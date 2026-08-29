import 'package:flutter/widgets.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/pages/mine/look_history_page.dart';

class BuyPage extends StatelessWidget {
  const BuyPage({super.key, this.loadCategories, this.loadPage});

  final HistoryCategoryLoader? loadCategories;
  final UserPostRecordLoader? loadPage;

  @override
  Widget build(BuildContext context) => LookHistoryPage(
        title: '我的购买',
        loadCategories: loadCategories,
        loadPage: loadPage ??
            (page, categoryId, forceRefresh) => UserApi.getOwnBuys(
                  page: page,
                  categoryId: categoryId,
                  forceRefresh: forceRefresh,
                ),
      );
}
