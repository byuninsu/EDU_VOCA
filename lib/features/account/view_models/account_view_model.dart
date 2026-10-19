import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/repositories/auth_repository.dart';

class AccountViewModel extends ChangeNotifier {
  final AuthRepository repository;
  StreamSubscription<Account?>? _subscription;
  Account? account;
  bool busy = false, ready = false, _disposed = false;
  String? message;
  AccountViewModel(this.repository);
  Set<LoginProvider> get supportedProviders => repository.supportedProviders;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (busy || ready || _disposed) return;
    busy = true;
    message = null;
    _notify();
    try {
      await repository.initialize().timeout(const Duration(seconds: 12));
      if (_disposed) return;
      account = repository.currentAccount;
      _subscription = repository.accountChanges.listen((value) {
        account = value;
        _notify();
      }, onError: (Object _) {
        message = '계정 상태를 확인하지 못했어요.\n잠시 후 다시 시도해 주세요.';
        _notify();
      });
      ready = true;
    } catch (e) {
      message =
          e is AuthFailure ? e.message : '로그인 서비스에 연결하지 못했어요.\n다시 시도해 주세요.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> signIn(LoginProvider provider) async {
    if (busy || _disposed || account != null) return;
    if (!ready) await initialize();
    if (!ready || busy || _disposed || account != null) return;
    if (!supportedProviders.contains(provider)) {
      message = '아직 지원하지 않는 로그인 방식이에요.';
      _notify();
      return;
    }
    await _run(() => repository.signIn(provider));
  }

  Future<void> signOut() async {
    if (!ready || busy || _disposed || account == null) return;
    await _run(repository.signOut);
  }

  Future<void> _run(Future<void> Function() action) async {
    busy = true;
    message = null;
    _notify();
    try {
      await action();
      account = repository.currentAccount;
    } catch (e) {
      message = e is AuthFailure ? e.message : '계정 작업에 실패했어요.\n다시 시도해 주세요.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
