import 'package:flutter/material.dart';

import '../../core/storage/onboarding_storage.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_page.dart';
import 'onboarding_item.dart';
import 'widgets/onboarding_content.dart';

/// Onboarding: narrativa de apresentação em 3 etapas.
/// PageView + PageController, estado sincronizado via setState.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  final OnboardingStorage _storage = OnboardingStorage();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == OnboardingItem.items.length - 1;

  void _nextPage() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await _storage.markAsCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: OnboardingItem.items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    OnboardingContent(item: OnboardingItem.items[index]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              for (var i = 0; i < OnboardingItem.items.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _nextPage,
                child: Text(_isLastPage ? 'Começar' : 'Avançar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
