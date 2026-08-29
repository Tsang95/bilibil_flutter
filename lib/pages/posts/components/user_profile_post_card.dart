import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/routes/app_routes.dart';

class UserProfilePostCard extends StatelessWidget {
  const UserProfilePostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 98,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    LegacyNetworkImage(
                      url: post.preferredCoverUrl,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[Colors.transparent, Colors.black38],
                            stops: <double>[0.72, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 5,
                      child: Text(
                        '${post.viewCount}  ·  ${post.collectCount}',
                        style:
                            const TextStyle(fontSize: 8, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  child: Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
