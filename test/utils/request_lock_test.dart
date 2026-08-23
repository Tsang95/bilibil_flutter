import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/request_lock.dart';

void main() {
  test('concurrent locks dismiss only after the final request completes', () {
    final presenter = _FakeLockPresenter();
    final manager = RequestLockManager(presenter: presenter);

    final first = manager.acquire(message: '加载首页...');
    final second = manager.acquire(message: '提交中...');

    expect(manager.activeCount, 2);
    expect(presenter.messages, ['加载首页...', '提交中...']);

    first.release();
    expect(manager.activeCount, 1);
    expect(presenter.dismissCount, 0);
    expect(presenter.messages.last, '提交中...');

    second.release();
    expect(manager.activeCount, 0);
    expect(presenter.dismissCount, 1);
  });
}

final class _FakeLockPresenter implements LockPresenter {
  final List<String> messages = <String>[];
  int dismissCount = 0;

  @override
  void show(String message) => messages.add(message);

  @override
  void dismiss() => dismissCount++;
}
