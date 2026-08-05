import 'package:fashio_me/features/dashboard/presentation/pages/discover_tab.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(body: child),
      ),
    );
  }

  group('DiscoverTab & Fashion Articles Widget Tests', () {
    testWidgets('renders Discover tab sections and fashion articles', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          DiscoverTab(state: _mockState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Style Guides'), findsOneWidget);
      expect(find.text('Fashion Tips & Articles'), findsOneWidget);
      expect(
        find.text('10 Style Rules Every Fashion Lover Should Know'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('tapping an article card opens full Article Detail Sheet', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          DiscoverTab(state: _mockState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final articleCard = find.text(
        '10 Style Rules Every Fashion Lover Should Know',
      ).first;
      expect(articleCard, findsOneWidget);

      await tester.tap(articleCard);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Article Detail Sheet content
      expect(find.text('FUNDAMENTALS'), findsOneWidget);
      expect(find.text('FashioMe Editorial'), findsOneWidget);
      expect(find.text('Key Takeaways'), findsOneWidget);
      expect(find.text('Save Article to Bookmarks'), findsOneWidget);
    });

    testWidgets('tapping Save Article to Bookmarks saves article and shows SnackBar', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          DiscoverTab(state: _mockState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Open article detail sheet
      await tester.tap(
        find.text('10 Style Rules Every Fashion Lover Should Know').first,
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll into view & tap save button
      final saveBtn = find.text('Save Article to Bookmarks');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(saveBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify SnackBar appears
      expect(
        find.text(
          '"10 Style Rules Every Fashion Lover Should Know" saved to your bookmarks!',
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('tapping Style Guide card opens its respective detailed article', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          DiscoverTab(state: _mockState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final styleGuideCard = find.text('How to Dress for Your Body Shape').first;
      expect(styleGuideCard, findsOneWidget);

      await tester.tap(styleGuideCard);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('FIT & SILHOUETTE'), findsOneWidget);
      expect(find.text('Key Takeaways'), findsOneWidget);
    });

    testWidgets('tapping View All under Fashion Tips & Articles lists all articles', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(
        wrap(
          DiscoverTab(state: _mockState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final viewAllBtn = find.text('View All').last;
      await tester.tap(viewAllBtn);
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Effortless Everyday Style & Capsule Wardrobes'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Layering Like a Pro for Every Season'), findsAtLeastNWidgets(1));
    });
  });
}
