import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/creator_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/pages/creator/creator_history_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() {
    Get.reset();
  });

  testWidgets('creator history restores three statuses and legacy work card', (
    tester,
  ) async {
    final work = CreatorWork.fromJson(<String, dynamic>{
      'id': 9,
      'title': '审核作品',
      'cover_images': <String>[],
      'is_vip_watch': 1,
      'sales_num': 2,
      'views_num': 30,
      'collect_num': 4,
      'reason': '封面不合规',
      'plate_two_obj': <String, dynamic>{'name': '动画'},
    });

    await tester.pumpWidget(
      GetMaterialApp(
        home: CreatorHistoryPage(
          initialIndex: 2,
          loader:
              ({
                required CreatorWorkStatus status,
                required int page,
                bool forceRefresh = false,
              }) async => PagedResult<CreatorWork>(
                page: 1,
                totalPages: 1,
                totalItems: 1,
                isLastPage: true,
                items: <CreatorWork>[work],
              ),
          deleteWork: ({required int id}) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('我的作品'), findsOneWidget);
    expect(find.text('发布成功'), findsOneWidget);
    expect(find.text('审核中'), findsOneWidget);
    expect(find.text('审核失败'), findsOneWidget);
    expect(find.text('审核作品'), findsOneWidget);
    expect(find.text('#动画'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('购买：2'), findsOneWidget);
    expect(find.text('浏览：30'), findsOneWidget);
    expect(find.text('收藏：4'), findsOneWidget);
    expect(find.text('审核失败:封面不合规'), findsOneWidget);
    expect(find.text('删除帖子'), findsOneWidget);
  });
}
