import 'package:get/get.dart';

import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/home/home_page.dart';
import 'package:b_flutter/pages/home/home_more_posts_page.dart';
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
import 'package:b_flutter/pages/topics/search_topic_page.dart';
import 'package:b_flutter/pages/topics/topic_list_page.dart';
import 'package:b_flutter/models/topic_summary.dart';
import 'package:b_flutter/pages/active/create_active_page.dart';
import 'package:b_flutter/pages/mine/invite_page.dart';
import 'package:b_flutter/pages/game/game_activity_page.dart';
import 'package:b_flutter/pages/game/game_recharge_page.dart';
import 'package:b_flutter/pages/game/game_recharge_record_page.dart';
import 'package:b_flutter/pages/game/game_withdraw_page.dart';
import 'package:b_flutter/pages/game/game_bind_bank_page.dart';
import 'package:b_flutter/pages/game/game_withdraw_record_page.dart';
import 'package:b_flutter/pages/follow/follow_list_page.dart';
import 'package:b_flutter/pages/mine/my_fans_page.dart';
import 'package:b_flutter/pages/mine/help_center_page.dart';
import 'package:b_flutter/pages/mine/change_password_page.dart';
import 'package:b_flutter/pages/mine/google_binded_page.dart';
import 'package:b_flutter/pages/mine/google_verify_page.dart';
import 'package:b_flutter/pages/mine/look_history_page.dart';
import 'package:b_flutter/pages/mine/collect_page.dart';
import 'package:b_flutter/pages/mine/buy_page.dart';
import 'package:b_flutter/pages/mine/set_pay_password_page.dart';
import 'package:b_flutter/pages/mine/task_center_page.dart';
import 'package:b_flutter/pages/mine/personal_info_page.dart';
import 'package:b_flutter/pages/mine/profile_text_edit_page.dart';
import 'package:b_flutter/pages/mine/set_charge_price_page.dart';
import 'package:b_flutter/pages/mine/user_feedback_page.dart';
import 'package:b_flutter/pages/vip/recharge_history_page.dart';
import 'package:b_flutter/pages/vip/recharge_page.dart';
import 'package:b_flutter/pages/vip/vip_center_page.dart';
import 'package:b_flutter/pages/vip/wallet_page.dart';

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
  static const homeMorePosts = '/home/label';
  static const searchTopic = '/topics/search';
  static const topicList = '/topics/list';
  static const createActive = '/person/createActive';
  static const invite = '/user/invite';
  static const gameActivities = '/game/activities';
  static const gameRecharge = '/game/recharge';
  static const gameRechargeRecords = '/game/recharge-records';
  static const gameWithdraw = '/game/withdraw';
  static const gameBindBank = '/game/bind-bank';
  static const gameWithdrawRecords = '/game/withdraw-records';
  static const followList = '/follow/list';
  static const myFans = '/user/fans';
  static const helpCenter = '/user/help';
  static const changePassword = '/user/change-password';
  static const googleVerify = '/user/google-verify';
  static const googleBound = '/user/google-bounded';
  static const lookHistory = '/view/history';
  static const collect = '/user/collect';
  static const buy = '/user/buy';
  static const setPayPassword = '/user/set-pay-password';
  static const taskCenter = '/user/tasks';
  static const personalInfo = '/user/profile';
  static const profileTextEdit = '/user/profile/edit';
  static const setChargePrice = '/user/charge-price';
  static const userFeedback = '/user/feedback';
  static const vipCenter = '/vip/center';
  static const wallet = '/vip/wallet';
  static const recharge = '/vip/recharge';
  static const rechargeHistory = '/vip/recharge-history';

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
    GetPage<dynamic>(name: AppRoutes.searchTopic, page: SearchTopicPage.new),
    GetPage<dynamic>(name: AppRoutes.createActive, page: CreateActivePage.new),
    GetPage<dynamic>(name: AppRoutes.invite, page: InvitePage.new),
    GetPage<dynamic>(
      name: AppRoutes.gameActivities,
      page: GameActivityPage.new,
    ),
    GetPage<dynamic>(name: AppRoutes.gameRecharge, page: GameRechargePage.new),
    GetPage<dynamic>(
      name: AppRoutes.gameRechargeRecords,
      page: GameRechargeRecordPage.new,
    ),
    GetPage<dynamic>(name: AppRoutes.gameWithdraw, page: GameWithdrawPage.new),
    GetPage<dynamic>(name: AppRoutes.gameBindBank, page: GameBindBankPage.new),
    GetPage<dynamic>(
      name: AppRoutes.gameWithdrawRecords,
      page: GameWithdrawRecordPage.new,
    ),
    GetPage<dynamic>(name: AppRoutes.followList, page: FollowListPage.new),
    GetPage<dynamic>(name: AppRoutes.myFans, page: MyFansPage.new),
    GetPage<dynamic>(name: AppRoutes.helpCenter, page: HelpCenterPage.new),
    GetPage<dynamic>(
      name: AppRoutes.changePassword,
      page: ChangePasswordPage.new,
    ),
    GetPage<dynamic>(name: AppRoutes.googleVerify, page: GoogleVerifyPage.new),
    GetPage<dynamic>(name: AppRoutes.googleBound, page: GoogleBindedPage.new),
    GetPage<dynamic>(name: AppRoutes.lookHistory, page: LookHistoryPage.new),
    GetPage<dynamic>(name: AppRoutes.collect, page: CollectPage.new),
    GetPage<dynamic>(name: AppRoutes.buy, page: BuyPage.new),
    GetPage<dynamic>(
      name: AppRoutes.setPayPassword,
      page: SetPayPasswordPage.new,
    ),
    GetPage<dynamic>(name: AppRoutes.taskCenter, page: TaskCenterPage.new),
    GetPage<dynamic>(name: AppRoutes.personalInfo, page: PersonalInfoPage.new),
    GetPage<dynamic>(
      name: AppRoutes.profileTextEdit,
      page: () => ProfileTextEditPage(
        arguments: Get.arguments is ProfileTextEditArguments
            ? Get.arguments as ProfileTextEditArguments
            : const ProfileTextEditArguments(title: '', maxLength: 0),
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.setChargePrice,
      page: SetChargePricePage.new,
    ),
    GetPage<dynamic>(name: AppRoutes.userFeedback, page: UserFeedbackPage.new),
    GetPage<dynamic>(
      name: AppRoutes.vipCenter,
      page: () => VipCenterPage(
        initialType: Get.arguments == VipType.creator
            ? VipType.creator
            : VipType.movie,
      ),
    ),
    GetPage<dynamic>(name: AppRoutes.wallet, page: WalletPage.new),
    GetPage<dynamic>(name: AppRoutes.recharge, page: RechargePage.new),
    GetPage<dynamic>(
      name: AppRoutes.rechargeHistory,
      page: RechargeHistoryPage.new,
    ),
    GetPage<dynamic>(
      name: AppRoutes.topicList,
      page: () => TopicListPage(
        topic: Get.arguments is TopicSummary
            ? Get.arguments as TopicSummary
            : TopicSummary.fromJson(const <String, dynamic>{}),
      ),
    ),
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
    GetPage<dynamic>(
      name: AppRoutes.homeMorePosts,
      page: () => HomeMorePostsPage(
        arguments: Get.arguments is HomeMorePostsArguments
            ? Get.arguments as HomeMorePostsArguments
            : HomeMorePostsArguments(
                parent: HomeCategory.fromJson(const <String, dynamic>{}),
                category: HomeCategory.fromJson(const <String, dynamic>{}),
                banners: const <BannerItem>[],
                contentAds: const <BannerItem>[],
              ),
      ),
    ),
  ];
}
