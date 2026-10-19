import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/domain/repositories/auth_repository.dart';
import 'package:edu_voca/features/account/view_models/account_view_model.dart';
import 'package:edu_voca/features/account/views/account_page.dart';
import 'puppy_design_test.dart' show prepare, capture;

class FakeAuthRepository implements AuthRepository {
  final events = StreamController<Account?>.broadcast(sync: true);
  final Set<LoginProvider> providers;
  FakeAuthRepository({this.providers = const {LoginProvider.google}});
  @override
  Account? currentAccount;
  @override
  Set<LoginProvider> get supportedProviders => providers;
  @override
  Stream<Account?> get accountChanges => events.stream;
  Completer<void>? pending;
  AuthFailure? failure;
  bool initFails = false;
  int signInCalls = 0;
  @override
  Future<void> initialize() async {
    if (initFails) throw const AuthFailure('설정 확인');
  }

  @override
  Future<void> signIn(LoginProvider provider) async {
    signInCalls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    currentAccount = const Account(
        uid: 'firebase-uid', name: '학습자', email: 'learner@example.com');
    events.add(currentAccount);
  }

  @override
  Future<void> signOut() async {
    currentAccount = null;
    events.add(null);
  }
}

void main() {
  test('Restores Firebase identity and follows account changes and sign-out',
      () async {
    final repo = FakeAuthRepository()
      ..currentAccount = const Account(uid: 'restored');
    final vm = AccountViewModel(repo);
    await vm.initialize();
    expect(vm.account!.uid, 'restored');
    expect(vm.ready, isTrue);
    repo.currentAccount = const Account(uid: 'updated');
    repo.events.add(repo.currentAccount);
    expect(vm.account!.uid, 'updated');
    await vm.signOut();
    expect(vm.account, isNull);
    vm.dispose();
    await repo.events.close();
  });

  test('Login blocks duplicate taps and handles cancellation and retry',
      () async {
    final repo = FakeAuthRepository()..pending = Completer<void>();
    final vm = AccountViewModel(repo);
    await vm.initialize();
    final first = vm.signIn(LoginProvider.google);
    await vm.signIn(LoginProvider.google);
    expect(repo.signInCalls, 1);
    expect(vm.busy, isTrue);
    repo.failure = const AuthFailure('로그인을 취소했어요.', cancelled: true);
    repo.pending!.complete();
    await first;
    expect(vm.account, isNull);
    expect(vm.busy, isFalse);
    expect(vm.message, '로그인을 취소했어요.');
    repo.failure = null;
    repo.pending = null;
    await vm.signIn(LoginProvider.google);
    expect(vm.account!.uid, 'firebase-uid');
    expect(vm.message, isNull);
    vm.dispose();
    await repo.events.close();
  });

  test('Configuration failure can retry and provider support is extensible',
      () async {
    final repo = FakeAuthRepository(
        providers: {LoginProvider.google, LoginProvider.kakao})
      ..initFails = true;
    final vm = AccountViewModel(repo);
    await vm.initialize();
    expect(vm.ready, isFalse);
    expect(vm.message, '설정 확인');
    repo.initFails = false;
    await vm.signIn(LoginProvider.naver);
    expect(vm.ready, isTrue);
    expect(repo.signInCalls, 0);
    expect(vm.message, contains('지원하지 않는'));
    await vm.signIn(LoginProvider.kakao);
    expect(vm.account!.uid, 'firebase-uid');
    vm.dispose();
    await repo.events.close();
  });

  test('Disposal cancels subscription and ignores pending notifications',
      () async {
    final repo = FakeAuthRepository()..pending = Completer<void>();
    final vm = AccountViewModel(repo);
    await vm.initialize();
    var notifications = 0;
    vm.addListener(() => notifications++);
    final operation = vm.signIn(LoginProvider.google);
    vm.dispose();
    final before = notifications;
    repo.pending!.complete();
    await operation;
    expect(notifications, before);
    expect(repo.events.hasListener, isFalse);
    await repo.events.close();
  });

  testWidgets('Account UI logs in and out with local-storage notice',
      (tester) async {
    await prepare(tester, width: 320);
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeAuthRepository();
    final vm = AccountViewModel(repo);
    repo.initFails = true;
    await vm.initialize();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'Preview'),
            home: AccountPage(vm: vm, startup: true))));
    expect(find.textContaining('로그인 먼저 해주세요'), findsOneWidget);
    expect(find.text('설정 확인'), findsOneWidget);
    expect(find.textContaining('네이버 · 카카오'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-kakao')), findsNothing);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'images/google_sign_in.png'),
        findsOneWidget);
    repo.initFails = false;
    await vm.initialize();
    await tester.pump();
    await capture(tester, key, 'social-login');
    expect(find.text('Google 계정으로 로그인'), findsOneWidget);
    expect(find.textContaining('동기화는 아직'), findsOneWidget);
    await tester.tap(find.text('Google 계정으로 로그인'));
    await tester.pumpAndSettle();
    expect(find.text('learner@example.com'), findsOneWidget);
    expect(find.text('Google 계정으로 로그인'), findsNothing);
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.text('Google 계정으로 로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
    await repo.events.close();
  });
}
