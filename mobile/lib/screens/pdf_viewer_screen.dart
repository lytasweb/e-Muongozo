import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api.dart';

class PdfViewerScreen extends StatefulWidget {
  final int topicId;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.topicId,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final String _pdfUrl;
  PdfControllerPinch? _controller;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pdfUrl = ApiConfig.endpoint('/mobile/topics/${widget.topicId}/pdf');
    if (!kIsWeb) _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch the raw PDF bytes with Dio, then open them with pdfx.
      final res = await Dio().get<List<int>>(
        _pdfUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      if (bytes.isEmpty) throw Exception('Empty PDF response');

      final document = await PdfDocument.openData(bytes);
      if (!mounted) return;

      _controller = PdfControllerPinch(document: Future.value(document));
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openInExternal() async {
    final uri = Uri.parse(_pdfUrl);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    try {
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the PDF externally')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web: hand off to the browser's built-in PDF viewer.
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        launchUrl(Uri.parse(_pdfUrl), mode: LaunchMode.platformDefault);
      });
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Opening PDF in a new tab…')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Open in another app',
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInExternal,
          ),
          if (_error != null)
            IconButton(
              tooltip: 'Retry',
              icon: const Icon(Icons.refresh),
              onPressed: _loadPdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load PDF',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _loadPdf,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _openInExternal,
                    child: const Text('Open externally'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return PdfViewPinch(
      controller: _controller!,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
