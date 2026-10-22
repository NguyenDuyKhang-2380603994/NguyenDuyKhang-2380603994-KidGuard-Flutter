
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nguyenduykhang_2380603994_kt/main.dart';

void main() {
  testWidgets('KidGuard Welcome Screen Test',
          (WidgetTester tester) async {

        await tester.pumpWidget(const KidGuardApp());

        // Kiểm tra tên ứng dụng
        expect(find.text('KidGuard'), findsOneWidget);

        // Kiểm tra nút Get Started
        expect(find.text('Get Started'), findsOneWidget);

        // Nhấn nút Get Started
        await tester.tap(find.text('Get Started'));

        await tester.pumpAndSettle();

        // Kiểm tra màn hình tiếp theo
        expect(
          find.text('Welcome to KidGuard'),
          findsOneWidget,
        );
      });
}
