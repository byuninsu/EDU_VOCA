import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../firebase_options.dart';

/// Future Kakao/Naver strategies must authenticate through a trusted backend
/// before exchanging a Firebase custom token. They must not trust client IDs.
abstract class FirebaseLoginStrategy {
  Future<void> signIn(FirebaseAuth auth);
  Future<void> signOut();
}

class GoogleLoginStrategy implements FirebaseLoginStrategy {
  Future<void>? _initialization;
  Future<void> _initialize() async {
    try {
      await (_initialization ??= GoogleSignIn.instance.initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<void> signIn(FirebaseAuth auth) async {
    await _initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw const AuthFailure('구글 계정을 확인하지 못했어요.\n다시 시도해 주세요.');
    }
    await auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: token));
  }

  @override
  Future<void> signOut() async {
    // Google has no active SDK session if only a Firebase session was restored.
    if (_initialization != null) {
      await _initialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}

class FirebaseAuthRepository implements AuthRepository {
  final Map<LoginProvider, FirebaseLoginStrategy> _strategies;
  FirebaseAuth? _auth;
  Future<void>? _initialization;
  FirebaseAuthRepository(
      {Map<LoginProvider, FirebaseLoginStrategy>? strategies})
      : _strategies = Map.unmodifiable(strategies ??
            {
              LoginProvider.google: GoogleLoginStrategy(),
            });

  @override
  Set<LoginProvider> get supportedProviders =>
      Set.unmodifiable(_strategies.keys);
  Account? _account(User? user) => user == null
      ? null
      : Account(uid: user.uid, name: user.displayName, email: user.email);
  @override
  Account? get currentAccount => _account(_auth?.currentUser);
  @override
  Stream<Account?> get accountChanges =>
      _auth!.authStateChanges().map(_account);

  @override
  Future<void> initialize() async {
    try {
      await (_initialization ??= _initialize());
    } on AuthFailure {
      _initialization = null;
      rethrow;
    } on PlatformException catch (e) {
      _initialization = null;
      if (e.message?.contains('Failed to load FirebaseOptions') == true) {
        throw const AuthFailure('앱의 로그인 연결 설정이 누락되었어요.\n설정이 완료된 앱으로 업데이트해 주세요.');
      }
      throw const AuthFailure('로그인 서비스를 연결하지 못했어요.\n잠시 후 로그인 버튼을 다시 눌러 주세요.');
    } on FirebaseException catch (e) {
      _initialization = null;
      throw AuthFailure(e.code == 'network-request-failed'
          ? '인터넷 연결을 확인하고 다시 시도해 주세요.'
          : '앱의 로그인 연결 설정을 확인해야 해요.\n설정이 완료된 앱으로 업데이트해 주세요.');
    } catch (_) {
      _initialization = null;
      throw const AuthFailure(
          '로그인 서비스를 준비하지 못했어요.\n앱의 로그인 설정과 인터넷 연결을 확인해 주세요.');
    }
  }

  Future<void> _initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const AuthFailure('현재 구글 로그인은 Android에서 지원해요.');
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    _auth = FirebaseAuth.instance;
  }

  @override
  Future<void> signIn(LoginProvider provider) async {
    await initialize();
    final strategy = _strategies[provider];
    if (strategy == null) throw const AuthFailure('아직 지원하지 않는 로그인 방식이에요.');
    if (_auth!.currentUser != null) {
      throw const AuthFailure('다른 계정으로 로그인하려면 먼저 로그아웃해 주세요.');
    }
    try {
      await strategy.signIn(_auth!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('로그인을 취소했어요.', cancelled: true);
      }
      throw const AuthFailure('구글 로그인에 실패했어요.\n인터넷 연결과 앱의 로그인 설정을 확인해 주세요.');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(switch (e.code) {
        'network-request-failed' => '인터넷 연결을 확인하고 다시 시도해 주세요.',
        'user-disabled' => '사용이 중지된 계정이에요.',
        'operation-not-allowed' => '이 앱에서 구글 로그인이 아직 활성화되지 않았어요.',
        'account-exists-with-different-credential' =>
          '다른 로그인 방식으로 가입한 계정이에요.\n기존 방식으로 로그인해 주세요.',
        _ => '로그인하지 못했어요.\n잠시 후 다시 시도해 주세요.',
      });
    }
  }

  @override
  Future<void> signOut() async {
    await _auth?.signOut();
    // Firebase is the source of truth. Provider cleanup cannot retain an app session.
    for (final strategy in _strategies.values) {
      try {
        await strategy.signOut();
      } catch (_) {/* Best-effort SDK cleanup. */}
    }
  }
}
