import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('onboarding is shown by default until completed', () async {
    final shouldShow = await OnboardingService.shouldShowOnboarding();
    expect(shouldShow, isTrue);

    await OnboardingService.completeOnboarding();

    final afterCompletion = await OnboardingService.shouldShowOnboarding();
    expect(afterCompletion, isFalse);
  });
}
