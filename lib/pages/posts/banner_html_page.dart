import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/components/legacy_app_bar.dart';

class BannerHtmlPage extends StatelessWidget {
  const BannerHtmlPage({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '公告'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: HtmlWidget(
          html,
          customStylesBuilder: (element) {
            if (element.classes.contains('p')) {
              return const <String, String>{'fontSize': '12', 'margin': '0'};
            }
            if (element.classes.contains('br')) {
              return const <String, String>{'fontSize': '1', 'margin': '0'};
            }
            return null;
          },
          onTapUrl: (url) async {
            final uri = Uri.tryParse(url);
            if (uri == null || !uri.hasScheme) return false;
            return launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ),
    );
  }
}
