import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { student, teacher }

extension UserRoleX on UserRole {
  String get label => this == UserRole.student ? 'Student' : 'Teacher';
  String get emoji  => this == UserRole.student ? '🎓' : '👩‍🏫';
}

class RoleNotifier extends StateNotifier<UserRole> {
  RoleNotifier() : super(UserRole.student) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('role') ?? 'student';
    state = stored == 'teacher' ? UserRole.teacher : UserRole.student;
    debugPrint('ROLE: loaded $stored');
  }

  Future<void> setRole(UserRole role) async {
    state = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role.name);
    debugPrint('ROLE: set to ${role.name}');
  }

  Future<void> toggle() async {
    await setRole(
      state == UserRole.student ? UserRole.teacher : UserRole.student,
    );
  }
}

final roleProvider =
    StateNotifierProvider<RoleNotifier, UserRole>((ref) => RoleNotifier());
