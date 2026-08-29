import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/utils/toast.dart';

class GoogleBindedPage extends StatelessWidget {
  const GoogleBindedPage({super.key});

  Future<void> _openService() async {
    final url = AppConfigStore.instance.config?.onlineUrl.trim() ?? '';
    if (url.isEmpty) {
      showToast('客服信息暂未配置', type: ToastType.info);
      return;
    }
    final target = Uri.tryParse(url);
    if (target == null || !await launchUrl(target)) {
      showToast('客服链接打开失败', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '谷歌验证码'),
        body: Column(
          children: <Widget>[
            const SizedBox(height: 100),
            SvgPicture.asset(
              'assets/images/v1/ic_binded_google.svg',
              width: 60,
              height: 60,
            ),
            const SizedBox(height: 10),
            const Text(
              '已绑定',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => unawaited(_openService()),
              child: const Text.rich(
                TextSpan(
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  children: <InlineSpan>[
                    TextSpan(text: '如果您有任何问题请联系'),
                    TextSpan(
                      text: '在线客服',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
