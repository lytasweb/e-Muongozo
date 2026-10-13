import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/bookmarks_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/role_provider.dart';
import '../services/bookmark_service.dart';
import '../services/db_service.dart';
import 'pdf_viewer_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int topicId;
  final String title;
  const ReaderScreen({
    super.key,
    required this.topicId,
    required this.title,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scroll = ScrollController();
  bool _bookmarked = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadBookmark() async {
    final ids = await BookmarkService.getAll();
    if (!mounted) return;
    setState(() => _bookmarked = ids.contains(widget.topicId));
  }

  Future<void> _toggleBookmark() async {
    await BookmarkService.toggle(widget.topicId);
    ref.invalidate(bookmarksProvider);
    await _loadBookmark();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_bookmarked ? 'Bookmarked' : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _restoreProgress() async {
    if (_restored) return;
    _restored = true;
    final pos = await DbService.getProgress(widget.topicId);
    if (pos != null && _scroll.hasClients) {
      final target = pos.toDouble();
      if (target <= _scroll.position.maxScrollExtent) {
        _scroll.jumpTo(target);
      }
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.offset;
    final rounded = (pos / 200).floor() * 200;
    if (rounded > 0) {
      DbService.saveProgress(widget.topicId, rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(readerBlocksProvider(widget.topicId));
    final fontScale = ref.watch(settingsProvider).fontSize.scale;
    final role = ref.watch(roleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (role == UserRole.teacher)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2050),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'TEACHER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          IconButton(
            icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: _bookmarked ? 'Remove bookmark' : 'Add bookmark',
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: blocksAsync.when(
        data: (blocks) {
          if (blocks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This topic has no content yet.\n\n'
                  'Try going back and tapping Sync.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _restoreProgress();
          });
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(20),
            itemCount: blocks.length + (role == UserRole.teacher ? 1 : 0),
            itemBuilder: (context, i) {
              if (role == UserRole.teacher && i == blocks.length) {
                return FutureBuilder<Map<String, dynamic>?>(
                  future: DbService.getTopicMeta(widget.topicId),
                  builder: (context, snap) {
                    final meta = snap.data;
                    final schemes = (meta?['teaching_schemes'] as List?)
                            ?.cast<String>() ??
                        const <String>[];
                    final books = (meta?['recommended_books'] as List?)
                            ?.cast<String>() ??
                        const <String>[];
                    return _TeacherExtras(
                      topicTitle: widget.title,
                      teachingSchemes: schemes,
                      recommendedBooks: books,
                    );
                  },
                );
              }
              return _buildBlock(context, blocks[i], fontScale);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBlock(
    BuildContext context,
    Map<String, dynamic> block,
    double fontScale,
  ) {
    final type = (block['type'] ?? 'text') as String;
    final content = (block['content'] ?? '') as String;

    switch (type) {
      case 'warning':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              border: Border.all(color: const Color(0xFFFCD34D)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD97706)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(
                        color: Color(0xFF78350F), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );

      case 'image_svg':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SvgPicture.string(content, fit: BoxFit.contain),
        );

      case 'pdf':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  topicId: widget.topicId,
                  title: widget.title,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      color: Color(0xFFD97706), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(content,
                            style: const TextStyle(
                                color: Color(0xFF78350F),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFFD97706)),
                ],
              ),
            ),
          ),
        );

      case 'text':
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 16 * fontScale,
              height: 1.65,
              color: const Color(0xFF334155),
            ),
          ),
        );
    }
  }
}

// ============================================================
// Teacher-only extra section at the bottom of the reader
// ============================================================
class _TeacherExtras extends StatelessWidget {
  final String topicTitle;
  final List<String> teachingSchemes;
  final List<String> recommendedBooks;

  const _TeacherExtras({
    required this.topicTitle,
    required this.teachingSchemes,
    required this.recommendedBooks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                    color: Color(0xFF2563EB), size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher extras',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visible only in Teacher mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (teachingSchemes.isEmpty && recommendedBooks.isEmpty)
            const _TeacherTile(
              icon: Icons.info_outline,
              title: 'No teacher content yet',
              subtitle:
                  'This topic does not have a teaching scheme or recommended '
                  'books uploaded. Ask the school admin to add them.',
            ),

          for (final s in teachingSchemes)
            _TeacherTile(
              icon: Icons.menu_book_outlined,
              title: 'Teaching scheme',
              subtitle: s,
            ),

          for (final b in recommendedBooks)
            _TeacherTile(
              icon: Icons.library_books_outlined,
              title: 'Recommended book',
              subtitle: b,
            ),

          const _TeacherTile(
            icon: Icons.quiz_outlined,
            title: 'Formative assessment',
            subtitle:
                'Prepare three quick questions to check understanding '
                'before the next lesson.',
          ),
        ],
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TeacherTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E2050)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1E2050),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
