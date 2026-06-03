import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:fashio_me/features/onboarding/presentation/providers/onboarding_providers.dart';

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
      // Complete onboarding and navigate to login
      final completed =
          await ref.read(onboardingViewModelProvider.notifier).completeOnboarding();
      if (!mounted || !completed) return;
      AppRoutes.pushReplacement(context, const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingViewModelProvider);
    final currentIndex = onboardingState.currentIndex;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            /// logo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FashioMe',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B0000),
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
                  ref.read(onboardingViewModelProvider.notifier).setIndex(index);
                },
                itemBuilder: (context, index) {
                  final data = kOnboardingItems[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
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
                                  borderRadius: BorderRadius.circular(32),
                                  color: const Color(0xFFEFE7E4),
                                ),
                              ),

                              /// image
                              Container(
                                margin: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      data.imageUrl,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),

                              /// gradient overlay
                              Container(
                                margin: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.35),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8D5),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'PERSONALIZED STYLE',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9B7A00),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// title
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// subtitle
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            data.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.6,
                              color: Colors.grey.shade700,
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
                              duration:
                                  const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              width:
                                  currentIndex == index ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(20),
                                color: currentIndex == index
                                    ? const Color(0xFF7A0000)
                                    : Colors.grey.shade300,
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
                              backgroundColor:
                                  const Color(0xFF7A0000),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
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
                              currentIndex ==
                                      kOnboardingItems.length - 1
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

                        const SizedBox(height: 28),
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