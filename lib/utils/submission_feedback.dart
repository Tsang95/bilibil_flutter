import 'api_exception.dart';
import 'request_lock.dart';
import 'toast.dart';

abstract final class SubmissionFeedback {
  static Future<T> run<T>({
    required Future<T> Function() action,
    required String successMessage,
    String loadingMessage = '提交中...',
    String fallbackErrorMessage = '操作失败，请稍后重试',
    bool lock = true,
  }) async {
    Future<T> execute() async {
      try {
        final result = await action();
        showToast(successMessage, type: ToastType.success);
        return result;
      } on ApiException catch (error) {
        showToast(error.message, type: ToastType.error);
        rethrow;
      } catch (_) {
        showToast(fallbackErrorMessage, type: ToastType.error);
        rethrow;
      }
    }

    if (!lock) return execute();
    return RequestLockManager.instance.runLocked(
      execute,
      message: loadingMessage,
    );
  }
}
