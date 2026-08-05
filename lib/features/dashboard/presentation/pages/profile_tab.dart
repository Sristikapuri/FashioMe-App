import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/core/localization/locale_notifier.dart';
import 'package:fashio_me/core/services/biometric/biometric_auth_service.dart';
import 'package:fashio_me/core/services/biometric/biometric_settings_notifier.dart';
import 'package:fashio_me/core/services/sensors/sensor_settings.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/profile_update_page.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/utils/dashboard_name_utils.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_measurement_row.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_network_image.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_profile_completion_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_profile_menu.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_stats_row.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_style_preferences_card.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileCompletion = _calculateProfileCompletion(state);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.4),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: DashboardPalette.cardAlt,
                  backgroundImage: state.profileData.profileImage.isEmpty
                      ? null
                      : CachedNetworkImageProvider(
                          ApiEndpoints.resolveAssetUrl(
                            state.profileData.profileImage,
                          ),
                        ),
                  child: state.profileData.profileImage.isEmpty
                      ? Text(
                          dashboardInitials(state.profileData.displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontFamily: AppFonts.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.profileData.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.profileData.email.isEmpty
                    ? 'Style is a way to show who you are'
                    : 'Style is a way to show who you are\nwithout speaking.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        DashboardProfileCompletionCard(completion: profileCompletion),
        const SizedBox(height: 24),
        DashboardStatsRow(state: state),
        const SizedBox(height: 24),
        DashboardStylePreferencesCard(state: state),
        const SizedBox(height: 24),
        DashboardProfileMenu(
          title: 'Edit Profile',
          subtitle: 'Update your personal information and photo',
          icon: Icons.edit_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileUpdatePage(),
              ),
            );
          },
        ),
        DashboardProfileMenu(
          title: 'My Silhouette',
          subtitle:
              '${state.profileData.bodyType} body & ${state.profileData.faceShape} analysis',
          icon: Icons.accessibility_new_outlined,
          onTap: () {
            AppRoutes.toSilhouette(context);
          },
        ),
        DashboardProfileMenu(
          title: 'Style Preferences',
          subtitle: state.profileData.stylePreferences.isEmpty
              ? 'Tap to select style moods'
              : state.profileData.stylePreferences.join(', '),
          icon: Icons.tune_outlined,
          onTap: () {
            _showStylePreferencesSheet(context, ref, state);
          },
        ),
        DashboardProfileMenu(
          title: 'Saved Looks',
          subtitle:
              '${state.homeRecommendations.length} AI-generated looks saved',
          icon: Icons.favorite_border,
          onTap: () {
            _showSavedLooksSheet(context, ref, state);
          },
        ),
        DashboardProfileMenu(
          title: 'Measurements',
          subtitle:
              '${state.profileData.heightCm} cm • ${state.profileData.weightKg} kg • ${state.profileData.skinTone} tone',
          icon: Icons.straighten_outlined,
          onTap: () {
            _showMeasurementsSheet(context, state);
          },
        ),
        DashboardProfileMenu(
          title: 'My Orders',
          subtitle: 'Your saved custom items & purchase history',
          icon: Icons.receipt_long_outlined,
          onTap: () => AppRoutes.toOrderHistory(context),
        ),
        DashboardProfileMenu(
          title: 'My Wishlist',
          subtitle: 'Products you saved for later',
          icon: Icons.favorite_border,
          onTap: () => AppRoutes.toWishlist(context),
        ),
        DashboardProfileMenu(
          title: 'Shop',
          subtitle: 'Browse clothing and styling matches',
          icon: Icons.storefront_outlined,
          onTap: () => AppRoutes.toShop(context),
        ),
        DashboardProfileMenu(
          title: 'My Reviews',
          subtitle: 'Ratings and reviews you\'ve written',
          icon: Icons.star_outline_rounded,
          onTap: () => AppRoutes.toMyReviews(context),
        ),
        DashboardProfileMenu(
          title: 'Closet',
          subtitle:
              '${state.wardrobeItems.length} items in your digital wardrobe',
          icon: Icons.checkroom_outlined,
          onTap: () {
            ref.read(dashboardViewModelProvider.notifier).setIndex(2);
          },
        ),
        DashboardProfileMenu(
          title: 'Privacy & Security',
          subtitle: 'Password and account protection',
          icon: Icons.shield_outlined,
          onTap: () {
            _showSecuritySheet(context);
          },
        ),
        DashboardProfileMenu(
          title: 'Subscription',
          subtitle: 'View your current plan',
          icon: Icons.workspace_premium_outlined,
          onTap: () {
            _showSubscriptionSheet(context);
          },
        ),
        DashboardProfileMenu(
          title: 'Settings',
          subtitle: 'Account, privacy & app preferences',
          icon: Icons.settings_outlined,
          onTap: () {
            _showSettingsSheet(context, ref);
          },
        ),
        DashboardProfileMenu(
          title: 'Notifications',
          subtitle: 'Daily outfits & trend alerts',
          icon: Icons.notifications_none_rounded,
          onTap: () {
            showDashboardNotificationsSheet(context, ref);
          },
        ),
        DashboardProfileMenu(
          title: 'Help & Support',
          subtitle: 'FAQ, contact & app guide',
          icon: Icons.help_outline,
          onTap: () {
            _showHelpSupportSheet(context);
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              final didLogout = await ref
                  .read(authSessionViewModelProvider.notifier)
                  .logout();
              if (!context.mounted || !didLogout) {
                return;
              }
              AppRoutes.toLogin(context);
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              context.strings.signOut,
              style: const TextStyle(fontFamily: AppFonts.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateProfileCompletion(DashboardState state) {
    int completedFields = 0;
    int totalFields = 6;

    if (state.profileData.displayName.isNotEmpty) completedFields++;
    if (state.profileData.email.isNotEmpty) completedFields++;
    if (state.profileData.bodyType.isNotEmpty) completedFields++;
    if (state.profileData.skinTone.isNotEmpty) completedFields++;
    if (state.profileData.stylePreferences.isNotEmpty) completedFields++;
    if (state.profileData.faceShape.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }
}

void _showStylePreferencesSheet(
  BuildContext context,
  WidgetRef ref,
  DashboardState state,
) {
  final allStyles = [
    'Minimal',
    'Glam',
    'Casual',
    'Traditional',
    'Streetwear',
    'Formal',
    'Boho',
    'Vintage',
  ];
  final current = Set<String>.from(state.profileData.stylePreferences);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Style Preferences',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontFamily: AppFonts.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select style moods to customize your AI recommendations.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allStyles.map((style) {
                    final selected = current.contains(style);
                    return FilterChip(
                      label: Text(style),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) {
                            current.add(style);
                          } else {
                            current.remove(style);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final updatedProfile = state.profileData.copyWith(
                        stylePreferences: current.toList(),
                      );
                      await ref
                          .read(dashboardViewModelProvider.notifier)
                          .updateProfileData(updatedProfile);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      'Save Preferences',
                      style: TextStyle(fontFamily: AppFonts.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showSavedLooksSheet(
  BuildContext context,
  WidgetRef ref,
  DashboardState state,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final items = state.homeRecommendations;
      return Container(
        height: context.screenHeight * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saved AI Looks',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontFamily: AppFonts.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No saved looks yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            ref
                                .read(dashboardViewModelProvider.notifier)
                                .selectRecommendation(item);
                            ref
                                .read(dashboardViewModelProvider.notifier)
                                .setIndex(1);
                          },
                          child: DashboardLuxuryCard(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: DashboardNetworkImage(
                                      url: item.imageUrl,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  item.occasion,
                                  style: const TextStyle(
                                    color: DashboardPalette.mutedText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

void _showMeasurementsSheet(BuildContext context, DashboardState state) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Measurements & Fit Profile',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 16),
              DashboardMeasurementRow(
                label: 'Height',
                value: '${state.profileData.heightCm} cm',
              ),
              DashboardMeasurementRow(
                label: 'Weight',
                value: '${state.profileData.weightKg} kg',
              ),
              DashboardMeasurementRow(
                label: 'Body Build',
                value: state.profileData.bodyType,
              ),
              DashboardMeasurementRow(
                label: 'Face Shape',
                value: state.profileData.faceShape,
              ),
              DashboardMeasurementRow(
                label: 'Skin Tone',
                value: state.profileData.skinTone,
              ),
              DashboardMeasurementRow(
                label: 'Style Mood',
                value: state.profileData.styleMood,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileUpdatePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(
                    'Edit Measurements',
                    style: TextStyle(fontFamily: AppFonts.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showLanguagePicker(BuildContext context, WidgetRef ref) {
  final strings = context.strings;
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer(
        builder: (dialogContext, ref, _) {
          final currentLocale = ref.watch(localeProvider);
          return AlertDialog(
            title: Text(strings.settingsLanguage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(strings.languageEnglish),
                  trailing: currentLocale.languageCode == 'en'
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('en'));
                    Navigator.pop(dialogContext);
                  },
                ),
                ListTile(
                  title: Text(strings.languageNepali),
                  trailing: currentLocale.languageCode == 'ne'
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('ne'));
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.close),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final strings = context.strings;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.settingsTitle,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
                title: Text(strings.settingsRefreshCache),
                subtitle: Text(strings.settingsRefreshCacheSubtitle),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(dashboardViewModelProvider.notifier)
                      .clearCacheAndRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dashboard cache cleared and synced!'),
                      ),
                    );
                  }
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final isNepali = ref.watch(
                    localeProvider.select(
                      (locale) => locale.languageCode == 'ne',
                    ),
                  );
                  return ListTile(
                    leading: const Icon(
                      Icons.language_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(strings.settingsLanguage),
                    subtitle: Text(
                      isNepali
                          ? strings.languageNepali
                          : strings.languageEnglish,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showLanguagePicker(context, ref);
                    },
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final enabled = ref.watch(sensorGesturesEnabledProvider);
                  return SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    secondary: const Icon(
                      Icons.screen_rotation_alt_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Sensor gestures'),
                    subtitle: Text(
                      enabled
                          ? 'Shake to refresh; tilt to filter shop items'
                          : 'Enable shake and tilt shortcuts in Shop',
                    ),
                    value: enabled,
                    onChanged: (value) => ref
                        .read(sensorGesturesEnabledProvider.notifier)
                        .setEnabled(value),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final biometricEnabled = ref.watch(biometricSettingsProvider);
                  return FutureBuilder<bool>(
                    future: ref
                        .read(biometricAuthServiceProvider)
                        .isSupported(),
                    builder: (context, snapshot) {
                      final supported = snapshot.data ?? false;
                      return SwitchListTile(
                        activeThumbColor: AppColors.primary,
                        secondary: const Icon(
                          Icons.fingerprint,
                          color: AppColors.primary,
                        ),
                        title: Text(strings.settingsBiometric),
                        subtitle: Text(
                          !supported
                              ? strings.settingsBiometricUnavailable
                              : (biometricEnabled
                                    ? strings.settingsBiometricSubtitleOn
                                    : strings.settingsBiometricSubtitleOff),
                        ),
                        value: biometricEnabled && supported,
                        onChanged: !supported
                            ? null
                            : (value) async {
                                if (value) {
                                  // Verify biometric actually works on this
                                  // device before turning the lock on, so the
                                  // user can never lock themselves out.
                                  final verified = await ref
                                      .read(biometricAuthServiceProvider)
                                      .authenticate(
                                        reason: strings.biometricPromptReason,
                                      );
                                  if (!verified) return;
                                }
                                await ref
                                    .read(biometricSettingsProvider.notifier)
                                    .setEnabled(value);
                              },
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                title: Text(strings.settingsPrivacyPolicy),
                subtitle: Text(strings.settingsPrivacyPolicySubtitle),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(strings.settingsPrivacyPolicy),
                      content: const Text(
                        'FashioMe respects your privacy. All style measurements and uploaded images are processed securely to provide personalized fashion recommendations.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(strings.close),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                title: Text(strings.settingsAbout),
                subtitle: Text(strings.settingsAboutSubtitle),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(strings.settingsAbout),
                      content: const Text(
                        'FashioMe is your luxury AI stylist — personalized outfit recommendations, '
                        'a smart digital wardrobe, and curated shopping, all in one app.\n\n'
                        'Version 1.0.0',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(strings.close),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showSecuritySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy & Security',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                title: const Text('Change password'),
                subtitle: const Text(
                  'Update your login password from the edit profile page',
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileUpdatePage(),
                    ),
                  );
                },
              ),
              const ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
                title: Text('Security status'),
                subtitle: Text(
                  'Your account is currently protected with standard login security.',
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showSubscriptionSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subscription',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: AppFonts.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '\$0',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: AppFonts.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final feature in const [
                      'AI chat styling',
                      'Outfit generation',
                      'Wardrobe storage',
                      'Limited image generation',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              feature,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Current plan',
                        style: TextStyle(
                          fontFamily: AppFonts.bold,
                          color: AppColors.primaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Paid subscriptions are not enabled yet. This screen will show upgrade options when billing is connected.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showDashboardNotificationsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final enabled = ref
          .read(dashboardViewModelProvider)
          .profileData
          .notificationsEnabled;
      bool dailyOutfit = enabled;
      bool orderStatus = enabled;
      bool trendAlerts = false;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Preferences',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 22,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: const Text('Daily Outfit Suggestion'),
                    subtitle: const Text(
                      'Receive a fresh AI look every morning',
                    ),
                    value: dailyOutfit,
                    onChanged: (v) => setSheetState(() => dailyOutfit = v),
                  ),
                  SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: const Text('Order & Shipping Updates'),
                    subtitle: const Text(
                      'Get notified when orders change status',
                    ),
                    value: orderStatus,
                    onChanged: (v) => setSheetState(() => orderStatus = v),
                  ),
                  SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: const Text('New Trend Alerts'),
                    subtitle: const Text(
                      'Be notified when seasonal trends launch',
                    ),
                    value: trendAlerts,
                    onChanged: (v) => setSheetState(() => trendAlerts = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final profile = ref
                            .read(dashboardViewModelProvider)
                            .profileData;
                        await ref
                            .read(dashboardViewModelProvider.notifier)
                            .updateProfileData(
                              profile.copyWith(
                                notificationsEnabled:
                                    dailyOutfit || orderStatus || trendAlerts,
                              ),
                              persistSilhouette: false,
                            );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        'Save Notification Settings',
                        style: TextStyle(fontFamily: AppFonts.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showHelpSupportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help & Support',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(
                  Icons.question_answer_outlined,
                  color: AppColors.primary,
                ),
                title: Text('How does AI Stylist work?'),
                subtitle: Text(
                  'FashioMe matches your silhouette, color palette, and wardrobe items using advanced AI algorithms.',
                ),
              ),
              const ListTile(
                leading: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                ),
                title: Text('How do I track my order?'),
                subtitle: Text(
                  'Go to My Orders under Profile to see live order details and receipt status.',
                ),
              ),
              const ListTile(
                leading: Icon(Icons.mail_outline, color: AppColors.primary),
                title: Text('Need more assistance?'),
                subtitle: Text('Contact us at support@fashiome.com'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontFamily: AppFonts.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
