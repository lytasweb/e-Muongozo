import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../services/sync_service.dart';
import '../services/db_service.dart';

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  // Try local first.
  final local = await DbService.getSubjects();
  if (local.isNotEmpty) {
    return local
        .map((j) => Subject.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // First run — try to sync.
  try {
    await SyncService().syncSubjects();
  } catch (_) {
    // Offline / unreachable. Return empty rather than crashing the UI.
    return const <Subject>[];
  }

  final synced = await DbService.getSubjects();
  return synced
      .map((j) => Subject.fromJson(Map<String, dynamic>.from(j)))
      .toList();
});