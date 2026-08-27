import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/common_barrage.dart';

Future<String?> showPostCommonBarrageList({
  required BuildContext context,
  required RenderBox anchor,
  required List<CommonBarrage> barrages,
}) {
  final origin = anchor.localToGlobal(Offset.zero);
  final screenWidth = MediaQuery.sizeOf(context).width;
  final width = anchor.size.width;
  final right = (screenWidth - origin.dx - width).clamp(10.0, screenWidth);
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭常用弹幕列表',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, _) {
      return Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
          ),
          Positioned(
            top: origin.dy + anchor.size.height,
            right: right,
            width: width,
            height: 200,
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: barrages.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 10,
                    endIndent: 10,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final content = barrages[index].content;
                    return InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(content),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          content,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
