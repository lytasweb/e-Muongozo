import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:nearby_service/nearby_service.dart';

import '../services/db_service.dart';
import '../services/p2p_service.dart';
import 'reader_screen.dart';

class P2PShareScreen extends StatefulWidget {
  /// When non-null, the sender auto-sends this subject on connect.
  final int? shareSubjectId;

  const P2PShareScreen({super.key, this.shareSubjectId});

  @override
  State<P2PShareScreen> createState() => _P2PShareScreenState();
}

class _P2PShareScreenState extends State<P2PShareScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _p2p = P2PService();

  bool _active = false;
  bool _busy = false;
  bool _sending = false;
  List<NearbyDevice> _peers = [];
  String? _status;
  NearbyDevice? _connected;

  String? _shareSubjectName;

  // Received bundles
  List<Map<String, dynamic>> _received = [];

  StreamSubscription? _msgSub;

  bool get _isSender => widget.shareSubjectId != null;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: _isSender ? 0 : 1,
    );

    _p2p.peersStream.listen((peers) {
      if (mounted) setState(() => _peers = peers);
    });

    _p2p.stateStream.listen((s) => debugPrint('P2P state: $s'));

    _msgSub = _p2p.messagesStream.listen(_onIncomingMessage);

    _loadShareSubjectName();
    _loadReceived();
  }

  Future<void> _loadShareSubjectName() async {
    final id = widget.shareSubjectId;
    if (id == null) return;
    final rows = await DbService.getSubjects();
    final match = rows.firstWhere(
      (r) => r['id'] == id,
      orElse: () => const {},
    );
    if (!mounted) return;
    setState(() {
      _shareSubjectName = match['name'] as String?;
    });
  }

  Future<void> _loadReceived() async {
    final rows = await DbService.getReceivedBundles();
    if (!mounted) return;
    setState(() => _received = rows);
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _tab.dispose();
    _p2p.stopDiscovery();
    super.dispose();
  }

  // ---- Incoming (receiver) ---------------------------------------------

  Future<void> _onIncomingMessage(ReceivedNearbyMessage msg) async {
    if (msg.content is! NearbyMessageTextRequest) return;
    final text = (msg.content as NearbyMessageTextRequest).value;
    if (text.isEmpty) return;

    try {
      final data = jsonDecode(text) as Map<String, dynamic>;
      if (data['type'] != 'subject_share') return;

      final subject = data['subject'] as Map<String, dynamic>?;
      final subjectName = (subject?['name'] ?? 'Unknown') as String;
      final subjectId = subject?['id'] as int?;

      final count = await DbService.importSubjectBundle(data);

      // Record this receipt for the "Received so far" list
      if (subjectId != null) {
        await DbService.recordReceivedBundle(
          subjectId: subjectId,
          subjectName: subjectName,
          topicCount: count,
          senderName: _connected?.info.displayName,
        );
      }

      if (!mounted) return;
      await _loadReceived();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Received $count topics from "$subjectName" ✓'),
          duration: const Duration(seconds: 4),
        ),
      );
      // Switch tab to Receive so the user sees the new item
      _tab.animateTo(1);
    } catch (e) {
      debugPrint('Import failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import: $e')),
      );
    }
  }

  // ---- Send -------------------------------------------------------------

  Future<void> _sendSelectedSubject() async {
    final subjectId = widget.shareSubjectId;
    if (subjectId == null) return;

    setState(() {
      _sending = true;
      _status = 'Preparing…';
    });

    try {
      final bundle = await DbService.exportSubjectBundle(subjectId);
      if (bundle == null) throw Exception('Subject not found locally');

      setState(() => _status = 'Sending…');
      await _p2p.sendPayload(jsonEncode(bundle));

      final topicCount = (bundle['topics'] as List).length;
      if (!mounted) return;
      setState(() {
        _sending = false;
        _status = 'Sent $topicCount topics ✓';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent $topicCount topics ✓'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _status = 'Send failed: $e';
      });
    }
  }

  // ---- Discovery --------------------------------------------------------

  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Starting…';
    });
    try {
      await _p2p.startDiscovery();
      if (!mounted) return;
      setState(() {
        _active = true;
        _busy = false;
        _status = null;
      });
    } on NearbyServiceBusyException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Bluetooth busy. Tap again, or toggle Bluetooth off/on.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _stop() async {
    setState(() {
      _busy = true;
      _status = 'Stopping…';
    });
    await _p2p.resetAll();
    if (!mounted) return;
    setState(() {
      _active = false;
      _busy = false;
      _peers = [];
      _connected = null;
      _status = null;
    });
  }

  Future<void> _connectTo(NearbyDevice device) async {
    try {
      await _p2p.connect(device);
      if (!mounted) return;
      setState(() => _connected = device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.info.displayName}')),
      );
      // Auto-send if this is the sender screen
      if (_isSender) {
        await _sendSelectedSubject();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share offline')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phonelink_off_rounded,
                    size: 64, color: Color(0xFF1E2050)),
                const SizedBox(height: 20),
                const Text('Available on Android only',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  'Offline P2P sharing uses Bluetooth and Wi-Fi Direct, '
                  'which are only available in the Android app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSender
            ? 'Share ${_shareSubjectName ?? "subject"}'
            : 'Receive offline'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Share', icon: Icon(Icons.upload_rounded, size: 18)),
            Tab(text: 'Receive',
                icon: Icon(Icons.download_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildShareTab(), _buildReceiveTab()],
      ),
    );
  }

  // ---- SHARE tab ---------------------------------------------------------

  Widget _buildShareTab() {
    if (!_isSender) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_rounded,
                  size: 64, color: Color(0xFF1E2050)),
              const SizedBox(height: 16),
              const Text(
                'To share a subject',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Go back to Home and tap the share icon on any subject card.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            _active ? Icons.wifi_tethering : Icons.wifi_tethering_off,
            size: 72,
            color: _active ? const Color(0xFF1E2050) : Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            _active ? 'Visible to classmates' : 'Ready to share',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _active
                ? (_connected != null
                    ? 'Connected. Sending…'
                    : 'Ask a classmate to tap "Receive" and find you.')
                : 'Sharing "${_shareSubjectName ?? "subject"}"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : (_active ? _stop : _start),
              icon: Icon(_active ? Icons.stop : Icons.play_arrow),
              label: Text(
                _busy
                    ? 'Please wait…'
                    : (_active ? 'Stop sharing' : 'Start sharing'),
              ),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(
              _status!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ---- RECEIVE tab -------------------------------------------------------

  Widget _buildReceiveTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : (_active ? _stop : _start),
              icon: Icon(_active ? Icons.stop : Icons.search),
              label: Text(
                _busy
                    ? 'Please wait…'
                    : (_active ? 'Stop searching' : 'Find classmates'),
              ),
            ),
          ),
        ),

        // Peers found
        if (_active && _peers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Searching for nearby devices…'),
              ],
            ),
          ),
        if (_peers.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _peers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = _peers[i];
                final isConnected = _connected?.info.id == p.info.id;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: isConnected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1E2050),
                    child: Icon(
                      isConnected ? Icons.check : Icons.phone_android,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    p.info.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(p.info.id,
                      style: const TextStyle(fontSize: 11)),
                  trailing: isConnected
                      ? const Text('Connected',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ))
                      : const Icon(Icons.chevron_right, size: 18),
                  onTap: isConnected ? null : () => _connectTo(p),
                );
              },
            ),
          ),

        const Divider(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Received so far',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _received.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Nothing received yet.\nConnect to a classmate and wait for them to share.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _received.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _received[i];
                    final when = DateTime.fromMillisecondsSinceEpoch(
                        r['received_at'] as int);
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF10B981),
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(
                        r['subject_name'] as String,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${r['topic_count']} topics · '
                        '${when.hour.toString().padLeft(2, "0")}:'
                        '${when.minute.toString().padLeft(2, "0")}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            topicId: 0, // not a reader open; just view list
                            title: r['subject_name'] as String,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
