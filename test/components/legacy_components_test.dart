import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_birthday_field.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/app_config.dart';
import 'package:b_flutter/stores/app_config_store.dart';

void main() {
  testWidgets('legacy form controls retain height, labels and tap behavior', (
    tester,
  ) async {
    var buttonTaps = 0;
    var birthdayTaps = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              LegacyTextField(controller: controller, hintText: '请输入内容'),
              LegacyBirthdayField(value: '', onTap: () => birthdayTaps++),
              LegacyActionButton(label: '提交', onPressed: () => buttonTaps++),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(LegacyTextField)).height, 40);
    expect(tester.getSize(find.byType(LegacyBirthdayField)).height, 40);
    expect(tester.getSize(find.byType(LegacyActionButton)).height, 40);
    expect(find.text('请输入您的生日'), findsOneWidget);

    await tester.tap(find.text('请输入您的生日'));
    await tester.tap(find.text('提交'));
    expect(birthdayTaps, 1);
    expect(buttonTaps, 1);
  });

  testWidgets('legacy navigation and access badges retain visible contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: LegacyAppBar(title: '页面标题', showBack: false),
          body: Row(
            children: <Widget>[
              PostAccessBadge(text: 'VIP'),
              PostAccessBadge(text: '12金币'),
              PostAccessBadge(text: ''),
            ],
          ),
        ),
      ),
    );

    expect(const LegacyAppBar(title: '标题').preferredSize.height, 49);
    expect(find.text('页面标题'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('12金币'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
  });

  test(
    'network image resolves legacy relative and absolute resource URLs',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await AppConfigStore.instance.clear();
      await AppConfigStore.instance.save(
        domain: 'https://api.example.test',
        config: const AppConfig(
          onlineUrl: '',
          sourceBaseUrl: 'https://assets.example.test/root',
          uploadVideoUrl: '',
          videoBaseUrl: '',
          withdrawalFee: 0,
          usdtExchangeRate: 0,
          telegramGroup: '',
          businessContact: '',
          shareDomains: <String>[],
        ),
      );

      expect(
        LegacyNetworkImage.resolveUrl('covers/a.png'),
        'https://assets.example.test/root/covers/a.png',
      );
      expect(
        LegacyNetworkImage.resolveUrl('HTTP://cdn.example.test/a.png'),
        'HTTP://cdn.example.test/a.png',
      );
    },
  );
}
