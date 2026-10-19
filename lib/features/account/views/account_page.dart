import 'package:flutter/material.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../shared/widgets/ui.dart';
import '../view_models/account_view_model.dart';

class AccountPage extends StatelessWidget {
  final AccountViewModel vm;
  final bool startup;
  const AccountPage({super.key, required this.vm, this.startup = false});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: vm,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
              title: Text(startup ? 'daily english' : '내 계정'),
              automaticallyImplyLeading: !startup),
          body: PageBody(children: [
            const Center(child: PuppyMascot(size: 132)),
            const SizedBox(height: 20),
            TitleText(
                vm.account == null ? '학습을 시작하려면\n로그인 먼저 해주세요.' : '로그인했어요.'),
            if (vm.account == null) ...[
              const SizedBox(height: 10),
              const Text('사용하실 계정을 선택해 주세요.\n강아지와 함께 영어 공부를 시작해요!'),
            ],
            const SizedBox(height: 20),
            if (vm.account != null)
              Panel(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vm.account!.name ?? '학습자',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  if (vm.account!.email != null) Text(vm.account!.email!),
                ],
              )),
            if (vm.busy) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Text('계정을 확인하고 있어요.', textAlign: TextAlign.center),
            ],
            if (vm.account == null) ...[
              for (final provider in LoginProvider.values)
                if (vm.supportedProviders.contains(provider)) ...[
                  _loginButton(provider),
                  const SizedBox(height: 10),
                ],
              if (!vm.supportedProviders.contains(LoginProvider.naver) &&
                  !vm.supportedProviders.contains(LoginProvider.kakao))
                const Text('네이버 · 카카오 로그인도 추가될 예정이에요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: muted)),
              if (!startup)
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('로그인 없이 계속 학습하기')),
            ] else if (!vm.busy)
              TextButton(onPressed: vm.signOut, child: const Text('로그아웃')),
            if (vm.message != null) ...[
              const SizedBox(height: 16),
              Semantics(
                  liveRegion: true,
                  child: Text(vm.message!, textAlign: TextAlign.center)),
            ],
            const SizedBox(height: 24),
            const Text(
                '학습 기록은 현재 이 기기에 저장돼요.\n로그인하거나 로그아웃해도 기존 기록은 유지됩니다.\n기기 간 학습 기록 동기화는 아직 지원하지 않아요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12)),
          ]),
        ),
      );

  Widget _loginButton(LoginProvider provider) {
    final label = switch (provider) {
      LoginProvider.google => 'Google 계정으로 로그인',
      LoginProvider.kakao => '카카오 계정으로 로그인',
      LoginProvider.naver => '네이버 계정으로 로그인',
    };
    return OutlinedButton(
        key: ValueKey('login-${provider.name}'),
        style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            side: const BorderSide(color: Color(0xFF747775)),
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28))),
        onPressed: vm.busy ? null : () => vm.signIn(provider),
        child: Row(children: [
          if (provider == LoginProvider.google)
            Image.asset('images/google_sign_in.png',
                width: 20, height: 20, excludeFromSemantics: true),
          if (provider == LoginProvider.google) const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500))),
          if (provider == LoginProvider.google) const SizedBox(width: 32),
        ]));
  }
}
