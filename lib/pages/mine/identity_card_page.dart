import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/identity_card_decoder.dart';

/// Legacy account recovery identity-card dialog. Credentials live in memory
/// only and are cleared on logout or app restart; they are never persisted.
class IdentityCardDialog extends StatelessWidget {
  const IdentityCardDialog({super.key});

  List<String> _domains() {
    final values = <String>[
      AppConfigStore.instance.domain,
      ...AppEnvironment.configuredApiDomains,
    ];
    return values.where((item) => item.isNotEmpty).toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<UserStore>();
    final user = store.user.value;
    if (user == null) return const SizedBox.shrink();
    final username = store.hasIdentityCardCredentials
        ? store.identityCardUsername
        : user.username;
    final password =
        store.hasIdentityCardCredentials ? store.identityCardPassword : '';

    String payload;
    try {
      payload = IdentityCardEncoder().encode(
        username: username,
        password: password,
      );
    } catch (error) {
      return Center(
        child: TextButton(
          onPressed: Get.back<void>,
          child: Text(error.toString()),
        ),
      );
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math
              .min(375.0, math.max(0.0, constraints.maxWidth - 20))
              .toDouble();
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: width,
                  height: width * 558 / 375,
                  child: _IdentityCard(
                    width: width,
                    username: username,
                    password: password,
                    payload: payload,
                    domains: _domains(),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: Get.back<void>,
                  child: const Icon(
                    CupertinoIcons.xmark_circle,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.width,
    required this.username,
    required this.password,
    required this.payload,
    required this.domains,
  });

  final double width;
  final String username;
  final String password;
  final String payload;
  final List<String> domains;

  @override
  Widget build(BuildContext context) {
    final scale = width / 375;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'assets/images/v1/bg_idcard.png',
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: 45 * scale,
          left: 68 * scale,
          child: Text(
            '我的身份卡',
            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w700),
          ),
        ),
        Positioned(
          top: 72 * scale,
          left: 68 * scale,
          child: Text(
            '请截图保存',
            style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700),
          ),
        ),
        Positioned(
          top: 96 * scale,
          left: 68 * scale,
          width: 132 * scale,
          child: Text(
            '身份卡用于保留您永久身份请及时保存',
            style: TextStyle(
              fontSize: 11 * scale,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Positioned(
          top: 182 * scale,
          left: 40 * scale,
          right: 40 * scale,
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w700,
              ),
              children: <InlineSpan>[
                TextSpan(text: '账号：$username'),
                WidgetSpan(child: SizedBox(width: 20 * scale)),
                TextSpan(text: '密码：$password'),
              ],
            ),
          ),
        ),
        Positioned(
          top: 216 * scale,
          left: 107.5 * scale,
          child: Container(
            width: 160 * scale,
            height: 160 * scale,
            padding: EdgeInsets.all(4 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(color: AppColors.primary, width: .5),
            ),
            child: QrImageView(data: payload, padding: EdgeInsets.zero),
          ),
        ),
        Positioned(
          top: 386 * scale,
          left: 57.5 * scale,
          right: 57.5 * scale,
          child: Column(
            children: <Widget>[
              for (var index = 0; index < domains.length; index++)
                Container(
                  height: 32 * scale,
                  margin: EdgeInsets.symmetric(vertical: 6 * scale),
                  padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4 * scale),
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '回家域名${index + 1}:',
                        style: TextStyle(fontSize: 12 * scale),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          domains[index],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
