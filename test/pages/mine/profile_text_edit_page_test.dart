import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/pages/mine/profile_text_edit_page.dart';
import 'package:b_flutter/routes/app_routes.dart';

void main() {
  tearDown(Get.reset);

  testWidgets(
    'profile text editor preserves the legacy text area and counter',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileTextEditPage(
            arguments: ProfileTextEditArguments(
              title: '昵称',
              maxLength: 16,
              initialValue: '旧昵称',
            ),
          ),
        ),
      );

      expect(find.text('昵称'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('3/16'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 16);
    },
  );

  testWidgets('named editor route returns the saved text', (tester) async {
    String? savedValue;

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: AppPages.pages,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await Get.toNamed<dynamic>(
                  AppRoutes.profileTextEdit,
                  arguments: const ProfileTextEditArguments(
                    title: '昵称',
                    maxLength: 16,
                    initialValue: '旧昵称',
                  ),
                );
                savedValue = result is String ? result : null;
              },
              child: const Text('编辑昵称'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('编辑昵称'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '新昵称');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedValue, '新昵称');
  });
}
