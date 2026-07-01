import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:fashio_me/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('OnboardingViewModel identifies the last page correctly', () {
    final notifier = container.read(onboardingViewModelProvider.notifier);

    expect(notifier.isLastPage(0), isFalse);
    expect(notifier.isLastPage(kOnboardingItems.length - 1), isTrue);
  });
}
