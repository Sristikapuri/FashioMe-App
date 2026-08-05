import 'package:fashio_me/core/services/sensors/sensor_settings.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/ai_stylist_tab.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSensorGesturesNotifier extends SensorGesturesNotifier {
  _FakeSensorGesturesNotifier(this.initialState);
  final bool initialState;

  @override
  bool build() => initialState;
}

DashboardState _mockState() {
  const dummyRec = DashboardRecommendation(
    id: 'rec_1',
    title: 'Summer Chic',
    occasion: 'Casual Day Out',
    category: 'Casual',
    mood: 'Relaxed',
    imageUrl: '',
    outfit: 'Linen Shirt & Shorts',
    hairstyle: 'Textured Crop',
    explanation: 'Lightweight fabrics keep you cool while staying sharp.',
    palette: [0xFFFFFFFF, 0xFFC5A059],
    paletteLabels: ['White', 'Gold'],
  );

  return DashboardState(
    aiProcessingMessage: 'Ready to craft a new recommendation.',
    aiStyleOfDay: dummyRec,
    currentRecommendation: dummyRec,
    homeRecommendations: const [dummyRec],
    wardrobeItems: const [],
    discoverItems: const [],
    profileData: DashboardProfileData.empty(),
  );
}

void main() {
  Future<void> prepareSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  Widget wrap(Widget child, {required bool sensorEnabled}) {
    return ProviderScope(
      overrides: [
        sensorGesturesEnabledProvider.overrideWith(
          () => _FakeSensorGesturesNotifier(sensorEnabled),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(body: child),
      ),
    );
  }

  group('AiStylistTab Widget Tests', () {
    testWidgets('renders occasion chips, vibe options and generate button', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          AiStylistTab(
            state: _mockState(),
            selectedEvent: 'Casual Day Out',
            selectedSource: 'New Inspiration',
            selectedWeather: 'Summer / Hot',
            selectedVibe: 'Minimalist',
            events: const [
              ('Casual Day Out', Icons.wb_sunny_outlined),
              ('Work & Office', Icons.business_outlined),
            ],
            onEventChanged: (_) {},
            onSourceChanged: (_) {},
            onWeatherChanged: (_) {},
            onVibeChanged: (_) {},
          ),
          sensorEnabled: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Occasion'), findsOneWidget);
      expect(find.text('Customize Your Look'), findsOneWidget);
      expect(find.text('Generate Outfit  ✦'), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
    });

    testWidgets('shows shake-to-refresh hint when sensor gestures are enabled', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          AiStylistTab(
            state: _mockState(),
            selectedEvent: 'Casual Day Out',
            selectedSource: 'New Inspiration',
            selectedWeather: 'Summer / Hot',
            selectedVibe: 'Minimalist',
            events: const [('Casual Day Out', Icons.wb_sunny_outlined)],
            onEventChanged: (_) {},
            onSourceChanged: (_) {},
            onWeatherChanged: (_) {},
            onVibeChanged: (_) {},
          ),
          sensorEnabled: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Shake your phone to generate a new outfit'),
        findsOneWidget,
      );
    });

    testWidgets('hides shake-to-refresh hint when sensor gestures are disabled', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          AiStylistTab(
            state: _mockState(),
            selectedEvent: 'Casual Day Out',
            selectedSource: 'New Inspiration',
            selectedWeather: 'Summer / Hot',
            selectedVibe: 'Minimalist',
            events: const [('Casual Day Out', Icons.wb_sunny_outlined)],
            onEventChanged: (_) {},
            onSourceChanged: (_) {},
            onWeatherChanged: (_) {},
            onVibeChanged: (_) {},
          ),
          sensorEnabled: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Shake your phone to generate a new outfit'),
        findsNothing,
      );
    });
  });
}
