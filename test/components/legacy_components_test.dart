import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_birthday_field.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/models/app_config.dart';
import 'package:b_flutter/stores/app_config_store.dart';

void main() {
  testWidgets('global focus layer dismisses a field when tapping elsewhere', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardFocusDismissLayer(
          child: Scaffold(
            body: Column(
              children: <Widget>[
                TextField(focusNode: focusNode),
                const ColoredBox(
                  key: Key('outside'),
                  color: Colors.transparent,
                  child: SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('global focus layer clears focus when the keyboard closes', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    addTearDown(tester.view.resetViewInsets);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardFocusDismissLayer(
          child: Scaffold(body: TextField(focusNode: focusNode)),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('long vertical lists can return to top across route changes', (
    tester,
  ) async {
    final observer = ScrollToTopNavigatorObserver();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(observer.currentRoute.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        builder: (context, child) =>
            ScrollToTopLayer(navigatorObserver: observer, child: child!),
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemExtent: 50,
            itemCount: 100,
            itemBuilder: (_, index) => Text('列表项$index'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
      findsNothing,
    );

    controller.jumpTo(900);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
      findsOneWidget,
    );

    final listContext = tester.element(find.byType(ListView));
    Navigator.of(listContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('详情页'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
      findsNothing,
    );

    Navigator.of(tester.element(find.text('详情页'))).pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(0, 0.1));
    expect(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
      findsNothing,
    );
  });

  testWidgets('nested scroll views do not replace the page scroll target', (
    tester,
  ) async {
    final observer = ScrollToTopNavigatorObserver();
    final pageController = ScrollController();
    final nestedController = ScrollController();
    addTearDown(pageController.dispose);
    addTearDown(nestedController.dispose);
    addTearDown(observer.currentRoute.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        builder: (context, child) =>
            ScrollToTopLayer(navigatorObserver: observer, child: child!),
        home: Scaffold(
          body: SingleChildScrollView(
            controller: pageController,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    controller: nestedController,
                    itemExtent: 30,
                    itemCount: 20,
                    itemBuilder: (_, index) => Text('嵌套项$index'),
                  ),
                ),
                const SizedBox(height: 1800),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    pageController.jumpTo(900);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
      findsOneWidget,
    );

    nestedController.jumpTo(30);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('global_scroll_to_top_button')),
    );
    await tester.pumpAndSettle();
    expect(pageController.offset, closeTo(0, 0.1));
  });

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

  testWidgets('legacy navigation can keep its trailing action off the edge', (
    tester,
  ) async {
    const trailingKey = Key('trailing-action');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: LegacyAppBar(
            title: '广告投放',
            showBack: false,
            trailingRightInset: 16,
            trailing: SizedBox(key: trailingKey, width: 60, height: 28),
          ),
        ),
      ),
    );

    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    expect(tester.getRect(find.byKey(trailingKey)).right, screenWidth - 16);
    expect(tester.getSize(find.byKey(trailingKey)).width, 60);
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

  testWidgets('network image accepts a stable custom loading placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: LegacyNetworkImage(
              url: 'https://image-loading.example.test/manga.jpg',
              placeholder: AspectRatio(
                aspectRatio: 3 / 4,
                child: ColoredBox(
                  key: ValueKey<String>('custom_image_placeholder'),
                  color: Colors.black12,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('custom_image_placeholder')),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('custom_image_placeholder')),
      ),
      const Size(240, 320),
    );
    final cachedImage = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(
      cachedImage.memCacheWidth,
      (240 * tester.view.devicePixelRatio).round(),
    );
  });
}
