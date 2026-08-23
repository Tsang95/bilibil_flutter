import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/post_detail.dart';

class PostRewardSheet extends StatefulWidget {
  const PostRewardSheet({
    super.key,
    required this.products,
    required this.onReward,
  });

  final List<PostRewardProduct> products;
  final Future<void> Function(PostRewardProduct product) onReward;

  @override
  State<PostRewardSheet> createState() => _PostRewardSheetState();
}

class _PostRewardSheetState extends State<PostRewardSheet> {
  int _selectedIndex = 0;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting || widget.products.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.onReward(widget.products[_selectedIndex]);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // The shared submission feedback reports the backend error.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Text(
                '打赏',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('打赏金额', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 115 / 50,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                    itemBuilder: (context, index) {
                      final product = widget.products[index];
                      final selected = index == _selectedIndex;
                      return InkWell(
                        onTap: _submitting
                            ? null
                            : () => setState(() => _selectedIndex = index),
                        borderRadius: BorderRadius.circular(10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${product.coinCount}',
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : () => unawaited(_submit()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                      ),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.8,
                              ),
                            )
                          : const Text('立即打赏'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
