import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/ga_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BCPTrackerApp());
}

class BCPTrackerApp extends StatelessWidget {
  const BCPTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BCP Beach Rentals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.grey.shade50,
        ),
      ),
      home: const _StartupRouter(),
    );
  }
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final complete = await SettingsService.isOnboardingComplete();
    if (complete) {
      await SettingsService.initAppConfig();
    }
    setState(() => _onboardingComplete = complete);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _onboardingComplete! ? const GASelectScreen() : const OnboardingFlow();
  }
}
