import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subject.dart';
import '../models/term.dart';
import '../providers/terms_provider.dart';
import '../providers/topics_provider.dart';
import '../services/sync_service.dart';
import 'reader_screen.dart';

class SubjectScreen extends ConsumerStatefulWidget {
  final Subject subject;
  const SubjectScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTerm = 1;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTerm = _tabController.index + 1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _syncTerm() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Syncing…')),
    );

    try {
      final count =
          await SyncService().syncTerm(widget.subject.id, _currentTerm);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Downloaded $count topics')),
      );
      ref.invalidate(topicsProvider);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsAsync = ref.watch(termsProvider(widget.subject.id));
    final topicsAsync = ref.watch(
      topicsProvider(TermKey(widget.subject.id, _currentTerm)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Term 1'),
            Tab(text: 'Term 2'),
            Tab(text: 'Term 3'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ---------- Sync banner ----------
          termsAsync.maybeWhen(
            data: (terms) {
              final current = terms.firstWhere(
                (t) => t.term == _currentTerm,
                orElse: () => const Term(
                  subjectId: 0,
                  term: 0,
                  topicCount: 0,
                  sizeBytes: 0,
                ),
              );
              if (current.term == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${current.topicCount} topics · ${current.sizeLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed: _syncing ? null : _syncTerm,
                      child: _syncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sync'),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // ---------- Topics list ----------
          Expanded(
            child: topicsAsync.when(
              data: (topics) {
                if (topics.isEmpty) {
                  return const Center(
                    child: Text('Tap Sync to download this term'),
                  );
                }
                return ListView.separated(
                  itemCount: topics.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = topics[i];
                    final id = t['id'] as int;
                    final title = t['title'] as String;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.book)),
                      title: Text(title),
                      subtitle: Text((t['badge'] ?? '') as String),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            topicId: id,
                            title: title,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}