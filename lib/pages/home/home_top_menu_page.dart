import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/pages/home/home_partition_page.dart';
import 'package:b_flutter/routes/app_routes.dart';

final class HomeTopMenuArguments {
  const HomeTopMenuArguments({
    required this.categories,
    required this.banners,
    required this.contentAds,
  });

  final List<HomeCategory> categories;
  final List<BannerItem> banners;
  final List<BannerItem> contentAds;
}

class HomeTopMenuPage extends StatelessWidget {
  const HomeTopMenuPage({super.key, required this.arguments});

  final HomeTopMenuArguments arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '分区'),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: arguments.categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 5,
          childAspectRatio: 94 / 71,
        ),
        itemBuilder: (context, index) {
          final category = arguments.categories[index];
          return GestureDetector(
            onTap: () => Get.toNamed<void>(
              AppRoutes.homePartition,
              arguments: HomePartitionArguments(
                category: category,
                banners: arguments.banners,
                contentAds: arguments.contentAds,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox.square(
                    dimension: 28,
                    child: LegacyNetworkImage(
                      url: category.backgroundUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
