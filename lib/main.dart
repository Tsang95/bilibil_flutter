import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/message_socket_store.dart';
import 'package:b_flutter/stores/startup_controller.dart';
import 'package:b_flutter/stores/user_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  _configureLoading();
  Get.put(StartupController(), permanent: true);
  final userStore = Get.put(UserStore(), permanent: true);
  Get.put(MessageSocketStore(userStore: userStore), permanent: true);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => GetMaterialApp(
        title: 'BiliBili',
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        theme: buildAppTheme(),
        navigatorObservers: [
          BotToastNavigatorObserver(),
          appScrollToTopNavigatorObserver,
        ],
        builder: (context, child) {
          final loadingChild = EasyLoading.init()(context, child);
          final toastChild = BotToastInit()(context, loadingChild);
          return KeyboardFocusDismissLayer(
            child: ScrollToTopLayer(
              navigatorObserver: appScrollToTopNavigatorObserver,
              child: toastChild,
            ),
          );
        },
      ),
    );
  }
}

void _configureLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.custom
    ..maskType = EasyLoadingMaskType.custom
    ..indicatorSize = 30
    ..radius = 10
    ..fontSize = 14
    ..progressColor = AppColors.primary
    ..backgroundColor = AppColors.toastBackground
    ..indicatorColor = AppColors.primary
    ..textColor = Colors.white
    ..maskColor = Colors.black.withValues(alpha: 0.32)
    ..userInteractions = false
    ..dismissOnTap = false;
}
