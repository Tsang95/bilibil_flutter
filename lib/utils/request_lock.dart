import 'dart:collection';

import 'package:flutter_easyloading/flutter_easyloading.dart';

abstract interface class LockPresenter {
  void show(String message);

  void dismiss();
}

final class EasyLoadingLockPresenter implements LockPresenter {
  const EasyLoadingLockPresenter();

  @override
  void show(String message) {
    EasyLoading.show(
      status: message,
      maskType: EasyLoadingMaskType.clear,
      dismissOnTap: false,
    );
  }

  @override
  void dismiss() {
    EasyLoading.dismiss();
  }
}

final class RequestLockHandle {
  RequestLockHandle._(this._manager, this._id);

  final RequestLockManager _manager;
  final int _id;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _manager._release(_id);
  }
}

final class RequestLockManager {
  RequestLockManager({LockPresenter? presenter})
    : _presenter = presenter ?? const EasyLoadingLockPresenter();

  static final RequestLockManager instance = RequestLockManager();

  final LockPresenter _presenter;
  final LinkedHashMap<int, String> _activeLocks = LinkedHashMap<int, String>();
  int _nextId = 0;

  int get activeCount => _activeLocks.length;

  RequestLockHandle acquire({String message = '加载中...'}) {
    final id = _nextId++;
    _activeLocks[id] = message;
    _presenter.show(message);
    return RequestLockHandle._(this, id);
  }

  Future<T> runLocked<T>(
    Future<T> Function() action, {
    String message = '加载中...',
  }) async {
    final handle = acquire(message: message);
    try {
      return await action();
    } finally {
      handle.release();
    }
  }

  void _release(int id) {
    if (_activeLocks.remove(id) == null) return;
    if (_activeLocks.isEmpty) {
      _presenter.dismiss();
      return;
    }
    _presenter.show(_activeLocks.values.last);
  }

  void releaseAll() {
    if (_activeLocks.isEmpty) return;
    _activeLocks.clear();
    _presenter.dismiss();
  }
}
