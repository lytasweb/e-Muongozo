// Basic smoke test for e-Muongozo.
//
// The default Flutter template test references a `MyApp` class that no
// longer exists in this project, so this file replaces it with a real
// smoke test that exercises the app's boot path.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emuongozo/main.dart';

void main() {
  testWidgets('EMuongozoApp boots without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EMuongozoApp()),
    );
    // First frame should render something (a Scaffold).
    expect(find.byType(Scaffold), findsWidgets);
  });
}
