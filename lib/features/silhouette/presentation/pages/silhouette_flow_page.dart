import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/utils/snackbar_utils.dart';
import 'package:fashio_me/core/widgets/selected_image.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fashio_me/features/silhouette/presentation/providers/silhouette_flow_providers.dart';
import 'package:fashio_me/features/silhouette/presentation/state/silhouette_flow_state.dart';

class SilhouetteFlowPage extends ConsumerWidget {
  const SilhouetteFlowPage({super.key});

  static const _skinToneCards = [
    (
      key: 'fair',
      title: 'Tone 01',
      label: 'Fair',
      gradient: [Color(0xFFEFE1D3), Color(0xFFD9C3B3)],
    ),
    (
      key: 'olive',
      title: 'Tone 02',
      label: 'Olive',
      gradient: [Color(0xFFE2C58F), Color(0xFF8C5A32)],
    ),
    (
      key: 'deep',
      title: 'Tone 03',
      label: 'Deep',
      gradient: [Color(0xFFB57646), Color(0xFF5F351E)],
    ),
  ];

  static const _shadeOptions = [
    ('fair', Color(0xFFEBDCCB)),
    ('light', Color(0xFFE9C99D)),
    ('warm', Color(0xFFD0A16C)),
    ('olive', Color(0xFFB57941)),
    ('deep', Color(0xFF6D4428)),
  ];

