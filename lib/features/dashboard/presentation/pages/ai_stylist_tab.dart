import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/services/sensors/sensor_settings.dart';
import 'package:fashio_me/core/services/sensors/shake_detector_service.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_chat_bubble.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_featured_recommendation_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_filter_chip.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_primary_luxury_button.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_section_title.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_source_card.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_providers.dart';

class AiStylistTab extends ConsumerStatefulWidget {
  const AiStylistTab({super.key, 
    required this.state,
    required this.selectedEvent,
    required this.selectedSource,
    required this.selectedWeather,
    required this.selectedVibe,
    required this.events,
    required this.onEventChanged,
    required this.onSourceChanged,
    required this.onWeatherChanged,
    required this.onVibeChanged,
  });

  final DashboardState state;
  final String selectedEvent;
  final String selectedSource;
  final String selectedWeather;
  final String selectedVibe;
  final List<(String, IconData)> events;
  final ValueChanged<String> onEventChanged;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onVibeChanged;

  @override
  ConsumerState<AiStylistTab> createState() => _AiStylistTabState();
}

class _AiStylistTabState extends ConsumerState<AiStylistTab> {
  final TextEditingController _messageController = TextEditingController();

  // ── Shake-to-refresh ──────────────────────────────────────────────────────
  late final ShakeDetectorService _shakeService;
  StreamSubscription<void>? _shakeSubscription;
  ProviderSubscription<bool>? _sensorToggleSubscription;
  bool _isRegeneratingFromShake = false;

  @override
  void initState() {
    super.initState();
    _shakeService = ref.read(shakeDetectorServiceProvider);
    // Respect the user's sensor-gestures preference (Profile → Settings).
    _setSensorEnabled(ref.read(sensorGesturesEnabledProvider));
    _sensorToggleSubscription = ref.listenManual<bool>(
      sensorGesturesEnabledProvider,
      (previous, enabled) {
        if (previous == enabled) return;
        _setSensorEnabled(enabled);
      },
    );
  }

  void _setSensorEnabled(bool enabled) {
    if (enabled) {
      _startShakeListener();
    } else {
      _stopShakeListener();
    }
  }

  void _startShakeListener() {
    if (_shakeSubscription != null) return;
    _shakeService.start();
    _shakeSubscription = _shakeService.shakeStream.listen((_) {
      _onShakeDetected();
    });
  }

