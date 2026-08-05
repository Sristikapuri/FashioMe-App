import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_color_dot.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_data_pill.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_measurement_row.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_small_info_panel.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(body: child),
    );
  }

  group('DashboardMeasurementRow', () {
    testWidgets('shows the label and its value', (tester) async {
      await tester.pumpWidget(
        wrap(const DashboardMeasurementRow(label: 'Height', value: '172 cm')),
      );

      expect(find.text('Height'), findsOneWidget);
      expect(find.text('172 cm'), findsOneWidget);
    });

    testWidgets('falls back to "Not set" for an empty value', (tester) async {
      await tester.pumpWidget(
        wrap(const DashboardMeasurementRow(label: 'Face Shape', value: '')),
      );

      expect(find.text('Face Shape'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
    });
  });

  group('DashboardStatTile', () {
    testWidgets('shows the value and its label', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            children: [DashboardStatTile(value: '6', label: 'Saved Looks')],
          ),
        ),
      );

      expect(find.text('6'), findsOneWidget);
      expect(find.text('Saved Looks'), findsOneWidget);
    });
  });

  group('DashboardDataPill', () {
    testWidgets('joins the label and value into a single pill', (tester) async {
      await tester.pumpWidget(
        wrap(const DashboardDataPill(label: 'Height', value: '172cm')),
      );

      expect(find.text('Height  172cm'), findsOneWidget);
    });
  });

  group('DashboardSmallInfoPanel', () {
    testWidgets('renders the title, subtitle and icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardSmallInfoPanel(
            title: 'Closet is empty',
            subtitle: 'Add tops, bottoms and shoes.',
            icon: Icons.checkroom_outlined,
          ),
        ),
      );

      expect(find.text('Closet is empty'), findsOneWidget);
      expect(find.text('Add tops, bottoms and shoes.'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });
  });

  group('DashboardColorDot', () {
    testWidgets('paints a circular swatch in the given color', (tester) async {
      await tester.pumpWidget(wrap(const DashboardColorDot(color: Colors.red)));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
      expect(decoration.shape, BoxShape.circle);
    });
  });
}