  static const _faceShapes = [
    ('oval', 'OVAL'),
    ('square', 'SQUARE'),
    ('round', 'ROUND'),
    ('heart', 'HEART'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(silhouetteFlowViewModelProvider);
    final notifier = ref.read(silhouetteFlowViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: const Text(
          'FashioMe',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.help_outline, color: AppColors.primaryDark),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(step: state.currentStep),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (state.currentStep) {
                  0 => _StepOneView(
                    key: const ValueKey('step-1'),
                    state: state,
                    onGenderSelected: notifier.selectGender,
                    onHeightChanged: notifier.setHeight,
                    onWeightChanged: notifier.setWeight,
                    onBuildSelected: notifier.selectBuildType,
                    onBodyShapeSelected: notifier.selectBodyShape,
                  ),
                  1 => _StepTwoView(
                    key: const ValueKey('step-2'),
                    state: state,
                    onSkinToneSelected: notifier.selectSkinTone,
                  ),
                  _ => _StepThreeView(
                    key: const ValueKey('step-3'),
                    state: state,
                    onFaceShapeSelected: notifier.selectFaceShape,
                    onUploadPortrait: (source) async {
                      final picked = await notifier.pickPortrait(source);
                      if (!context.mounted) return;
                      if (!picked) {
                        showAppSnackBar(
                          context,
                          'Unable to upload your portrait right now.',
                          isError: true,
                        );
                      }
                    },
                    onRemovePortrait: notifier.removePortrait,
                  ),
                },
              ),
            ),
            _BottomActionBar(
              state: state,
              onBack: () async {
                if (state.currentStep > 0) {
                  notifier.previousStep();
                  return;
                }

                final popped = await Navigator.of(context).maybePop();
                if (!popped && context.mounted) {
                  showAppSnackBar(
                    context,
                    'Complete your silhouette setup to continue.',
                  );
                }
              },
              onPrimaryPressed: () async {
                if (state.currentStep == 0) {
                  if (!state.canFinishStepOne) {
                    showAppSnackBar(
                      context,
                      'Fill in your body profile details first.',
                      isError: true,
                    );
                    return;
                  }
                  notifier.nextStep();
                  return;
                }

                if (state.currentStep == 1) {
                  if (!state.canFinishStepTwo) {
                    showAppSnackBar(
                      context,
                      'Choose a skin tone before continuing.',
                      isError: true,
                    );
                    return;
                  }
                  notifier.nextStep();
                  return;
                }

                if (!state.canFinishStepThree) {
                  showAppSnackBar(
                    context,
                    'Select a face shape or upload a portrait first.',
                    isError: true,
                  );
                  return;
                }

                final result = await notifier.saveProfile();
                if (!context.mounted) return;

                if (result == -1) {
                  showAppSnackBar(
                    context,
                    'Unable to save your silhouette profile. Please try again.',
                    isError: true,
                  );
                  return;
                }

                if (result == 0) {
                  // Saved locally; warn user that backend sync failed
                  showAppSnackBar(
                    context,
                    'Profile saved on device. It will sync when you reconnect.',
                  );
                }

                final isLoggedInResult = await ref.read(
                  isLoggedInUsecaseProvider,
                )();
                if (!context.mounted) return;
                final isLoggedIn = isLoggedInResult.fold(
                  (_) => false,
                  (value) => value,
                );
                if (isLoggedIn) {
                  AppRoutes.pushAndRemoveUntil(context, const DashboardPage());
                } else {
                  AppRoutes.pushAndRemoveUntil(context, const LoginPage());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= step;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Text(
            step == 0
                ? 'Curate Your Silhouette'
                : step == 1
                ? 'Choose your skin tone\nfor perfect color matching'
                : 'Discover your\nperfect fit',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step == 0
                ? 'Step 1 of 3: Personalized fit details.'
                : step == 1
                ? 'Our AI uses this to curate high-end fashion suggestions that complement your natural radiance.'
                : 'Step 3 of 3: Select your face shape or upload a portrait for AI-powered personalization.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepOneView extends StatelessWidget {
  const _StepOneView({
    super.key,
    required this.state,
    required this.onGenderSelected,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onBuildSelected,
    required this.onBodyShapeSelected,
  });

  final SilhouetteFlowState state;
  final ValueChanged<String> onGenderSelected;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onBuildSelected;
  final ValueChanged<String> onBodyShapeSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        _SectionLabel(title: 'SELECT GENDER'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                label: 'MALE',
                icon: Icons.male,
                selected: state.gender == 'male',
                onTap: () => onGenderSelected('male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                label: 'FEMALE',
                icon: Icons.female,
                selected: state.gender == 'female',
                onTap: () => onGenderSelected('female'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                label: 'NB',
                icon: Icons.transgender,
                selected: state.gender == 'nb',
                onTap: () => onGenderSelected('nb'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const _SectionLabel(title: 'HEIGHT'),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${state.heightCm}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
                  ),
                  TextSpan(
                    text: ' cm',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.divider,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          child: Slider(
            min: 140,
            max: 210,
            value: state.heightCm.toDouble().clamp(140, 210).toDouble(),
            onChanged: onHeightChanged,
          ),
        ),
        Row(
          children: [
            Text(
              '140cm',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
            ),
            const Spacer(),
            Text(
              '210cm',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionLabel(title: 'BODY TYPE & WEIGHT'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT WEIGHT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${state.weightKg}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 28, color: AppColors.primary),
                    ),
                    TextSpan(
                      text: ' Kilograms',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: AppColors.divider,
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  min: 40,
                  max: 120,
                  value: state.weightKg.toDouble().clamp(40, 120).toDouble(),
                  onChanged: onWeightChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ChoicePill(
              label: 'SLIM',
              icon: Icons.accessibility_new,
              selected: state.buildType == 'slim',
              onTap: () => onBuildSelected('slim'),
            ),
            _ChoicePill(
              label: 'ATHLETIC',
              icon: Icons.fitness_center,
              selected: state.buildType == 'athletic',
              onTap: () => onBuildSelected('athletic'),
            ),
            _ChoicePill(
              label: 'RECTANGLE',
              icon: Icons.crop_square_outlined,
              selected: state.bodyShape == 'rectangle',
              onTap: () => onBodyShapeSelected('rectangle'),
            ),
            _ChoicePill(
              label: 'INV TRIANGLE',
              icon: Icons.change_history_outlined,
              selected: state.bodyShape == 'inverted_triangle',
              onTap: () => onBodyShapeSelected('inverted_triangle'),
            ),
            _ChoicePill(
              label: 'PEAR',
              icon: Icons.water_drop_outlined,
              selected: state.bodyShape == 'pear',
              onTap: () => onBodyShapeSelected('pear'),
            ),
            _ChoicePill(
              label: 'CURVY',
              icon: Icons.hourglass_bottom,
              selected: state.bodyShape == 'curvy',
              onTap: () => onBodyShapeSelected('curvy'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionLabel(title: 'STYLE INSPIRATION'),
        const SizedBox(height: 10),
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 18,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 120,
                bottom: 16,
                child: Text(
                  'We curate based on your unique proportions.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepTwoView extends StatelessWidget {
  const _StepTwoView({
    super.key,
    required this.state,
    required this.onSkinToneSelected,
  });

  final SilhouetteFlowState state;
  final ValueChanged<String> onSkinToneSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final tone = SilhouetteFlowPage._skinToneCards[index];
              final selected = state.skinTone == tone.key;
              return GestureDetector(
                onTap: () => onSkinToneSelected(tone.key),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                    gradient: LinearGradient(
                      colors: tone.gradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tone.title,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tone.label,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemCount: SilhouetteFlowPage._skinToneCards.length,
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const _SectionLabel(title: 'ALL SHADES'),
            const Spacer(),
            Text(
              'GUIDE',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: SilhouetteFlowPage._shadeOptions.map((shade) {
            final isSelected = state.skinTone == shade.$1;
            return GestureDetector(
              onTap: () => onSkinToneSelected(shade.$1),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shade.$2,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepThreeView extends StatelessWidget {
  const _StepThreeView({
    super.key,
    required this.state,
    required this.onFaceShapeSelected,
    required this.onUploadPortrait,
    required this.onRemovePortrait,
  });

  final SilhouetteFlowState state;
  final ValueChanged<String> onFaceShapeSelected;
  final Future<void> Function(ImageSource source) onUploadPortrait;
  final VoidCallback onRemovePortrait;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.divider,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              if (state.portraitPath == null) ...[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.cardBackground,
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primaryDark.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Upload Your Portrait',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI analysis for best results',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: buildSelectedImage(
                      state.portraitPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.background,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Portrait ready for analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRemovePortrait,
                  child: const Text('Remove portrait'),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isSaving
                          ? null
                          : () {
                              onUploadPortrait(ImageSource.gallery);
                            },
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isSaving
                          ? null
                          : () {
                              onUploadPortrait(ImageSource.camera);
                            },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(
                        state.portraitPath == null ? 'Camera' : 'Retake',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Manual Selection',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: SilhouetteFlowPage._faceShapes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.05,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final item = SilhouetteFlowPage._faceShapes[index];
            final selected = state.faceShape == item.$1;
            return GestureDetector(
              onTap: () => onFaceShapeSelected(item.$1),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.cardBackground,
                              AppColors.primaryLight,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          item.$1 == 'oval'
                              ? Icons.radio_button_unchecked
                              : item.$1 == 'square'
                              ? Icons.crop_square_rounded
                              : item.$1 == 'round'
                              ? Icons.circle_outlined
                              : Icons.favorite_border,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.state,
    required this.onBack,
    required this.onPrimaryPressed,
  });

  final SilhouetteFlowState state;
  final Future<void> Function() onBack;
  final Future<void> Function() onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = state.currentStep == 0
        ? 'CONTINUE'
        : state.currentStep == 1
        ? 'CONFIRM SELECTION'
        : 'ANALYZE MY STYLE';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                onBack();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('BACK'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.isSaving
                  ? null
                  : () {
                      onPrimaryPressed();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.accent,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.primaryDark),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 98,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.primaryDark,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
