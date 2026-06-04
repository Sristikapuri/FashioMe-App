class OnboardingItem {
  final String title;
  final String subtitle;
  final String imageUrl;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

final List<OnboardingItem> kOnboardingItems = [
  OnboardingItem(
    title: 'Welcome to FashioMe',
    subtitle: 'Discover the latest fashion trends and styles',
    imageUrl: 'assets/images/onboarding1.png',
  ),
  OnboardingItem(
    title: 'Shop Your Style',
    subtitle: 'Find clothes that match your personality',
    imageUrl: 'assets/images/onboarding2.png',
  ),
  OnboardingItem(
    title: 'Get Started',
    subtitle: 'Create an account and start shopping today',
    imageUrl: 'assets/images/onboarding3.png',
  ),
];
