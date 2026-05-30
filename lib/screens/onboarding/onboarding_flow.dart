import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'location_screen.dart';
import 'inventory_setup_screen.dart';
import 'ga_setup_screen.dart';
import '../../models/beach_location.dart';
import '../../models/inventory_type.dart';
import '../../models/ga.dart';
import '../../services/settings_service.dart';
import '../ga_select_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();

  BeachLocation? _selectedLocation;
  List<InventoryType> _inventoryTypes = InventoryType.defaults
      .map((t) => t.copyWith(totalCount: 0))
      .toList();
  List<GA> _gas = [];

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await SettingsService.completeOnboarding(
      location: _selectedLocation!,
      inventoryTypes: _inventoryTypes,
      gas: _gas,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GASelectScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WelcomeScreen(onNext: _nextPage),
          LocationScreen(
            onNext: (location) {
              setState(() => _selectedLocation = location);
              _nextPage();
            },
          ),
          InventorySetupScreen(
            initialTypes: _inventoryTypes,
            onNext: (types) {
              setState(() => _inventoryTypes = types);
              _nextPage();
            },
          ),
          GASetupScreen(
            onFinish: (gas) {
              setState(() => _gas = gas);
              _finish();
            },
          ),
        ],
      ),
    );
  }
}
