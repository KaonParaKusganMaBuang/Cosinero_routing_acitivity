import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:routing/pages/sample_page.dart';

void main() {
  testWidgets('Sample page loads API items and removes one on delete', (
    tester,
  ) async {
    final posts = [
      {'id': 1, 'title': 'First item', 'body': 'Body text'},
      {'id': 2, 'title': 'Second item', 'body': 'Body text 2'},
    ];

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(posts),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'DELETE') {
        posts.removeWhere(
          (item) => item['id'].toString() == request.url.pathSegments.last,
        );
        return http.Response(
          '',
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('', 500);
    });

    await tester.pumpWidget(MaterialApp(home: SamplePage(client: mockClient)));
    await tester.pumpAndSettle();

    expect(find.text('First item'), findsOneWidget);
    expect(find.text('Second item'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete').first);
    await tester.pumpAndSettle();

    expect(find.text('First item'), findsNothing);
    expect(find.text('Second item'), findsOneWidget);
  });
}
