import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:fashio_me/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:fashio_me/features/silhouette/presentation/pages/silhouette_flow_page.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Removed redirect check to allow onboarding to show
  }

  Future<void> nextPage() async {
    final onboardingState = ref.read(onboardingViewModelProvider);
    if (onboardingState.currentIndex < kOnboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding and navigate to silhouette
      final completed = await ref
          .read(onboardingViewModelProvider.notifier)
          .completeOnboarding();
      if (!mounted || !completed) return;
      AppRoutes.pushReplacement(context, const SilhouetteFlowPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingViewModelProvider);
    final currentIndex = onboardingState.currentIndex;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            /// logo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FashioMe',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// pageview
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: kOnboardingItems.length,
                onPageChanged: (index) {
                  ref
                      .read(onboardingViewModelProvider.notifier)
                      .setIndex(index);
                },
                itemBuilder: (context, index) {
                  final data = kOnboardingItems[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        /// image section
                        Expanded(
                          flex: 5,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              /// background card
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: AppColors.cardBackground,
                                ),
                              ),

                              /// image
                              Container(
                                margin: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.premiumInk.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    data.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, _, _) =>
                                        Container(color: AppColors.surfaceSoft),
                                  ),
                                ),
                              ),

                              /// gradient overlay
                              Container(
                                margin: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      AppColors.heroOverlayDark,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        /// tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'PERSONALIZED STYLE',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// title
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            data.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.6,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const Spacer(),

                        /// dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            kOnboardingItems.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: currentIndex == index ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: currentIndex == index
                                    ? AppColors.primary
                                    : AppColors.divider,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: onboardingState.isCompleting
                                ? null
                                : nextPage,
                            child: onboardingState.isCompleting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    currentIndex == kOnboardingItems.length - 1
                                        ? 'Continue'
                                        : 'Next',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
