import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/pages/login/forgot_password.dart';
import 'package:b_flutter/pages/login/login.dart';
import 'package:b_flutter/pages/login/register.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('login page preserves all legacy form actions', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));

    expect(find.text('账号'), findsOneWidget);
    expect(find.text('密码'), findsOneWidget);
    expect(find.text('谷歌验证码（可选输入）'), findsOneWidget);
    expect(find.text('身份卡登录'), findsOneWidget);
    expect(find.text('联系客服'), findsOneWidget);
  });

  testWidgets('register page includes birthday recovery field', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: RegisterPage()));

    expect(find.text('昵称'), findsOneWidget);
    expect(find.text('重置密码（生日验证）'), findsOneWidget);
    expect(find.text('请输入您的生日'), findsOneWidget);
    expect(find.text('注册'), findsAtLeastNWidgets(2));
  });

  testWidgets('forgot password page renders all three steps', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: ForgotPasswordPage()));

    expect(find.text('输入账号'), findsOneWidget);
    expect(find.text('输入生日'), findsOneWidget);
    expect(find.text('重置密码'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('legacy login and coin prompts retain their custom layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LegacyMessageDialog(
            title: '温馨提示',
            message: '请先注册或登录账号',
            confirmLabel: '确认',
            cancelLabel: '取消',
            onConfirm: _noop,
          ),
        ),
      ),
    );
    expect(find.text('温馨提示'), findsOneWidget);
    expect(find.text('请先注册或登录账号'), findsOneWidget);
    expect(find.text('确认'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LegacyAccessDialog(
            price: 5,
            walletBalance: 0,
            nickname: '测试账号',
            isVip: false,
          ),
        ),
      ),
    );
    final insufficientSize = tester.getSize(
      find.byKey(const ValueKey<String>('legacy_access_dialog')),
    );
    expect(insufficientSize.width, 315);
    expect(insufficientSize.height, lessThan(330));
    expect(find.text('当前钱包余额：0.0'), findsOneWidget);
    expect(find.text('当前帖子需要付费5.0金币进行购买。'), findsOneWidget);
    expect(find.text('余额不足，是否前往充值'), findsOneWidget);
    expect(find.text('加入up主充电计划。'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
    expect(find.text('去充值'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LegacyAccessDialog(
            price: 5,
            walletBalance: 10,
            nickname: '测试账号',
            isVip: false,
          ),
        ),
      ),
    );
    final sufficientSize = tester.getSize(
      find.byKey(const ValueKey<String>('legacy_access_dialog')),
    );
    expect(find.text('余额不足，是否前往充值'), findsNothing);
    expect(find.text('我要购买'), findsOneWidget);
    expect(sufficientSize.height, lessThan(insufficientSize.height));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LegacyAccessDialog(
            price: 0,
            walletBalance: 0,
            nickname: 'java123dsd',
            isVip: true,
          ),
        ),
      ),
    );
    expect(find.text('当前账户：java123dsd'), findsOneWidget);
    expect(find.text('此贴为VIP专享，请购买VIP'), findsOneWidget);
    expect(find.text('加入up主充电计划。'), findsOneWidget);
    expect(find.text('去开通VIP'), findsOneWidget);
    expect(find.text('已有账号？立即登录'), findsOneWidget);
  });
}

void _noop() {}
