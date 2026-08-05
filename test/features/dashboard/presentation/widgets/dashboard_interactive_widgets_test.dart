import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_action_panel.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_mini_icon_button.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(body: child),
    );
  }

  group('DashboardProfileMenu', () {
    testWidgets('shows the title, subtitle and a chevron when tappable', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DashboardProfileMenu(
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            icon: Icons.edit_outlined,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Update your personal information'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          DashboardProfileMenu(
            title: 'Shop',
            subtitle: 'Browse clothing',
            icon: Icons.storefront_outlined,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Shop'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('hides the chevron when onTap is null', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardProfileMenu(
            title: 'My Orders',
            subtitle: 'Purchase history',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('DashboardMiniIconButton', () {
    testWidgets('renders the given icon', (tester) async {
      await tester.pumpWidget(
        wrap(DashboardMiniIconButton(icon: Icons.close, onTap: () {})),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          DashboardMiniIconButton(
            icon: Icons.arrow_back,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('DashboardActionPanel', () {
    testWidgets('renders its icon and label', (tester) async {
      await tester.pumpWidget(
        wrap(
          DashboardActionPanel(
            icon: Icons.photo_camera_outlined,
            label: 'Camera',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Camera'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          DashboardActionPanel(
            icon: Icons.upload_outlined,
            label: 'Upload Image',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Upload Image'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
