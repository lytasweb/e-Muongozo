import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bookmarks_provider.dart';
import '../services/db_service.dart';
import 'reader_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarksAsync.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No bookmarks yet.\nTap the bookmark icon while reading a topic.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rows[i];
              final topicId = r['topic_id'] as int;
              final title = (r['title'] ?? 'Topic #$topicId') as String;
              final badge = (r['badge'] ?? '') as String;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.bookmark)),
                title: Text(title),
                subtitle: badge.isEmpty ? null : Text(badge),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove bookmark',
                  onPressed: () async {
                    await DbService.toggleBookmark(topicId);
                    ref.invalidate(bookmarksProvider);
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(topicId: topicId, title: title),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}