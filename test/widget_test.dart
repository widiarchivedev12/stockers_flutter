// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockers_flutter/app/app.dart';

void main() {
  testWidgets('App loads with bottom navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: StockersApp()));
    await tester.pumpAndSettle();

    // Verify that bottom navigation bar is present
    expect(find.byType(NavigationBar), findsOneWidget);
    
    // Verify tab labels are present in NavigationBar
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final labels = navBar.destinations.map((d) => (d as NavigationDestination).label).toList();
    expect(labels, equals(['Beranda', 'Mutasi', 'Input', 'Laporan', 'Periode']));
  });
}