  void _stopShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
    _shakeService.stop();
  }

  Future<void> _onShakeDetected() async {
    // Prevent overlapping calls while a generation is in flight.
    if (_isRegeneratingFromShake) return;
    if (widget.state.isUploading) return;
    // Do not regenerate if another page is on top (e.g. CartPage, ShopDetailPage).
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _isRegeneratingFromShake = true;
    try {
      if (!mounted) return;
      // Clear the chat history when the user shakes so the fresh outfit
      // recommendation starts a clean conversation.
      ref.read(dashboardViewModelProvider.notifier).clearChatMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text('Shake detected — generating a new outfit! ✦'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await ref.read(dashboardViewModelProvider.notifier).generateHomeRecommendation(
        occasion:
            '${widget.selectedEvent} in ${widget.selectedWeather} with a ${widget.selectedVibe} vibe',
        syncCurrentRecommendation: true,
        source: widget.selectedSource,
      );
    } finally {
      _isRegeneratingFromShake = false;
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopShakeListener();
    _sensorToggleSubscription?.close();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    _messageController.clear();
    await ref
        .read(dashboardViewModelProvider.notifier)
        .sendChatMessage(message, source: widget.selectedSource);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final visibleMessages = state.chatMessages.length > 6
        ? state.chatMessages.sublist(state.chatMessages.length - 6)
        : state.chatMessages;
    final quickPrompts = [
      'What should I wear for ${widget.selectedEvent}?',
      'Suggest colors for my skin tone',
      'Which hairstyle fits this look?',
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Build a look around your occasion, mood, and wardrobe.',
          style: TextStyle(color: DashboardPalette.mutedText, fontSize: 13),
        ),
        const SizedBox(height: 20),
        const DashboardSectionTitle(title: 'Select Occasion'),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = widget.events[index];
              return DashboardFilterChip(
                label: item.$1,
                selected: widget.selectedEvent == item.$1,
                onTap: () => widget.onEventChanged(item.$1),
              );
            },
          ),
        ),
        if (state.uploadMessage != null && state.uploadMessage!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: state.uploadSucceeded
                  ? DashboardPalette.cardAlt
                  : const Color(0xFFFFE9E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: state.uploadSucceeded
                    ? DashboardPalette.outline
                    : AppColors.error,
              ),
            ),
            child: Text(
              state.uploadMessage!,
              style: TextStyle(
                color: state.uploadSucceeded
                    ? DashboardPalette.mutedText
                    : AppColors.error,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const DashboardSectionTitle(title: 'Customize Your Look'),
        const SizedBox(height: 12),
        const Text(
          'Weather / Season',
          style: TextStyle(color: DashboardPalette.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                    'Summer / Hot',
                    'Winter / Cold',
                    'Spring / Mild',
                    'Autumn / Breezy',
                  ]
                  .map(
                    (item) => DashboardFilterChip(
                      label: item,
                      selected: widget.selectedWeather == item,
                      onTap: () => widget.onWeatherChanged(item),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 14),
        const Text(
          'Vibe / Aesthetic',
          style: TextStyle(color: DashboardPalette.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                    'Minimalist',
                    'Maximalist',
                    'Streetwear',
                    'Glam',
                    'Chic',
                    'Edgy',
                    'Boho',
                    'Vintage',
                    'Y2K',
                  ]
                  .map(
                    (item) => DashboardFilterChip(
                      label: item,
                      selected: widget.selectedVibe == item,
                      onTap: () => widget.onVibeChanged(item),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: DashboardSourceCard(
            label: 'Generate New Inspiration',
            icon: Icons.auto_awesome_outlined,
            selected: false,
            onTap: () => widget.onSourceChanged('New Inspiration'),
          ),
        ),
        const SizedBox(height: 14),
        DashboardPrimaryLuxuryButton(
          label: state.isUploading
              ? state.aiProcessingMessage
              : 'Generate Outfit  ✦',
          onTap: state.isUploading
              ? null
              : () async {
                  await notifier.generateHomeRecommendation(
                    occasion:
                        '${widget.selectedEvent} in ${widget.selectedWeather} with a ${widget.selectedVibe} vibe',
                    syncCurrentRecommendation: true,
                    source: widget.selectedSource,
                  );
                },
        ),
        if (ref.watch(sensorGesturesEnabledProvider))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.vibration, size: 13, color: DashboardPalette.mutedText),
                SizedBox(width: 4),
                Text(
                  'Shake your phone to generate a new outfit',
                  style: TextStyle(
                    color: DashboardPalette.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        DashboardFeaturedRecommendationCard(
          item: state.currentRecommendation,
          isLoading: state.isUploading,
          primaryLabel: 'Save to Wardrobe',
          onAddProduct: (product) async {
            final added = await ref
                .read(shopViewModelProvider.notifier)
                .addToBagById(product.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  added
                      ? '${product.name} added to your bag.'
                      : 'Could not add ${product.name} to your bag.',
                ),
              ),
            );
          },
          onPrimaryTap: () async {
            await notifier.saveCurrentRecommendation();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Look saved to your wardrobe.')),
            );
          },
        ),
        const SizedBox(height: 24),
        DashboardSectionTitle(
          title: 'AI Assistant',
          actionLabel: state.chatMessages.isNotEmpty ? 'Clear Chat' : null,
          onAction: state.chatMessages.isNotEmpty
              ? () => ref.read(dashboardViewModelProvider.notifier).clearChatMessages()
              : null,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickPrompts
              .map(
                (prompt) => ActionChip(
                  backgroundColor: DashboardPalette.cardAlt,
                  side: const BorderSide(color: DashboardPalette.outline),
                  label: Text(
                    prompt,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => notifier.sendChatMessage(
                    prompt,
                    source: widget.selectedSource,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        DashboardLuxuryCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ask for outfits, colors, styling, or hairstyle advice.',
                style: TextStyle(
                  color: DashboardPalette.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ...visibleMessages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DashboardChatBubble(message: message),
                ),
              ),
              if (state.isChatTyping)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: DashboardPalette.cardAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'AI stylist is typing...',
                    style: TextStyle(
                      color: DashboardPalette.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitMessage(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask your AI stylist...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: DashboardPalette.cardAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: DashboardPalette.outline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: DashboardPalette.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: DashboardPalette.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: state.isChatTyping ? null : _submitMessage,
                      child: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
