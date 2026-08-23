import 'package:get/get.dart';

import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/home/home_page.dart';
import 'package:b_flutter/pages/home/home_partition_page.dart';
import 'package:b_flutter/pages/home/home_top_menu_page.dart';
import 'package:b_flutter/pages/login/forgot_password.dart';
import 'package:b_flutter/pages/login/login.dart';
import 'package:b_flutter/pages/login/quick_register.dart';
import 'package:b_flutter/pages/login/register.dart';
import 'package:b_flutter/pages/mine/suggestion_page.dart';
import 'package:b_flutter/pages/posts/banner_html_page.dart';
import 'package:b_flutter/pages/posts/post_detail_page.dart';
import 'package:b_flutter/pages/posts/post_label_page.dart';
import 'package:b_flutter/pages/search/search_page.dart';
import 'package:b_flutter/pages/splash/splash_page.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/user/forget_password';
  static const quickRegister = '/quick_register';
  static const search = '/search';
  static const postDetail = '/posts/detail/:postId';
  static const postLabel = '/posts/label/:labelId';
  static const suggestion = '/user/suggestion';
  static const bannerHtml = '/banner/html';
  static const homeTopMenu = '/home/topMenu';
  static const homePartition = '/home/partition';

  static String postDetailPath(int postId) => '/posts/detail/$postId';
  static String postLabelPath(int labelId) => '/posts/label/$labelId';
}

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage<dynamic>(name: AppRoutes.splash, page: SplashPage.new),
    GetPage<dynamic>(name: AppRoutes.home, page: HomePage.new),
    GetPage<dynamic>(name: AppRoutes.login, page: LoginPage.new),
    GetPage<dynamic>(name: AppRoutes.register, page: RegisterPage.new),
    GetPage<dynamic>(name: AppRoutes.search, page: SearchPage.new),
    GetPage<dynamic>(
      name: AppRoutes.postDetail,
      page: () => PostDetailPage(
        postId: int.tryParse(Get.parameters['postId'] ?? '') ?? 0,
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.postLabel,
      page: () => PostLabelPage(
        label: Get.arguments is PostLabel
            ? Get.arguments as PostLabel
            : PostLabel(
                id: int.tryParse(Get.parameters['labelId'] ?? '') ?? 0,
                name: '',
              ),
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.forgotPassword,
      page: ForgotPasswordPage.new,
    ),
    GetPage<dynamic>(
      name: AppRoutes.quickRegister,
      page: QuickRegisterPage.new,
    ),
    GetPage<dynamic>(name: AppRoutes.suggestion, page: SuggestionPage.new),
    GetPage<dynamic>(
      name: AppRoutes.bannerHtml,
      page: () => BannerHtmlPage(html: Get.arguments?.toString() ?? ''),
    ),
    GetPage<dynamic>(
      name: AppRoutes.homeTopMenu,
      page: () => HomeTopMenuPage(
        arguments: Get.arguments is HomeTopMenuArguments
            ? Get.arguments as HomeTopMenuArguments
            : const HomeTopMenuArguments(
                categories: <HomeCategory>[],
                banners: <BannerItem>[],
                contentAds: <BannerItem>[],
              ),
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.homePartition,
      page: () => HomePartitionPage(
        arguments: Get.arguments is HomePartitionArguments
            ? Get.arguments as HomePartitionArguments
            : HomePartitionArguments(
                category: HomeCategory.fromJson(const <String, dynamic>{}),
                banners: const <BannerItem>[],
                contentAds: const <BannerItem>[],
              ),
      ),
    ),
  ];
}
