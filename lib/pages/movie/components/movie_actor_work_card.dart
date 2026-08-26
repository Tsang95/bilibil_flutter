import 'package:flutter/material.dart';

import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/movie_models.dart';

class MovieActorWorkCard extends StatelessWidget {
  const MovieActorWorkCard({super.key, required this.work});

  final MovieActorWork work;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          LegacyNetworkImage(
            url: work.coverUrl,
            borderRadius: BorderRadius.circular(8),
          ),
          if (work.isVipOnly)
            const Positioned(
              top: 0,
              right: 0,
              child: PostAccessBadge(text: 'VIP'),
            ),
        ],
      ),
    );
  }
}
