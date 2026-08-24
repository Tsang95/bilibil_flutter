import 'package:flutter/widgets.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/pages/mine/look_history_page.dart';

class CollectPage extends StatelessWidget {
  const CollectPage({super.key, this.loadCategories, this.loadPage});

  final HistoryCategoryLoader? loadCategories;
  final UserPostRecordLoader? loadPage;

  @override
  Widget build(BuildContext context) => LookHistoryPage(
    title: '我的收藏',
    loadCategories: loadCategories,
    loadPage:
        loadPage ??
        (page, categoryId, forceRefresh) => UserApi.getOwnCollections(
          page: page,
          categoryId: categoryId,
          forceRefresh: forceRefresh,
        ),
  );
}
