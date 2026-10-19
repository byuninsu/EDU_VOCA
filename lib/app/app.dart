import 'package:flutter/material.dart';
import '../features/account/view_models/account_view_model.dart';
import '../features/account/views/account_page.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/features/home/views/home_shell.dart';

class DailyEnglishApp extends StatelessWidget {
  final LearningViewModel state;
  final String? fontFamily;
  final AccountViewModel? account;
  const DailyEnglishApp(
      {super.key, required this.state, this.fontFamily, this.account});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Daily English',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: fontFamily,
          useMaterial3: true,
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(
              seedColor: teal,
              primary: teal,
              secondary: const Color(0xFF9B632E),
              surface: paper,
              onSurface: ink),
          appBarTheme: const AppBarTheme(
              backgroundColor: paper,
              surfaceTintColor: Colors.transparent,
              foregroundColor: ink,
              scrolledUnderElevation: 0),
          dividerTheme: const DividerThemeData(color: warmLine),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: teal,
              linearTrackColor: warmLine,
              borderRadius: BorderRadius.all(Radius.circular(12))),
          navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: paper,
              indicatorColor: mint,
              elevation: 0,
              labelTextStyle: WidgetStatePropertyAll(TextStyle(
                  fontSize: 12, color: ink, fontWeight: FontWeight.w700))),
          chipTheme: ChipThemeData(
              backgroundColor: Colors.white,
              selectedColor: mint,
              side: const BorderSide(color: warmLine),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24))),
          textTheme: const TextTheme(
              bodyMedium: TextStyle(color: muted, height: 1.6),
              bodyLarge: TextStyle(color: ink, height: 1.6)),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: warmLine)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: teal, width: 2)),
              contentPadding: const EdgeInsets.all(20)),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  textStyle: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700))),
        ),
        builder: account == null
            ? null
            : (context, child) => AnimatedBuilder(
                  animation: account!,
                  builder: (context, _) => account!.account == null
                      ? Navigator(
                          key: const ValueKey('startup-navigation'),
                          onGenerateRoute: (_) => MaterialPageRoute<void>(
                              builder: (_) =>
                                  AccountPage(vm: account!, startup: true)))
                      : child!,
                ),
        home: HomeShell(state: state, account: account),
      );
}
