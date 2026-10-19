import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/app/app.dart';
import 'package:edu_voca/domain/repositories/auth_repository.dart';
import 'package:edu_voca/features/account/view_models/account_view_model.dart';
import 'package:edu_voca/features/home/views/home_shell.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'support.dart';
import 'account_test.dart' show FakeAuthRepository;
import 'puppy_design_test.dart' show prepare, capture;

void main() {
  testWidgets('Compact home fits normal phone and shortcuts select every tab',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key, child: DailyEnglishApp(state: state, fontFamily: 'Preview')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('home-start')).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('home-shortcut-3')).hitTestable(),
        findsOneWidget);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, lessThan(100));
    await capture(tester, key, 'compact-home');
    // No bottom bar: shortcuts open each section, back returns home.
    expect(find.byType(NavigationBar), findsNothing);
    for (final (i, title) in [(1, '단어'), (2, '영작'), (3, '복습')]) {
      await tester.tap(find.byKey(ValueKey('home-shortcut-$i')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      if (i == 3) {
        await tester.binding.handlePopRoute(); // system back
      } else {
        await tester.tap(find.byKey(const ValueKey('section-back')));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-start')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets('Small large-text home can continue after daily goal',
      (tester) async {
    await prepare(tester, width: 320);
    final state = createLearning(completed: 10);
    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: DailyEnglishApp(state: state, fontFamily: 'Preview')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('단어 계속하기'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('단어 계속하기'));
    await tester.pumpAndSettle();
    expect(find.byType(WordPractice), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
      'Startup login cancels safely, enters home on success and gates logout',
      (tester) async {
    // Discard codecs left pending when the previous test disposed its route.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await prepare(tester);
    final repo = FakeAuthRepository();
    final vm = AccountViewModel(repo);
    await vm.initialize();
    final state = createLearning();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child:
            DailyEnglishApp(state: state, account: vm, fontFamily: 'Preview')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsNothing);
    expect(find.text('로그인 없이 계속 학습하기'), findsNothing);
    await capture(tester, key, 'startup-login');
    repo.failure = const AuthFailure('로그인을 취소했어요.', cancelled: true);
    await tester.tap(find.text('Google 계정으로 로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsNothing);
    repo.failure = null;
    await tester.tap(find.text('Google 계정으로 로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    await tester.tap(find.byTooltip('내 계정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsNothing);
    expect(find.text('Google 계정으로 로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
    state.dispose();
    await repo.events.close();
  });
  testWidgets('Restored account enters home without requesting Google again',
      (tester) async {
    await prepare(tester);
    final repo = FakeAuthRepository()
      ..currentAccount = const Account(uid: 'restored');
    final vm = AccountViewModel(repo);
    await vm.initialize();
    final state = createLearning();
    await tester.pumpWidget(DailyEnglishApp(state: state, account: vm));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(repo.signInCalls, 0);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
    state.dispose();
    await repo.events.close();
  });
  testWidgets('Firebase setup failure stays on startup with retry',
      (tester) async {
    await prepare(tester);
    final repo = FakeAuthRepository()..initFails = true;
    final vm = AccountViewModel(repo);
    await vm.initialize();
    final state = createLearning();
    await tester.pumpWidget(DailyEnglishApp(state: state, account: vm));
    await tester.pumpAndSettle();
    expect(find.text('설정 확인'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
    repo.initFails = false;
    await tester.tap(find.text('다시 연결'));
    await tester.pumpAndSettle();
    expect(find.text('Google 계정으로 로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
    state.dispose();
    await repo.events.close();
  });
}
