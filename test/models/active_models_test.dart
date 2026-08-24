import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/invite_summary.dart';
import 'package:b_flutter/models/upload_file_result.dart';

void main() {
  test('InviteSummary accepts comma-separated legacy share domains', () {
    final summary = InviteSummary.fromJson(<String, dynamic>{
      'share_domain': 'https://a.example,https://b.example',
      'share_member_num': '3',
      'share_sum_coin': 12,
    });

    expect(summary.shareDomains, <String>[
      'https://a.example',
      'https://b.example',
    ]);
    expect(summary.invitedCount, 3);
    expect(summary.rewardCoins, 12);
  });

  test('UploadFileResult preserves final chunk status and url', () {
    final result = UploadFileResult.fromJson(<String, dynamic>{
      'status': '1',
      'url': '/uploads/video.m3u8',
    });

    expect(result.status, 1);
    expect(result.url, '/uploads/video.m3u8');
  });
}
