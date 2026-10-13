import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nearby_service/nearby_service.dart';

/// Wraps nearby_service for our P2P sharing use case.
///
/// Handles Android 12+ permission requests internally via the plugin's
/// built-in requestPermissions() method, which shows the correct system
/// dialog for "Nearby Devices" access.
class P2PService {
  static final P2PService _instance = P2PService._internal();
  factory P2PService() => _instance;
  P2PService._internal();

  final NearbyService _nearby = NearbyService.getInstance(
    logLevel: NearbyServiceLogLevel.debug,
  );

  final _peers = StreamController<List<NearbyDevice>>.broadcast();
  final _messages = StreamController<ReceivedNearbyMessage>.broadcast();
  final _files = StreamController<ReceivedNearbyFilesPack>.broadcast();
  final _state = StreamController<CommunicationChannelState>.broadcast();

  Stream<List<NearbyDevice>> get peersStream => _peers.stream;
  Stream<ReceivedNearbyMessage> get messagesStream => _messages.stream;
  Stream<ReceivedNearbyFilesPack> get filesStream => _files.stream;
  Stream<CommunicationChannelState> get stateStream => _state.stream;

  NearbyDevice? _connectedDevice;
  NearbyDevice? get connectedDevice => _connectedDevice;

  bool _initialized = false;
  bool _permissionsGranted = false;

  /// Requests Android runtime permissions for Nearby Connections.
  ///
  /// On Android 12+, this shows a single system dialog asking the user
  /// to allow the app to find and connect to nearby devices.
  /// Returns true if permissions were granted.
  Future<bool> ensurePermissions() async {
    if (_permissionsGranted) return true;

    try {
      final androidService = _nearby.android;
      if (androidService != null) {
        final granted = await androidService.requestPermissions();
        _permissionsGranted = granted;
        debugPrint('P2P: permissions granted = $granted');
        return granted;
      }
      // Non-Android platforms don't need these permissions
      _permissionsGranted = true;
      return true;
    } catch (e) {
      debugPrint('P2P: permission request failed: $e');
      return false;
    }
  }

  /// Initializes the service. Safe to call multiple times.
  Future<bool> initialize() async {
    if (_initialized) return true;

    // Always request permissions before initializing
    if (!await ensurePermissions()) {
      throw Exception('Nearby devices permission denied');
    }

    try {
      await _nearby.initialize();
      _initialized = true;
      debugPrint('P2P: initialized');
      return true;
    } catch (e) {
      debugPrint('P2P: initialize failed: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Cancels any lingering native-level connection.
  Future<void> cancelPendingConnection() async {
    try {
      final androidService = _nearby.android;
      if (androidService != null) {
        await androidService.cancelLastConnectionProcess();
        debugPrint('P2P: cancelled pending connection (Android)');
      }
    } catch (e) {
      debugPrint('P2P: cancel failed (usually harmless): $e');
    }
  }

  /// Full reset — cancels, stops discovery, disconnects.
  Future<void> resetAll() async {
    await cancelPendingConnection();
    try {
      await _nearby.stopDiscovery();
    } catch (e) {
      debugPrint('P2P: stopDiscovery in reset: $e');
    }
    try {
      if (_connectedDevice != null) {
        await _nearby.disconnectById(_connectedDevice!.info.id);
      }
    } catch (e) {
      debugPrint('P2P: disconnect in reset: $e');
    }
    _connectedDevice = null;
    _initialized = false;
    debugPrint('P2P: reset complete');
  }

  /// Starts discovery. Handles BUSY by cancelling and retrying once.
  Future<void> startDiscovery() async {
    // Request permissions FIRST — this triggers the system dialog
    final granted = await ensurePermissions();
    if (!granted) {
      throw Exception('Nearby devices permission denied');
    }

    // Cancel any stuck native connection
    await cancelPendingConnection();

    if (!await initialize()) {
      throw Exception('Nearby service failed to initialize');
    }

    // Listen for peers and state
    _nearby.getPeersStream().listen((peers) => _peers.add(peers));
    _nearby.getCommunicationChannelStateStream().listen((s) => _state.add(s));

    try {
      await _nearby.discover();
      debugPrint('P2P: discovery started');
    } on NearbyServiceBusyException {
      debugPrint('P2P: BUSY — cancelling and retrying');
      await Future.delayed(const Duration(milliseconds: 800));
      await cancelPendingConnection();
      await _nearby.discover();
      debugPrint('P2P: discovery started on retry');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _nearby.stopDiscovery();
    } catch (e) {
      debugPrint('P2P: stopDiscovery error: $e');
    }
    _initialized = false;
    debugPrint('P2P: discovery stopped');
  }

  /// Connects to a peer. Cancels any stuck connection first.
  Future<void> connect(NearbyDevice device) async {
    await cancelPendingConnection();

    final ok = await _nearby.connectById(device.info.id);
    if (!ok) throw Exception('Connection failed');
    _connectedDevice = device;

    await _nearby.startCommunicationChannel(
      NearbyCommunicationChannelData(
        device.info.id,
        messagesListener: NearbyServiceMessagesListener(
          onData: (msg) => _messages.add(msg),
        ),
        filesListener: NearbyServiceFilesListener(
          onData: (pack) => _files.add(pack),
        ),
      ),
    );
    debugPrint('P2P: connected to ${device.info.id}');
  }

  Future<void> disconnect() async {
    final dev = _connectedDevice;
    if (dev == null) return;
    try {
      await _nearby.disconnectById(dev.info.id);
    } catch (e) {
      debugPrint('P2P: disconnect error: $e');
    }
    _connectedDevice = null;
    debugPrint('P2P: disconnected');
  }

  /// Send a JSON payload as a text message.
  Future<void> sendPayload(String jsonPayload) async {
    final dev = _connectedDevice;
    if (dev == null) throw Exception('Not connected');

    await _nearby.send(
      OutgoingNearbyMessage(
        receiver: dev.info,
        content: NearbyMessageTextRequest.create(value: jsonPayload),
      ),
    );
    debugPrint('P2P: payload sent (${jsonPayload.length} bytes)');
  }

  Future<void> dispose() async {
    await resetAll();
    await _peers.close();
    await _messages.close();
    await _files.close();
    await _state.close();
  }
}
