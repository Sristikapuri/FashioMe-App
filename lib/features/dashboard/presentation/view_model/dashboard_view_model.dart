import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/core/services/media/image_picker_service.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/dashboard_home_usecases.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/read_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/persist_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/upload_item_photo_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/generate_recommendation_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/get_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/save_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/style_archive/domain/week_key_utils.dart';
import 'package:fashio_me/features/style_archive/domain/usecases/save_style_archive_entry_usecase.dart';

class DashboardViewModel extends Notifier<DashboardState> {
  late final GetCurrentUserUsecase _getCurrentUserUsecase;
  late final GetSilhouetteProfileUsecase _getSilhouetteProfileUsecase;
  late final SaveSilhouetteProfileUsecase _saveSilhouetteProfileUsecase;
  late final ReadDashboardStateUsecase _readDashboardStateUsecase;
  late final PersistDashboardStateUsecase _persistDashboardStateUsecase;
  late final UploadItemPhotoUsecase _uploadItemPhotoUsecase;
  late final DashboardHomeUsecases _dashboardHome;
  late final GenerateRecommendationUsecase _generateRecommendationUsecase;
  late final SaveStyleArchiveEntryUsecase _saveStyleArchiveEntryUsecase;
  late final ImagePickerService _imagePicker;
  final Random _random = Random();
  AuthEntity? _currentUser;
  bool _usedPersistedProfileData = false;

  @override
  DashboardState build() {
    _imagePicker = ref.read(imagePickerServiceProvider);
    _getCurrentUserUsecase = ref.read(getCurrentUserUsecaseProvider);
    _getSilhouetteProfileUsecase = ref.read(
      getSilhouetteProfileUsecaseProvider,
    );
    _saveSilhouetteProfileUsecase = ref.read(
      saveSilhouetteProfileUsecaseProvider,
    );
    _readDashboardStateUsecase = ref.read(readDashboardStateUsecaseProvider);
    _persistDashboardStateUsecase = ref.read(
      persistDashboardStateUsecaseProvider,
    );
    _uploadItemPhotoUsecase = ref.read(uploadItemPhotoUsecaseProvider);
    _dashboardHome = ref.read(dashboardHomeUsecasesProvider);
    _generateRecommendationUsecase = ref.read(
      generateRecommendationUsecaseProvider,
    );
    _saveStyleArchiveEntryUsecase = ref.read(
      saveStyleArchiveEntryUsecaseProvider,
    );

    final initial = _buildStateFromCache(const <String, dynamic>{});
    Future.microtask(_initialize);
    return initial;
  }

  Future<void> _initialize() async {
    final currentUserResult = await _getCurrentUserUsecase();
    _currentUser = currentUserResult.fold((_) => null, (user) => user);
    final cachedResult = await _readDashboardStateUsecase();
    cachedResult.fold((_) {}, (cachedData) {
      if (cachedData.isNotEmpty) {
        state = _buildStateFromCache(cachedData);
      }
    });

    // Always refresh profile data from current session user
    if (_currentUser != null) {
      await _refreshProfileFromSession();
    }

    await _hydrateFromSilhouetteIfNeeded();
    await _loadRemoteWardrobeItems();
    await _loadRemoteDashboardContent();
  }

  Future<void> _loadRemoteDashboardContent() async {
    try {
      const homeOccasions = ['Weekend', 'Office / Work', 'Party / Club Night'];
      final recommendations = await Future.wait(
        homeOccasions.map(
          (occasion) => _dashboardHome.generateOutfit(
            occasion: occasion,
            profileData: state.profileData,
            preferenceScores: state.stylePreferenceScores,
          ),
        ),
      );
      final recommendation = recommendations.first;
      final seenImages = <String>{};
      final distinctRecommendations = recommendations.where((item) {
        final image = item.imageUrl.trim();
        if (image.isEmpty || seenImages.add(image)) return true;
        return false;
      }).toList(growable: false);
      final trends = await _dashboardHome.fetchTrends();
      final refreshedList = [
        ...distinctRecommendations,
        ...state.homeRecommendations.where(
          (item) => !distinctRecommendations.any((fresh) => fresh.id == item.id),
        ),
      ].take(6).toList();

      state = state.copyWith(
        aiStyleOfDay: recommendation,
        currentRecommendation: recommendation,
        homeRecommendations: refreshedList,
        discoverItems: trends.isEmpty ? state.discoverItems : trends,
        uploadMessage: 'Dashboard synced with backend.',
        uploadSucceeded: true,
      );
      await _persistState();
    } catch (_) {
      // Keep locally generated content when backend is unavailable.
    }
  }

  Future<void> _loadRemoteWardrobeItems() async {
    try {
      final remoteItems = await _dashboardHome.fetchWardrobe();
      if (remoteItems.isEmpty) {
        return;
      }

      state = state.copyWith(wardrobeItems: remoteItems);
      await _persistState();
    } catch (_) {
      // Keep local wardrobe if backend sync is unavailable.
    }
  }

  Future<void> _refreshProfileFromSession() async {
    if (_currentUser == null) {
      return;
    }

    final fullName = [
      _currentUser!.firstName,
      _currentUser!.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();

    final updatedProfile = state.profileData.copyWith(
      displayName: fullName.isEmpty ? 'User' : fullName,
      email: _currentUser!.email,
      profileImage: _currentUser!.profileImage ?? '',
    );

    state = state.copyWith(profileData: updatedProfile);
    await _persistState();
  }

  Future<void> refreshFromSession() async {
    final currentUserResult = await _getCurrentUserUsecase();
    _currentUser = currentUserResult.fold((_) => null, (user) => user);
    await _refreshProfileFromSession();
  }

  Future<void> clearCacheAndRefresh() async {
    await _persistDashboardStateUsecase(
      PersistDashboardStateParams(payload: const {}),
    );

    final currentUserResult = await _getCurrentUserUsecase();
    _currentUser = currentUserResult.fold((_) => null, (user) => user);
    if (_currentUser != null) {
      await _refreshProfileFromSession();
    }
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  Future<DashboardRecommendation?> generateRecommendation({
    required String occasion,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
  }) => _generateRecommendationUsecase(
    occasion: occasion,
    profileData: profileData,
    preferenceScores: preferenceScores,
  );

  bool _isLiveRecommendation(DashboardRecommendation recommendation) {
    return recommendation.imageUrl.startsWith('/uploads/') ||
        recommendation.imageUrl.startsWith('http://') ||
        recommendation.imageUrl.startsWith('https://');
  }

  DashboardState _buildStateFromCache(Map<String, dynamic> cachedData) {
    _usedPersistedProfileData =
        cachedData['profileData'] is Map &&
        (cachedData['profileData'] as Map).isNotEmpty;
    final profileData = _buildProfileData(
      rawProfile: cachedData['profileData'] as Map<String, dynamic>?,
      silhouette: null,
      currentUser: _currentUser,
    );
    final preferenceScores = Map<String, int>.from(
      cachedData['stylePreferenceScores'] as Map<String, dynamic>? ?? const {},
    );

    // Discover content is hydrated from the backend's AI-generated trends.
    final discoverItems = <DiscoverEntry>[];
    final cachedRecommendations =
        (cachedData['homeRecommendations'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => DashboardRecommendation.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where(_isLiveRecommendation)
            .toList(growable: false);
    final homeRecommendations = cachedRecommendations.isEmpty
        ? [DashboardRecommendation.empty()]
        : cachedRecommendations;
    final cachedAiStyle = cachedData['aiStyleOfDay'] is Map
        ? DashboardRecommendation.fromJson(
            Map<String, dynamic>.from(cachedData['aiStyleOfDay'] as Map),
          )
        : null;
    final aiStyleOfDay =
        cachedAiStyle != null && _isLiveRecommendation(cachedAiStyle)
        ? cachedAiStyle
        : homeRecommendations.first;
    final cachedCurrentRecommendation =
        cachedData['currentRecommendation'] is Map
        ? DashboardRecommendation.fromJson(
            Map<String, dynamic>.from(
              cachedData['currentRecommendation'] as Map,
            ),
          )
        : null;
    final currentRecommendation =
        cachedCurrentRecommendation != null &&
            _isLiveRecommendation(cachedCurrentRecommendation)
        ? cachedCurrentRecommendation
        : aiStyleOfDay;
    final wardrobeItems =
        (cachedData['wardrobeItems'] as List<dynamic>? ?? const [])
            .map(
              (item) => WardrobeEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    final chatMessages =
        (cachedData['chatMessages'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();

    return DashboardState(
      aiProcessingMessage: 'Ready to craft a new recommendation.',
      aiStyleOfDay: aiStyleOfDay,
      currentRecommendation: currentRecommendation,
      homeRecommendations: homeRecommendations,
      wardrobeItems: wardrobeItems,
      discoverItems: discoverItems,
      wardrobeFilter: (cachedData['wardrobeFilter'] ?? 'All').toString(),
      discoverFilter: (cachedData['discoverFilter'] ?? 'Trending').toString(),
      searchQuery: (cachedData['searchQuery'] ?? '').toString(),
      preferenceScore: cachedData['preferenceScore'] as int? ?? 0,
      stylePreferenceScores: preferenceScores,
      chatMessages: chatMessages.isEmpty
          ? [
              ChatMessage(
                id: _id('chat'),
                text:
                    'Hi ${profileData.displayName.split(' ').first}, ask for a look by mood, occasion, or weather and I will mock a tailored recommendation.',
                isUser: false,
              ),
            ]
          : chatMessages,
      profileData: profileData,
    );
  }

  Future<void> _hydrateFromSilhouetteIfNeeded() async {
    if (_usedPersistedProfileData) {
      return;
    }

    final result = await _getSilhouetteProfileUsecase();
    await result.fold((_) async {}, (silhouette) async {
      if (silhouette == null) {
        return;
      }

      final profileData = _buildProfileData(
        rawProfile: null,
        silhouette: silhouette,
        currentUser: _currentUser,
      );

      await updateProfileData(profileData, persistSilhouette: false);
    });
  }

  Future<void> _persistState() async {
    final payload = {
      'profileData': state.profileData.toJson(),
      'wardrobeItems': state.wardrobeItems
          .map((item) => item.toJson())
          .toList(),
      'preferenceScore': state.preferenceScore,
      'stylePreferenceScores': state.stylePreferenceScores,
      'aiStyleOfDay': state.aiStyleOfDay.toJson(),
      'currentRecommendation': state.currentRecommendation.toJson(),
      'homeRecommendations': state.homeRecommendations
          .map((item) => item.toJson())
          .toList(),
      'chatMessages': state.chatMessages.map((item) => item.toJson()).toList(),
      'wardrobeFilter': state.wardrobeFilter,
      'discoverFilter': state.discoverFilter,
      'searchQuery': state.searchQuery,
    };
    await _persistDashboardStateUsecase(
      PersistDashboardStateParams(payload: payload),
    );
  }

  DashboardProfileData _buildProfileData({
    required Map<String, dynamic>? rawProfile,
    required SilhouetteProfile? silhouette,
    required AuthEntity? currentUser,
  }) {
    final fullName = [
      currentUser?.firstName ?? '',
      currentUser?.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();

    final skinTone = silhouette?.toneLabel.trim().isNotEmpty == true
        ? silhouette!.toneLabel
        : (rawProfile != null
              ? (rawProfile['skinTone']?.toString() ?? 'Warm')
              : 'Warm');
    final bodyType = silhouette?.buildType.trim().isNotEmpty == true
        ? _toTitleCase(silhouette!.buildType)
        : (rawProfile != null
              ? (rawProfile['bodyType']?.toString() ?? 'Balanced')
              : 'Balanced');
    final faceShape =
        silhouette?.faceShapeLabel ??
        (rawProfile != null
            ? (rawProfile['faceShape']?.toString() ?? 'Oval')
            : 'Oval');
    final preferences = rawProfile != null
        ? List<String>.from(
            rawProfile['stylePreferences'] ??
                const ['Minimal', 'Neutral', 'Tailored'],
          )
        : _defaultPreferencesForTone(skinTone);
    final styleMood = rawProfile != null
        ? (rawProfile['styleMood']?.toString() ?? _defaultMoodForTone(skinTone))
        : _defaultMoodForTone(skinTone);
    final heightCm =
        silhouette?.heightCm ??
        (rawProfile?['heightCm'] as num?)?.toInt() ??
        (rawProfile?['height'] as num?)?.toInt() ??
        int.tryParse(
          (rawProfile?['heightCm'] ?? rawProfile?['height'] ?? '172')
              .toString(),
        ) ??
        172;
    final weightKg =
        silhouette?.weightKg ??
        (rawProfile?['weightKg'] as num?)?.toInt() ??
        (rawProfile?['weight'] as num?)?.toInt() ??
        int.tryParse(
          (rawProfile?['weightKg'] ?? rawProfile?['weight'] ?? '64').toString(),
        ) ??
        64;

    return DashboardProfileData(
      displayName: fullName.isEmpty ? 'User' : fullName,
      email: currentUser?.email ?? (rawProfile?['email']?.toString() ?? ''),
      gender: currentUser?.gender ?? (rawProfile?['gender']?.toString() ?? ''),
      profileImage:
          currentUser?.profileImage ??
          (rawProfile?['profileImage']?.toString() ?? ''),
      heightCm: heightCm,
      weightKg: weightKg,
      styleMood: styleMood,
      stylePreferences: preferences,
      skinTone: skinTone,
      bodyType: bodyType,
      faceShape: faceShape,
      themePreference: rawProfile?['themePreference']?.toString() ?? 'System',
      notificationsEnabled:
          rawProfile?['notificationsEnabled'] as bool? ?? true,
      language: rawProfile?['language']?.toString() ?? 'English',
    );
  }

  Future<bool> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pick(
        useCamera: source == ImageSource.camera,
      );

      if (pickedFile == null) {
        state = state.copyWith(
          uploadMessage: 'Image selection cancelled.',
          uploadSucceeded: false,
        );
        return false;
      }

      state = state.copyWith(
        selectedImagePath: pickedFile.path,
        clearUploadedAssetName: true,
        uploadProgress: 0,
        uploadSucceeded: false,
        hasCompletedStyleAnalysis: false,
        uploadMessage: 'Image selected and ready for AI analysis.',
        aiProcessingMessage: 'Reference image ready.',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        uploadSucceeded: false,
        uploadMessage: 'Unable to open image picker on this device.',
      );
      return false;
    }
  }

  void clearSelectedImage() {
    state = state.copyWith(
      clearSelectedImage: true,
      clearUploadedAssetName: true,
      uploadProgress: 0,
      uploadSucceeded: false,
      hasCompletedStyleAnalysis: false,
      clearUploadMessage: true,
    );
  }

  String _extractMessage(dynamic data, String fallbackMessage) {
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['message'],
        data['responseMessage'],
        data['statusMessage'],
      ];

      for (final candidate in candidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }

      final responseData = data['responseData'];
      if (responseData is Map<String, dynamic>) {
        final nestedMessage = responseData['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }
    }

    return fallbackMessage;
  }

  String? _extractAssetName(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final directData = data['data'];
    if (directData is String && directData.trim().isNotEmpty) {
      return directData.trim();
    }

    final candidates = [
      data['fileUrl'],
      data['relativeFileUrl'],
      data['filename'],
      data['fileName'],
      data['assetName'],
      data['imageName'],
      data['videoName'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    final responseData = data['responseData'];
    if (responseData is Map<String, dynamic>) {
      final nestedCandidates = [
        responseData['fileUrl'],
        responseData['relativeFileUrl'],
        responseData['filename'],
        responseData['data'],
        responseData['fileName'],
        responseData['assetName'],
        responseData['imageName'],
        responseData['videoName'],
      ];

      for (final candidate in nestedCandidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }

    return null;
  }

  Future<DashboardRecommendation> generateHomeRecommendation({
    String? occasion,
    bool syncCurrentRecommendation = false,
    String source = 'My Wardrobe',
  }) async {
    if (state.isUploading) {
      return state.aiStyleOfDay;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.2,
      aiProcessingMessage: 'Refreshing your AI style dashboard...',
      uploadMessage: 'Refreshing today\'s recommendation...',
    );

    final selectedOccasion = occasion ?? state.aiStyleOfDay.occasion;
    final occasionList = _generateOccasionRecommendationsList(
      selectedOccasion,
      state.profileData,
      state.stylePreferenceScores,
    );

    // Pick a fresh, non-duplicate recommendation different from the currently shown one
    final currentId = state.currentRecommendation.id;
    final unusedList = occasionList.where((item) => item.id != currentId).toList();
    final freshRecommendation = unusedList.isNotEmpty
        ? unusedList[_random.nextInt(unusedList.length)]
        : occasionList[_random.nextInt(occasionList.length)];

    final recommendation = await _generateRecommendationFromBackend(
      occasion: selectedOccasion,
      source: source,
      fallback: () => freshRecommendation,
    );

    final refreshedList = [
      recommendation,
      ...occasionList.where((item) => item.id != recommendation.id),
    ].take(6).toList();

    state = state.copyWith(
      isUploading: false,
      uploadProgress: 0,
      aiStyleOfDay: recommendation,
      currentRecommendation: syncCurrentRecommendation
          ? recommendation
          : state.currentRecommendation,
      homeRecommendations: refreshedList,
      uploadSucceeded: true,
      aiProcessingMessage: 'Style board updated for $selectedOccasion.',
      uploadMessage: 'Your $selectedOccasion style recommendations are ready.',
    );
    await _persistState();
    return recommendation;
  }

  Future<DashboardRecommendation> generateFreshHomeRecommendation({
    String source = 'My Wardrobe',
  }) async {
    final occasions = [
      'Wedding',
      'Office',
      'Party',
      'Travel',
      'Weekend',
      'Casual',
      'Date Night',
      'Festival',
      'Gala',
      'Street Style',
      'Beach',
      'Sangeet',
      'Black Tie',
      'Brunch',
    ];
    final currentOccasion = state.aiStyleOfDay.occasion;
    final availableOccasions = occasions
        .where((item) => item.toLowerCase() != currentOccasion.toLowerCase())
        .toList();
    final nextOccasion = availableOccasions.isEmpty
        ? occasions[_random.nextInt(occasions.length)]
        : availableOccasions[_random.nextInt(availableOccasions.length)];

    if (state.isUploading) {
      return state.aiStyleOfDay;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.2,
      aiProcessingMessage: 'Reading your profile and refreshing the look...',
      uploadMessage: 'Generating a personalized outfit...',
    );

    final recommendation = await _generateRecommendationFromBackend(
      occasion: nextOccasion,
      source: source,
      fallback: () => _generateRecommendation(
        occasion: nextOccasion,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        excludedCategory: state.aiStyleOfDay.category,
      ),
    );
    final refreshedList = [
      recommendation,
      ...state.homeRecommendations.where(
        (item) => item.id != recommendation.id,
      ),
    ].take(6).toList();

    state = state.copyWith(
      isUploading: false,
      uploadProgress: 0,
      aiStyleOfDay: recommendation,
      currentRecommendation: recommendation,
      homeRecommendations: refreshedList,
      uploadSucceeded: true,
      aiProcessingMessage: 'Fresh recommendation ready.',
      uploadMessage:
          'Generated a ${recommendation.category.toLowerCase()} ${recommendation.occasion.toLowerCase()} look for your ${state.profileData.styleMood.toLowerCase()} style.',
    );
    await _persistState();
    return recommendation;
  }

  void selectRecommendation(DashboardRecommendation recommendation) {
    state = state.copyWith(currentRecommendation: recommendation);
  }

  void setWardrobeFilter(String filter) {
    state = state.copyWith(wardrobeFilter: filter);
    _persistState();
  }

  void setDiscoverFilter(String filter) {
    state = state.copyWith(discoverFilter: filter);
    _persistState();
  }

  Future<void> searchDashboard(String query) async {
    final trimmed = query.trim();
    state = state.copyWith(searchQuery: trimmed);

    if (trimmed.isEmpty) {
      await _loadRemoteDashboardContent();
      await _persistState();
      return;
    }

    final lower = trimmed.toLowerCase();

    // 1. Check if search query matches an occasion (e.g. "wedding", "party", "formal", "casual", "sangeet", etc.)
    final knownOccasions = [
      'Wedding',
      'Sangeet',
      'Party',
      'Formal',
      'Office',
      'Casual',
      'Festival',
      'Date Night',
      'Travel',
      'Gala',
      'Street Style',
      'Beach',
      'Brunch',
      'Black Tie',
    ];

    final matchedOccasion = knownOccasions.firstWhere(
      (occ) => occ.toLowerCase() == lower || lower.contains(occ.toLowerCase()),
      orElse: () => '',
    );

    if (matchedOccasion.isNotEmpty) {
      final occasionList = _generateOccasionRecommendationsList(
        matchedOccasion,
        state.profileData,
        state.stylePreferenceScores,
      );
      final topRec = occasionList.first;

      state = state.copyWith(
        currentIndex: state.currentIndex == 4 ? 0 : state.currentIndex,
        aiStyleOfDay: topRec,
        currentRecommendation: topRec,
        homeRecommendations: occasionList,
        uploadMessage: 'Showing $matchedOccasion recommendations.',
        uploadSucceeded: true,
      );
      await _persistState();
      return;
    }

    // 2. Search remote backend
    try {
      final result = await _dashboardHome.search(
        query: trimmed,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
      );

      final recommendationPayload = result['recommendation'];
      DashboardRecommendation? recommendation;
      if (recommendationPayload is Map<String, dynamic>) {
        recommendation = DashboardRecommendation.fromJson(
          recommendationPayload,
        );
      } else if (recommendationPayload is Map) {
        recommendation = DashboardRecommendation.fromJson(
          Map<String, dynamic>.from(recommendationPayload),
        );
      }

      final discoverPayload = result['discoverItems'];
      final discoverItems = discoverPayload is List
          ? discoverPayload
                .whereType<Map>()
                .map(
                  (item) =>
                      DiscoverEntry.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : state.discoverItems;

      final wardrobePayload = result['wardrobeItems'];
      final wardrobeItems = wardrobePayload is List
          ? wardrobePayload
                .whereType<Map>()
                .map(
                  (item) =>
                      WardrobeEntry.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : state.wardrobeItems;

      // Stay on current tab (Home/Discover/Wardrobe) – NEVER jump to Profile (index 4)
      final targetIndex = state.currentIndex == 4 ? 3 : state.currentIndex;

      state = state.copyWith(
        currentIndex: targetIndex,
        discoverFilter: 'Trending',
        discoverItems: discoverItems.isEmpty
            ? state.discoverItems
            : discoverItems,
        wardrobeItems: wardrobeItems.isEmpty
            ? state.wardrobeItems
            : wardrobeItems,
        currentRecommendation: recommendation ?? state.currentRecommendation,
        aiStyleOfDay: recommendation ?? state.aiStyleOfDay,
        homeRecommendations: recommendation == null
            ? state.homeRecommendations
            : [
                recommendation,
                ...state.homeRecommendations.where(
                  (item) => item.id != recommendation!.id,
                ),
              ].take(6).toList(),
        uploadMessage: 'Search results loaded for "$trimmed".',
        uploadSucceeded: true,
      );
    } catch (_) {
      final localDiscover = state.discoverItems
          .where(
            (item) =>
                item.title.toLowerCase().contains(lower) ||
                item.category.toLowerCase().contains(lower) ||
                item.caption.toLowerCase().contains(lower),
          )
          .toList();
      final localWardrobe = state.wardrobeItems
          .where(
            (item) =>
                item.title.toLowerCase().contains(lower) ||
                item.category.toLowerCase().contains(lower) ||
                item.tag.toLowerCase().contains(lower),
          )
          .toList();

      final targetIndex = state.currentIndex == 4
          ? (localWardrobe.isNotEmpty ? 2 : 3)
          : state.currentIndex;

      state = state.copyWith(
        currentIndex: targetIndex,
        discoverItems: localDiscover.isEmpty
            ? state.discoverItems
            : localDiscover,
        wardrobeItems: localWardrobe.isEmpty
            ? state.wardrobeItems
            : localWardrobe,
        uploadMessage: 'Showing local search results for "$trimmed".',
      );
    }

    await _persistState();
  }

  Future<String?> pickWardrobeItemImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pick(
        useCamera: source == ImageSource.camera,
      );
      return pickedFile?.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadWardrobeItemImage(String imagePath) async {
    if (imagePath.isEmpty) {
      state = state.copyWith(
        uploadSucceeded: false,
        uploadMessage: 'Please choose an item photo first.',
      );
      return null;
    }

    final assetName = await _uploadImageToBackend(
      imagePath,
      startedMessage: 'Uploading closet item photo...',
      successFallbackMessage: 'Closet item photo uploaded.',
    );

    return assetName;
  }

  Future<bool> addWardrobeItem(
    String title,
    String category, {
    String imagePath = '',
  }) async {
    final newItem = WardrobeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      imageUrl: imagePath,
      tag: category,
      outfit: '',
      hairstyle: '',
      palette: [],
      paletteLabels: [],
      explanation: '',
      savedAt: DateTime.now(),
      entryType: 'clothes',
    );
    state = state.copyWith(
      wardrobeItems: [newItem, ...state.wardrobeItems],
      uploadMessage: 'Image added to your wardrobe.',
      uploadSucceeded: true,
    );
    await _persistState();
    try {
      await _dashboardHome.createWardrobeItem(newItem);
      state = state.copyWith(
        uploadMessage: 'Image uploaded and added to your wardrobe.',
        uploadSucceeded: true,
      );
      return true;
    } catch (_) {
      await _syncWardrobeWithBackend();
      state = state.copyWith(
        uploadMessage: 'Image saved locally. Upload will sync later.',
        uploadSucceeded: false,
      );
      return false;
    }
  }

  Future<void> addCustomOutfit({
    required String title,
    required String category,
    required String imagePath,
    String outfit = '',
    String hairstyle = '',
    String explanation = '',
    List<String> paletteLabels = const [],
  }) async {
    final newItem = WardrobeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      imageUrl: imagePath,
      tag: 'Custom',
      outfit: outfit,
      hairstyle: hairstyle,
      palette: _paletteValuesForLabels(paletteLabels),
      paletteLabels: paletteLabels,
      explanation: explanation.isEmpty
          ? 'Added manually to your digital wardrobe.'
          : explanation,
      savedAt: DateTime.now(),
      entryType: 'look',
    );
    state = state.copyWith(wardrobeItems: [newItem, ...state.wardrobeItems]);
    await _persistState();
    try {
      await _dashboardHome.createWardrobeItem(newItem);
    } catch (_) {
      await _syncWardrobeWithBackend();
    }
  }

  Future<void> addLookFromCloset(
    List<WardrobeEntry> items, {
    bool favorite = false,
  }) async {
    if (items.isEmpty) {
      return;
    }

    final title = 'Closet Outfit';
    final outfit = items.map((e) => '${e.category}: ${e.title}').join(' • ');
    final imageUrl = items.first.imageUrl;

    final newLook = WardrobeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: 'Custom Outfit',
      tag: 'From closet',
      imageUrl: imageUrl,
      outfit: outfit,
      hairstyle: '',
      explanation: 'Picked from your saved clothes.',
      palette: const [],
      paletteLabels: const [],
      savedAt: DateTime.now(),
      isFavorite: favorite,
      entryType: 'look',
    );

    state = state.copyWith(wardrobeItems: [newLook, ...state.wardrobeItems]);
    await _persistState();
    try {
      await _dashboardHome.createWardrobeItem(newLook);
    } catch (_) {
      await _syncWardrobeWithBackend();
    }
  }

  Future<void> toggleWardrobeFavorite(WardrobeEntry item) async {
    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    state = state.copyWith(
      wardrobeItems: state.wardrobeItems
          .map((e) => e.id == item.id ? updatedItem : e)
          .toList(),
    );
    await _persistState();
    try {
      await _dashboardHome.updateWardrobeItem(updatedItem);
    } catch (_) {
      await _syncWardrobeWithBackend();
    }
  }

  Future<void> updateWardrobeItem(
    WardrobeEntry item, {
    required String title,
    required String category,
    String? imagePath,
  }) async {
    final updatedItem = item.copyWith(
      title: title,
      category: category,
      tag: item.tag == item.category ? category : item.tag,
      imageUrl: imagePath ?? item.imageUrl,
      savedAt: DateTime.now(),
    );

    state = state.copyWith(
      wardrobeItems: state.wardrobeItems
          .map((entry) => entry.id == item.id ? updatedItem : entry)
          .toList(),
      uploadMessage: 'Wardrobe item updated.',
      uploadSucceeded: true,
    );
    await _persistState();
    try {
      await _dashboardHome.updateWardrobeItem(updatedItem);
    } catch (_) {
      await _syncWardrobeWithBackend();
    }
  }

  Future<void> removeWardrobeItem(WardrobeEntry item) async {
    state = state.copyWith(
      wardrobeItems: state.wardrobeItems.where((i) => i.id != item.id).toList(),
      uploadMessage: 'Wardrobe item deleted.',
      uploadSucceeded: true,
    );
    await _persistState();
    try {
      await _dashboardHome.deleteWardrobeItem(item.id);
    } catch (_) {
      await _syncWardrobeWithBackend();
    }
  }

  Future<void> saveDiscoverItem(DiscoverEntry item) async {
    final exists = state.wardrobeItems.any((entry) => entry.id == item.id);
    if (exists) {
      return;
    }

    final paletteLabels = _discoverPaletteLabels(item.category);
    final newItem = WardrobeEntry(
      id: item.id,
      title: item.title,
      category: item.category,
      tag: 'Discover',
      imageUrl: item.imageUrl,
      outfit: _discoverOutfitFor(item),
      hairstyle: _discoverHairstyleFor(item.category),
      explanation: item.caption,
      palette: _paletteValuesForLabels(paletteLabels),
      paletteLabels: paletteLabels,
      savedAt: DateTime.now(),
      entryType: 'look',
    );

    state = state.copyWith(wardrobeItems: [newItem, ...state.wardrobeItems]);
    await _persistState();
    try {
      await _dashboardHome.createWardrobeItem(newItem);
    } catch (_) {
      await _syncWardrobeWithBackend();
    }
  }

  Future<bool> uploadSelectedImage({
    String? occasion,
    String source = 'Uploaded Reference',
  }) async {
    final imagePath = state.selectedImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      state = state.copyWith(
        uploadSucceeded: false,
        uploadMessage: 'Pick an image before uploading.',
      );
      return false;
    }

    final uploadedAssetName = await _uploadImageToBackend(
      imagePath,
      startedMessage: 'Uploading image to backend...',
      successFallbackMessage: 'Image uploaded successfully.',
      progressScale: 0.35,
    );

    if (uploadedAssetName == null) {
      return false;
    }

    final selectedOccasion = occasion ?? state.currentRecommendation.occasion;

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.42,
      uploadedAssetName: uploadedAssetName,
      uploadSucceeded: false,
      hasCompletedStyleAnalysis: false,
      uploadMessage: 'Analyzing style...',
      aiProcessingMessage: 'Analyzing style...',
    );

    final stages = [
      'Analyzing style...',
      'Reading silhouette and proportions...',
      'Matching outfit and hairstyle rules...',
      'Building your color palette...',
      'Finalizing recommendation...',
    ];
    final progressStops = [0.5, 0.64, 0.78, 0.9, 1.0];

    for (var i = 0; i < stages.length; i++) {
      state = state.copyWith(
        aiProcessingMessage: stages[i],
        uploadMessage: stages[i],
        uploadProgress: progressStops[i],
      );
      await Future.delayed(const Duration(milliseconds: 650));
    }

    var analyzedProfile = state.profileData;
    DashboardRecommendation recommendation;
    String? analysisSummary;

    try {
      final analysis = await _dashboardHome.generateProfile(
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        imageReference: uploadedAssetName,
        occasion: selectedOccasion,
        source: source,
      );

      final profilePayload = analysis['profileData'];
      if (profilePayload is Map<String, dynamic>) {
        analyzedProfile = DashboardProfileData.fromJson(profilePayload);
      } else if (profilePayload is Map) {
        analyzedProfile = DashboardProfileData.fromJson(
          Map<String, dynamic>.from(profilePayload),
        );
      }

      final recommendationPayload = analysis['recommendation'];
      if (recommendationPayload is Map<String, dynamic>) {
        recommendation = DashboardRecommendation.fromJson(
          recommendationPayload,
        );
      } else if (recommendationPayload is Map) {
        recommendation = DashboardRecommendation.fromJson(
          Map<String, dynamic>.from(recommendationPayload),
        );
      } else {
        recommendation = await _generateRecommendationFromBackend(
          occasion: selectedOccasion,
          source: source,
          imageReference: uploadedAssetName,
          fallback: () => _generateRecommendation(
            occasion: selectedOccasion,
            profileData: analyzedProfile,
            preferenceScores: state.stylePreferenceScores,
          ),
        );
      }

      final summary = analysis['summary'];
      if (summary is String && summary.trim().isNotEmpty) {
        analysisSummary = summary.trim();
      }
    } catch (_) {
      recommendation = await _generateRecommendationFromBackend(
        occasion: selectedOccasion,
        source: source,
        imageReference: uploadedAssetName,
        fallback: () => _generateRecommendation(
          occasion: selectedOccasion,
          profileData: state.profileData,
          preferenceScores: state.stylePreferenceScores,
        ),
      );
    }

    final refreshedList = [
      recommendation,
      ...state.homeRecommendations.where(
        (item) => item.id != recommendation.id,
      ),
    ].take(6).toList();

    state = state.copyWith(
      isUploading: false,
      uploadProgress: 1.0,
      uploadSucceeded: true,
      hasCompletedStyleAnalysis: true,
      profileData: analyzedProfile,
      currentRecommendation: recommendation,
      aiStyleOfDay: recommendation,
      homeRecommendations: refreshedList,
      aiProcessingMessage: 'Recommendation ready.',
      uploadMessage: analysisSummary ?? 'AI style analysis complete.',
    );
    await _persistState();
    return true;
  }

  Future<String?> uploadSelectedImageToBackend() async {
    final imagePath = state.selectedImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      state = state.copyWith(
        uploadSucceeded: false,
        uploadMessage: 'Pick an image before uploading.',
      );
      return null;
    }

    return _uploadImageToBackend(
      imagePath,
      startedMessage: 'Uploading image...',
      successFallbackMessage: 'Image uploaded successfully.',
    );
  }

  Future<String?> _uploadImageToBackend(
    String imagePath, {
    required String startedMessage,
    required String successFallbackMessage,
    double progressScale = 1,
  }) async {
    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0,
      uploadSucceeded: false,
      uploadMessage: startedMessage,
      aiProcessingMessage: startedMessage,
    );

    final fileName = imagePath.split('/').last;
    final uploadResult = await _uploadItemPhotoUsecase(
      UploadItemPhotoParams(
        imagePath: imagePath,
        fileName: fileName,
        onSendProgress: (sent, total) {
          final progress = total > 0 ? sent / total : 0.0;
          state = state.copyWith(
            uploadProgress: (progress.clamp(0.0, 1.0) * progressScale)
                .toDouble(),
          );
        },
      ),
    );

    return uploadResult.fold(
      (failure) {
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 0,
          uploadSucceeded: false,
          uploadMessage: failure.message.isEmpty
              ? 'Upload failed.'
              : failure.message,
          aiProcessingMessage: null,
          uploadedAssetName: fileName,
        );
        return null;
      },
      (data) {
        final assetName = _extractAssetName(data) ?? fileName;
        state = state.copyWith(
          isUploading: false,
          uploadProgress: progressScale >= 1 ? 1 : state.uploadProgress,
          uploadSucceeded: true,
          uploadedAssetName: assetName,
          uploadMessage: _extractMessage(data, successFallbackMessage),
          aiProcessingMessage: 'Upload complete.',
        );
        return assetName;
      },
    );
  }

  Future<void> likeCurrentRecommendation() async {
    final recommendation = state.currentRecommendation;
    await likeRecommendation(recommendation);
  }

  Future<void> likeRecommendation(
    DashboardRecommendation recommendation,
  ) async {
    final updatedScores = Map<String, int>.from(state.stylePreferenceScores);
    updatedScores[recommendation.category] =
        (updatedScores[recommendation.category] ?? 0) + 1;
    final updatedWardrobe = _saveRecommendationToWardrobe(
      recommendation,
      existing: state.wardrobeItems,
      markFavorite: true,
    );

    state = state.copyWith(
      preferenceScore: state.preferenceScore + 1,
      stylePreferenceScores: updatedScores,
      wardrobeItems: updatedWardrobe,
      currentRecommendation: recommendation,
      uploadMessage:
          'Saved to Wardrobe and tuned future recommendations to ${recommendation.category.toLowerCase()} looks.',
    );
    await _persistState();
    await _syncWardrobeWithBackend();
    await _archiveTodaysLook(recommendation);
  }

  /// Records the saved look in the user's Style Archive under today's day
  /// slot. Best-effort: archiving failures shouldn't disrupt the save flow.
  Future<void> _archiveTodaysLook(
    DashboardRecommendation recommendation,
  ) async {
    if (!_isLiveRecommendation(recommendation)) {
      return;
    }
    try {
      final now = DateTime.now();
      await _saveStyleArchiveEntryUsecase(
        weekKey: computeWeekKey(now),
        day: computeDayAbbrev(now),
        occasion: recommendation.occasion,
        title: recommendation.title,
        outfit: recommendation.outfit,
        imageUrl: recommendation.imageUrl,
        explanation: recommendation.explanation,
        paletteLabels: recommendation.paletteLabels,
        wardrobeItemsUsed: recommendation.wardrobeItemsUsed,
      );
    } catch (_) {
      // Archiving is a secondary effect; ignore failures.
    }
  }

  Future<void> saveCurrentRecommendation() async {
    await saveRecommendation(state.currentRecommendation);
  }

  Future<void> saveRecommendation(
    DashboardRecommendation recommendation,
  ) async {
    final updatedWardrobe = _saveRecommendationToWardrobe(
      recommendation,
      existing: state.wardrobeItems,
    );
    state = state.copyWith(
      wardrobeItems: updatedWardrobe,
      currentRecommendation: recommendation,
      uploadMessage: 'Saved this recommendation to your Wardrobe.',
    );
    await _persistState();
    await _syncWardrobeWithBackend();
    await _archiveTodaysLook(recommendation);
  }

  Future<void> dislikeCurrentRecommendation() async {
    if (state.isUploading) {
      return;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.35,
      aiProcessingMessage: 'Reworking your recommendation...',
      uploadMessage: 'Finding a different direction...',
    );
    final recommendation = await _generateRecommendationFromBackend(
      occasion: state.currentRecommendation.occasion,
      source: 'New Inspiration',
      fallback: () => _generateRecommendation(
        occasion: state.currentRecommendation.occasion,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        excludedCategory: state.currentRecommendation.category,
      ),
    );
    state = state.copyWith(
      isUploading: false,
      uploadProgress: 0,
      currentRecommendation: recommendation,
      aiStyleOfDay: recommendation,
      uploadSucceeded: true,
      aiProcessingMessage: 'Updated recommendation ready.',
      uploadMessage: 'Generated a fresh recommendation based on your feedback.',
    );
    await _persistState();
  }

  /// Clears the AI stylist chat history.
  void clearChatMessages() {
    state = state.copyWith(chatMessages: []);
  }

  Future<void> sendChatMessage(
    String message, {
    String source = 'My Wardrobe',
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || state.isChatTyping) {
      return;
    }

    final nextMessages = [
      ...state.chatMessages,
      ChatMessage(id: _id('chat-user'), text: trimmed, isUser: true),
    ];
    state = state.copyWith(chatMessages: nextMessages, isChatTyping: true);

    String reply;
    DashboardRecommendation? suggestedRecommendation;
    var isGeneratingPromptLook = false;

    try {
      final response = await _dashboardHome.chatWithAssistant(
        message: trimmed,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        source: source,
        currentRecommendation: state.currentRecommendation,
      );
      final remoteReply = response['reply'] ?? response['text'];
      reply = (remoteReply is String && remoteReply.trim().isNotEmpty)
          ? remoteReply.trim()
          : 'Your AI stylist did not return a message. Please try again.';

      final recommendationPayload = response['recommendation'];
      if (recommendationPayload is Map<String, dynamic>) {
        suggestedRecommendation = DashboardRecommendation.fromJson(
          recommendationPayload,
        );
      } else if (recommendationPayload is Map) {
        suggestedRecommendation = DashboardRecommendation.fromJson(
          Map<String, dynamic>.from(recommendationPayload),
        );
      }
    } catch (_) {
      reply =
          '✈️ You\'re offline right now. Connect to WiFi to chat with your AI stylist. Your previous style recommendations are still available above!';
    }

    // The assistant endpoint is responsible for the conversation, but it can
    // legitimately return only a text reply. A styling prompt should still
    // produce a visual look, so use the outfit generator as a fallback when
    // the chat response did not include a usable recommendation image.
    if (_looksLikeVisualStylingRequest(trimmed) &&
        (suggestedRecommendation == null ||
            suggestedRecommendation.imageUrl.trim().isEmpty)) {
      isGeneratingPromptLook = true;
      state = state.copyWith(
        isUploading: true,
        uploadProgress: 0.2,
        aiProcessingMessage: 'Generating your look...',
        uploadMessage: 'Turning your styling request into an outfit...',
      );

      suggestedRecommendation = await _generateRecommendationFromBackend(
        // Passing the prompt through this field preserves the user’s full
        // request for the backend AI prompt while its occasion normalizer can
        // still extract values such as Wedding, Party, or Office.
        occasion: trimmed,
        source: source,
        fallback: () => _generateRecommendation(
          occasion: state.currentRecommendation.occasion,
          profileData: state.profileData,
          preferenceScores: state.stylePreferenceScores,
        ),
      );
    }

    final nextRecommendations = suggestedRecommendation == null
        ? state.homeRecommendations
        : [
            suggestedRecommendation,
            ...state.homeRecommendations.where(
              (item) => item.id != suggestedRecommendation!.id,
            ),
          ].take(6).toList();

    state = state.copyWith(
      chatMessages: [
        ...nextMessages,
        ChatMessage(id: _id('chat-ai'), text: reply, isUser: false),
      ],
      currentRecommendation:
          suggestedRecommendation ?? state.currentRecommendation,
      aiStyleOfDay: suggestedRecommendation ?? state.aiStyleOfDay,
      homeRecommendations: nextRecommendations,
      uploadMessage: suggestedRecommendation == null
          ? state.uploadMessage
          : 'AI assistant suggested a new ${suggestedRecommendation.category.toLowerCase()} look.',
      isUploading: isGeneratingPromptLook ? false : state.isUploading,
      uploadProgress: isGeneratingPromptLook ? 1 : state.uploadProgress,
      aiProcessingMessage: isGeneratingPromptLook
          ? 'Look ready.'
          : state.aiProcessingMessage,
      isChatTyping: false,
    );
    await _persistState();
  }

  bool _looksLikeVisualStylingRequest(String message) {
    return RegExp(
      r'\b(generate|create|suggest|recommend|outfit|wear|style me|styling|look|dress|gown|clothes|clothing|fashion|saree|sari|kurta|kurti|blazer|shirt|top|skirt|trousers|pants|jeans|jacket|shoes|heels|accessories|color palette|colour palette|hairstyle|hair style|wardrobe|party|wedding|office|date night|festival|formal|casual|vacation|holiday|airport|travel|brunch|beach|dinner|meeting|interview)\b',
      caseSensitive: false,
    ).hasMatch(message);
  }

  Future<void> updateProfileData(
    DashboardProfileData profileData, {
    bool persistSilhouette = true,
  }) async {
    state = state.copyWith(profileData: profileData);

    if (persistSilhouette) {
      final silhouetteResult = await _getSilhouetteProfileUsecase();
      await silhouetteResult.fold((_) async {}, (silhouette) async {
        if (silhouette == null) {
          return;
        }

        await _saveSilhouetteProfileUsecase(
          SaveSilhouetteProfileParams(
            profile: silhouette.copyWith(
              skinTone: profileData.skinTone.toLowerCase(),
              buildType: profileData.bodyType.toLowerCase(),
              faceShape: profileData.faceShape.toLowerCase(),
            ),
          ),
        );
      });
    }

    await _persistState();
  }

  List<WardrobeEntry> _saveRecommendationToWardrobe(
    DashboardRecommendation recommendation, {
    required List<WardrobeEntry> existing,
    bool markFavorite = false,
  }) {
    final items = [...existing];
    final existingIndex = items.indexWhere(
      (item) => item.id == recommendation.id,
    );
    if (existingIndex != -1) {
      if (!markFavorite) {
        return items;
      }
      final current = items[existingIndex];
      if (current.isFavorite) {
        return items;
      }
      items[existingIndex] = current.copyWith(isFavorite: true);
      return items;
    }

    return [
      WardrobeEntry.fromRecommendation(
        recommendation,
      ).copyWith(isFavorite: markFavorite),
      ...items,
    ];
  }

  List<int> _paletteValuesForLabels(List<String> labels) {
    const colorMap = {
      'Ivory': 0xFFF6F0E6,
      'Beige': 0xFFDAB894,
      'Camel': 0xFFC08B5C,
      'Brown': 0xFF7B4B2A,
      'Olive': 0xFF73845B,
      'Black': 0xFF1D1D1D,
      'White': 0xFFFDFDFD,
      'Blue': 0xFF5D87C7,
      'Navy': 0xFF243B5A,
      'Blush': 0xFFEAB4C5,
      'Berry': 0xFF8D3B72,
      'Grey': 0xFF8A8F98,
    };

    return labels
        .map((label) => colorMap[label] ?? 0xFFD9C7B8)
        .toList(growable: false);
  }

  List<String> _discoverPaletteLabels(String category) {
    return switch (category) {
      'Formal' => const ['Black', 'Ivory', 'Grey'],
      'Party' => const ['Berry', 'Black', 'Blush'],
      'Streetwear' => const ['Grey', 'Black', 'Olive'],
      'Summer' => const ['Ivory', 'Beige', 'Blue'],
      'Winter' => const ['Navy', 'Grey', 'White'],
      _ => const ['Beige', 'Camel', 'Olive'],
    };
  }

  String _discoverOutfitFor(DiscoverEntry item) {
    return switch (item.category) {
      'Formal' =>
        'Structured blazer, silky blouse, wide-leg trousers, pointed heels',
      'Party' => 'Statement top, tailored skirt, metallic heels, mini bag',
      'Streetwear' => 'Oversized jacket, relaxed tee, cargo pants, sneakers',
      'Summer' => 'Linen shirt, airy shorts, woven sandals, shoulder bag',
      'Winter' => 'Knit sweater, long coat, straight jeans, ankle boots',
      _ => 'Relaxed blazer, fitted top, straight pants, clean sneakers',
    };
  }

  String _discoverHairstyleFor(String category) {
    return switch (category) {
      'Formal' => 'Sleek low bun',
      'Party' => 'Soft glam waves',
      'Streetwear' => 'Textured ponytail',
      'Summer' => 'Loose braided ponytail',
      'Winter' => 'Smooth blowout',
      _ => 'Soft layered blowout',
    };
  }

  Future<DashboardRecommendation> _generateRecommendationFromBackend({
    required String occasion,
    required DashboardRecommendation Function() fallback,
    String source = 'My Wardrobe',
    String? imageReference,
  }) async {
    try {
      return await _dashboardHome.generateOutfit(
        occasion: occasion,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        source: source,
        imageReference: imageReference,
      );
    } catch (error) {
      debugPrint('AI outfit request failed; using local fallback: $error');
      await Future.delayed(const Duration(milliseconds: 600));
      return fallback();
    }
  }

  /// Returns true when the user's profile gender is explicitly set to male.
  /// Empty / unset / female defaults to false so existing female outfits are preserved.
  bool _isMale(DashboardProfileData profileData) {
    final g = profileData.gender.trim().toLowerCase();
    return g == 'male' || g == 'm';
  }

  List<DashboardRecommendation> _generateOccasionRecommendationsList(
    String occasion,
    DashboardProfileData profileData,
    Map<String, int> preferenceScores,
  ) {
    final lower = occasion.trim().toLowerCase();
    final male = _isMale(profileData);

    // ── WEDDING ────────────────────────────────────────────────────────────
    if (lower.contains('wedding') || lower.contains('shaadi') || lower.contains('marriage')) {
      if (male) {
        return [
          DashboardRecommendation(
            id: 'wedding-m1',
            title: 'Classic Ivory Sherwani & Churidar',
            occasion: 'Wedding',
            category: 'Traditional',
            mood: 'Regal & Royal',
            imageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=400&q=80',
            outfit: 'Ivory raw-silk sherwani with gold zari embroidery, matching churidar, embroidered waistcoat & leather Mojris',
            hairstyle: 'Neatly styled with light pomade; trimmed beard',
            explanation: 'The quintessential groom & wedding-guest sherwani — timeless and commanding.',
            palette: _paletteValuesForLabels(const ['Ivory', 'Gold', 'Deep Maroon']),
            paletteLabels: const ['Ivory', 'Gold', 'Deep Maroon'],
          ),
          DashboardRecommendation(
            id: 'wedding-m2',
            title: 'Embroidered Bandhgala Suit',
            occasion: 'Wedding',
            category: 'Traditional',
            mood: 'Classic Elegance',
            imageUrl: 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400&q=80',
            outfit: 'Nehru-collar bandhgala jacket with intricate threadwork, slim trousers & pocket square',
            hairstyle: 'Side-parted clean cut',
            explanation: 'A refined Indian formal jacket that exudes heritage charm at wedding functions.',
            palette: _paletteValuesForLabels(const ['Royal Blue', 'Gold', 'Ivory']),
            paletteLabels: const ['Royal Blue', 'Gold', 'Ivory'],
          ),
          DashboardRecommendation(
            id: 'wedding-m3',
            title: 'Silk Kurta & Dhoti Ensemble',
            occasion: 'Wedding',
            category: 'Traditional',
            mood: 'Graceful & Festive',
            imageUrl: 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400&q=80',
            outfit: 'Pure silk embroidered kurta, silk dhoti with gold border, stole draped & Kolhapuri sandals',
            hairstyle: 'Traditional oiled neat look',
            explanation: 'Authentic South-Indian inspired silk kurta-dhoti for traditional wedding ceremonies.',
            palette: _paletteValuesForLabels(const ['Deep Crimson', 'Gold', 'Emerald']),
            paletteLabels: const ['Deep Crimson', 'Gold', 'Emerald'],
          ),
          DashboardRecommendation(
            id: 'wedding-m4',
            title: 'Indo-Western Tuxedo Sherwani',
            occasion: 'Wedding',
            category: 'Indo-Western',
            mood: 'Modern Royal',
            imageUrl: 'https://images.unsplash.com/photo-1627225925004-2f69684e93c1?w=400&q=80',
            outfit: 'Structured tuxedo-lapel sherwani over straight-cut trousers, embroidered pocket square & black Mojris',
            hairstyle: 'Textured pompadour / side part',
            explanation: 'Modern fusion sherwani blending tuxedo sophistication with Indian craftsmanship.',
            palette: _paletteValuesForLabels(const ['Champagne', 'Black', 'Gold']),
            paletteLabels: const ['Champagne', 'Black', 'Gold'],
          ),
          DashboardRecommendation(
            id: 'wedding-m5',
            title: 'Jodhpuri Suit with Contrast Piping',
            occasion: 'Wedding',
            category: 'Ethnic Fusion',
            mood: 'Vibrant & Festive',
            imageUrl: 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=400&q=80',
            outfit: 'Jodhpuri bundi jacket with contrast piping over slim trousers, kurta shirt & leather shoes',
            hairstyle: 'Clean fade with side part',
            explanation: 'Heritage Jodhpuri design elevated with modern tailoring for wedding receptions.',
            palette: _paletteValuesForLabels(const ['Emerald Green', 'Gold', 'Ivory']),
            paletteLabels: const ['Emerald Green', 'Gold', 'Ivory'],
          ),
          DashboardRecommendation(
            id: 'wedding-m6',
            title: 'Velvet Sherwani with Embroidered Stole',
            occasion: 'Wedding',
            category: 'Couture',
            mood: 'Glamorous',
            imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
            outfit: 'Midnight-blue velvet sherwani, gold embroidered stole, slim pants & stone-studded Mojris',
            hairstyle: 'Slicked back with beard',
            explanation: 'Ultra-rich velvet sherwani for evening galas and high-profile wedding receptions.',
            palette: _paletteValuesForLabels(const ['Midnight Blue', 'Gold', 'Pearl']),
            paletteLabels: const ['Midnight Blue', 'Gold', 'Pearl'],
          ),
        ];
      }
      return [
        DashboardRecommendation(
          id: 'wedding-1',
          title: 'Royal Velvet Embroidered Lehenga',
          occasion: 'Wedding',
          category: 'Traditional',
          mood: 'Regal & Royal',
          imageUrl: 'https://images.unsplash.com/photo-1610189352649-1a7b2d7e9be5?w=400&q=80',
          outfit: 'Heavy velvet lehenga in deep crimson with gold zari embroidery, silk blouse & sheer net dupatta',
          hairstyle: 'Traditional braided bun with fresh jasmine flowers',
          explanation: 'A grand traditional ensemble perfect for main wedding ceremonies and royal receptions.',
          palette: _paletteValuesForLabels(const ['Deep Crimson', 'Gold', 'Emerald']),
          paletteLabels: const ['Deep Crimson', 'Gold', 'Emerald'],
        ),
        DashboardRecommendation(
          id: 'wedding-2',
          title: 'Banarasi Silk Heritage Saree',
          occasion: 'Wedding',
          category: 'Traditional',
          mood: 'Classic Elegance',
          imageUrl: 'https://images.unsplash.com/photo-1571290274554-6a2eaa771e5f?w=400&q=80',
          outfit: 'Pure Banarasi silk saree with gold zari woven floral motifs, elbow-sleeve blouse & Kundan choker set',
          hairstyle: 'Sleek low bun with statement jhumkas',
          explanation: 'Timeless Indian heritage saree crafted for traditional wedding rituals and family celebrations.',
          palette: _paletteValuesForLabels(const ['Ruby Red', 'Gold', 'Ivory']),
          paletteLabels: const ['Ruby Red', 'Gold', 'Ivory'],
        ),
        DashboardRecommendation(
          id: 'wedding-3',
          title: 'Pastel Floral Anarkali Suit',
          occasion: 'Wedding',
          category: 'Ethnic Fusion',
          mood: 'Graceful & Dreamy',
          imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4b3d21?w=400&q=80',
          outfit: 'Floor-length silk Anarkali suit with Gota Patti work, organza dupatta & pearl Chandbali earrings',
          hairstyle: 'Soft romantic waves with side pin-up',
          explanation: 'Lightweight yet luxurious Anarkali suit ideal for day weddings and daytime functions.',
          palette: _paletteValuesForLabels(const ['Blush Pink', 'Rose Gold', 'Ivory']),
          paletteLabels: const ['Blush Pink', 'Rose Gold', 'Ivory'],
        ),
        DashboardRecommendation(
          id: 'wedding-4',
          title: 'Regal Indo-Western Sherwani Jacket Set',
          occasion: 'Wedding',
          category: 'Indo-Western',
          mood: 'Modern Royal',
          imageUrl: 'https://images.unsplash.com/photo-1628191013085-990d39ec25b4?w=400&q=80',
          outfit: 'Embroidered silk sherwani jacket over tailored trousers, paired with leather Mojris & pocket square',
          hairstyle: 'Textured pompadour / side part',
          explanation: 'Sophisticated fusion outerwear designed for high-profile wedding receptions.',
          palette: _paletteValuesForLabels(const ['Royal Blue', 'Champagne', 'Gold']),
          paletteLabels: const ['Royal Blue', 'Champagne', 'Gold'],
        ),
        DashboardRecommendation(
          id: 'wedding-5',
          title: 'Georgette Mirror Work Sharara Set',
          occasion: 'Wedding',
          category: 'Traditional',
          mood: 'Vibrant & Festive',
          imageUrl: 'https://images.unsplash.com/photo-1609209035942-1d1e1d53f98e?w=400&q=80',
          outfit: 'Tiered georgette sharara pants with mirror-work short kurti, net dupatta & Maang Tikka',
          hairstyle: 'Half-up braided crown',
          explanation: 'Flowy, celebratory sharara set crafted for movement and dancing during wedding celebrations.',
          palette: _paletteValuesForLabels(const ['Emerald Green', 'Gold', 'Lime']),
          paletteLabels: const ['Emerald Green', 'Gold', 'Lime'],
        ),
        DashboardRecommendation(
          id: 'wedding-6',
          title: 'Embellished Organza Saree & Pearl Corset',
          occasion: 'Wedding',
          category: 'Couture',
          mood: 'Glamorous',
          imageUrl: 'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=400&q=80',
          outfit: 'Hand-embellished champagne organza saree with a pearl corset blouse & crystal clutch',
          hairstyle: 'Glamorous Hollywood waves',
          explanation: 'Ultra-modern wedding couture saree for evening galas and cocktail receptions.',
          palette: _paletteValuesForLabels(const ['Champagne', 'Silver', 'Pearl']),
          paletteLabels: const ['Champagne', 'Silver', 'Pearl'],
        ),
      ];
    }

    // ── SANGEET / MEHENDI ──────────────────────────────────────────────────
    if (lower.contains('sangeet') || lower.contains('mehendi')) {
      if (male) {
        return [
          DashboardRecommendation(
            id: 'sangeet-m1',
            title: 'Embroidered Kurta & Patiala Set',
            occasion: 'Sangeet',
            category: 'Festive Ethnic',
            mood: 'Dazzling',
            imageUrl: 'https://images.unsplash.com/photo-1519657306-a8d6a4bc0a5e?w=400&q=80',
            outfit: 'Floral-embroidered silk kurta with Patiala salwar, embroidered Nehru waistcoat & beaded Juttis',
            hairstyle: 'Textured slick back',
            explanation: 'Vibrant kurta-Patiala set designed for high-energy Sangeet dance performances.',
            palette: _paletteValuesForLabels(const ['Sparkling Yellow', 'Orange', 'Gold']),
            paletteLabels: const ['Sparkling Yellow', 'Orange', 'Gold'],
          ),
          DashboardRecommendation(
            id: 'sangeet-m2',
            title: 'Mirror Work Bandhgala & Slim Trousers',
            occasion: 'Sangeet',
            category: 'Indo-Western',
            mood: 'Contemporary Chic',
            imageUrl: 'https://images.unsplash.com/photo-1617196034176-5e80c4d01432?w=400&q=80',
            outfit: 'Short mirror-embellished bandhgala jacket over white kurta & slim-fit cream trousers',
            hairstyle: 'Neat side part with beard',
            explanation: 'Glam Indo-Western bandhgala perfect for toasts and festive group dances.',
            palette: _paletteValuesForLabels(const ['Magenta', 'Gold', 'Ivory']),
            paletteLabels: const ['Magenta', 'Gold', 'Ivory'],
          ),
          DashboardRecommendation(
            id: 'sangeet-m3',
            title: 'Sequined Nehru Jacket Set',
            occasion: 'Sangeet',
            category: 'Party Ethnic',
            mood: 'Midnight Sparkle',
            imageUrl: 'https://images.unsplash.com/photo-1631281956016-3cdc1b2fe5fb?w=400&q=80',
            outfit: 'Sequined royal-blue Nehru jacket over silk kurta, straight trousers & metallic Mojris',
            hairstyle: 'Quiffed with trimmed beard',
            explanation: 'Sparkling Nehru jacket that catches every spotlight on the Sangeet dance floor.',
            palette: _paletteValuesForLabels(const ['Royal Blue', 'Silver', 'Gold']),
            paletteLabels: const ['Royal Blue', 'Silver', 'Gold'],
          ),
          DashboardRecommendation(
            id: 'sangeet-m4',
            title: 'Printed Indo-Western Jacket & Slim Pants',
            occasion: 'Sangeet',
            category: 'Ethnic Fusion',
            mood: 'Edgy & Bold',
            imageUrl: 'https://images.unsplash.com/photo-1578932750294-f5075e85f44a?w=400&q=80',
            outfit: 'Block-printed structured jacket, kurta shirt & straight-fit slim trousers with leather loafers',
            hairstyle: 'Fade cut with styled top',
            explanation: 'Bold printed fusion jacket blending traditional block prints with modern tailoring.',
            palette: _paletteValuesForLabels(const ['Electric Blue', 'Saffron', 'Black']),
            paletteLabels: const ['Electric Blue', 'Saffron', 'Black'],
          ),
        ];
      }
      return [
        DashboardRecommendation(
          id: 'sangeet-1',
          title: 'Sparkling Mirror Crop Top & Lehenga',
          occasion: 'Sangeet',
          category: 'Festive Glam',
          mood: 'Dazzling',
          imageUrl: 'https://images.unsplash.com/photo-1617019114583-affb34d1b3cd?w=400&q=80',
          outfit: 'All-over mirror-work crop top with a twirl-ready georgette lehenga & lightweight ruffled dupatta',
          hairstyle: 'High voluminous ponytail',
          explanation: 'Designed for high-energy dance performances and evening Sangeet festivities.',
          palette: _paletteValuesForLabels(const ['Sparkling Lavender', 'Silver', 'Plum']),
          paletteLabels: const ['Sparkling Lavender', 'Silver', 'Plum'],
        ),
        DashboardRecommendation(
          id: 'sangeet-2',
          title: 'Indo-Western Cape Suit & Tulip Pants',
          occasion: 'Sangeet',
          category: 'Indo-Western',
          mood: 'Contemporary Chic',
          imageUrl: 'https://images.unsplash.com/photo-1596993100471-c3905dafa78e?w=400&q=80',
          outfit: 'Embroidered sheer cape over a strapless bustier & draped tulip trousers',
          hairstyle: 'Sleek straight hair with middle part',
          explanation: 'Modern Indo-Western cape set offering maximum comfort and high fashion impact.',
          palette: _paletteValuesForLabels(const ['Magenta', 'Gold', 'Bronze']),
          paletteLabels: const ['Magenta', 'Gold', 'Bronze'],
        ),
        DashboardRecommendation(
          id: 'sangeet-3',
          title: 'Sequined Net Cocktail Saree',
          occasion: 'Sangeet',
          category: 'Party Wear',
          mood: 'Midnight Sparkle',
          imageUrl: 'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=400&q=80',
          outfit: 'Gradient sequined net saree with sleeveless designer blouse & drop earrings',
          hairstyle: 'Side-swept curls',
          explanation: 'A glamorous party saree that catches every light on the Sangeet dance floor.',
          palette: _paletteValuesForLabels(const ['Midnight Blue', 'Silver', 'Navy']),
          paletteLabels: const ['Midnight Blue', 'Silver', 'Navy'],
        ),
        DashboardRecommendation(
          id: 'sangeet-4',
          title: 'Dhoti Pants & Metallic Jacket Set',
          occasion: 'Sangeet',
          category: 'Ethnic Fusion',
          mood: 'Edgy & Bold',
          imageUrl: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400&q=80',
          outfit: 'Silk dhoti pants with a structured metallic embroidered jacket & heeled sandals',
          hairstyle: 'Braided crown updos',
          explanation: 'Edgy fusion outfit blending traditional dhoti draping with modern tailoring.',
          palette: _paletteValuesForLabels(const ['Electric Blue', 'Silver', 'Black']),
          paletteLabels: const ['Electric Blue', 'Silver', 'Black'],
        ),
      ];
    }

    // ── PARTY ──────────────────────────────────────────────────────────────
    if (lower.contains('party') || lower.contains('club') || lower.contains('cocktail')) {
      if (male) {
        return [
          DashboardRecommendation(
            id: 'party-m1',
            title: 'Slim-Fit Black Suit & Turtleneck',
            occasion: 'Party',
            category: 'Evening Wear',
            mood: 'Sleek & Sophisticated',
            imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&q=80',
            outfit: 'Slim-fit black suit, fitted black turtleneck, leather Derby shoes & silver watch',
            hairstyle: 'Textured undercut or slick back',
            explanation: 'A modern monochromatic party look that never goes out of style.',
            palette: _paletteValuesForLabels(const ['Jet Black', 'Charcoal', 'Silver']),
            paletteLabels: const ['Jet Black', 'Charcoal', 'Silver'],
          ),
          DashboardRecommendation(
            id: 'party-m2',
            title: 'Printed Cuban Shirt & Tailored Chinos',
            occasion: 'Party',
            category: 'Smart Casual',
            mood: 'Relaxed & Cool',
            imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&q=80',
            outfit: 'Open-collar printed Cuban shirt, slim-fit chinos, suede loafers & minimal chain necklace',
            hairstyle: 'Messy textured crop',
            explanation: 'Effortlessly cool party look balancing print and tailoring.',
            palette: _paletteValuesForLabels(const ['Cobalt Blue', 'Cream', 'Tan']),
            paletteLabels: const ['Cobalt Blue', 'Cream', 'Tan'],
          ),
          DashboardRecommendation(
            id: 'party-m3',
            title: 'Monochrome Coord Set',
            occasion: 'Party',
            category: 'Street Glam',
            mood: 'Bold & Confident',
            imageUrl: 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=400&q=80',
            outfit: 'Matching oversized shirt & wide-leg trousers in one tone, clean sneakers & minimalist watch',
            hairstyle: 'Fade cut with styled top',
            explanation: 'Head-to-toe monochrome coord set for a powerful, fashion-forward party statement.',
            palette: _paletteValuesForLabels(const ['Caramel', 'Sand', 'Off-White']),
            paletteLabels: const ['Caramel', 'Sand', 'Off-White'],
          ),
          DashboardRecommendation(
            id: 'party-m4',
            title: 'Velvet Blazer & Dark Jeans',
            occasion: 'Party',
            category: 'Smart Glam',
            mood: 'Edgy & Refined',
            imageUrl: 'https://images.unsplash.com/photo-1610047802551-1e8e7c51d776?w=400&q=80',
            outfit: 'Rich velvet blazer in burgundy, dark slim jeans, white shirt & Chelsea boots',
            hairstyle: 'Side-swept voluminous',
            explanation: 'Luxury velvet blazer adds evening drama to classic denim for parties.',
            palette: _paletteValuesForLabels(const ['Burgundy', 'Black', 'White']),
            paletteLabels: const ['Burgundy', 'Black', 'White'],
          ),
        ];
      }
      return [
        DashboardRecommendation(
          id: 'party-1',
          title: 'Sequined Cocktail Mini Dress',
          occasion: 'Party',
          category: 'Evening Wear',
          mood: 'Glamorous',
          imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80',
          outfit: 'All-over sequined bodycon mini dress with metallic ankle-strap heels & compact clutch',
          hairstyle: 'Sleek high ponytail',
          explanation: 'Turn heads at any night-out party or celebration with this shimmering look.',
          palette: _paletteValuesForLabels(const ['Midnight Black', 'Silver', 'Gunmetal']),
          paletteLabels: const ['Midnight Black', 'Silver', 'Gunmetal'],
        ),
        DashboardRecommendation(
          id: 'party-2',
          title: 'Emerald Satin Slip Maxi Dress',
          occasion: 'Party',
          category: 'Chic',
          mood: 'Seductive & Elegant',
          imageUrl: 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=400&q=80',
          outfit: 'Cowl-neck satin maxi slip dress, layered gold necklaces & stiletto heels',
          hairstyle: 'Loose textured beach waves',
          explanation: 'Effortlessly chic satin slip dress for upscale lounge parties and dinners.',
          palette: _paletteValuesForLabels(const ['Emerald Green', 'Gold', 'Black']),
          paletteLabels: const ['Emerald Green', 'Gold', 'Black'],
        ),
        DashboardRecommendation(
          id: 'party-3',
          title: 'Velvet Corset & Oversized Blazer',
          occasion: 'Party',
          category: 'Smart Glam',
          mood: 'Bold & Confident',
          imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=400&q=80',
          outfit: 'Structured velvet corset top, tailored wide-leg trousers & oversized silk blazer',
          hairstyle: 'Sharp bob / sleek straight',
          explanation: 'A powerful party look combining tailored masculine cuts with feminine velvet detail.',
          palette: _paletteValuesForLabels(const ['Burgundy', 'Black', 'Gold']),
          paletteLabels: const ['Burgundy', 'Black', 'Gold'],
        ),
        DashboardRecommendation(
          id: 'party-4',
          title: 'Leather Trousers & Sheer Sparkle Top',
          occasion: 'Party',
          category: 'Street Glam',
          mood: 'Edgy & Cool',
          imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&q=80',
          outfit: 'High-waisted faux leather trousers, sheer embellished turtleneck & pointed boots',
          hairstyle: 'Messy bun with face-framing strands',
          explanation: 'Urban night-out outfit balancing edgy leather textures with sparkle.',
          palette: _paletteValuesForLabels(const ['Black', 'Charcoal', 'Silver']),
          paletteLabels: const ['Black', 'Charcoal', 'Silver'],
        ),
      ];
    }

    // ── FORMAL ─────────────────────────────────────────────────────────────
    if (lower.contains('formal') || lower.contains('gala') || lower.contains('black tie')) {
      if (male) {
        return [
          DashboardRecommendation(
            id: 'formal-m1',
            title: 'Classic Charcoal Three-Piece Suit',
            occasion: 'Formal',
            category: 'Formal',
            mood: 'Majestic & Sophisticated',
            imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
            outfit: 'Charcoal three-piece suit, crisp white dress shirt, silk tie, pocket square & Oxford shoes',
            hairstyle: 'Neatly combed side part',
            explanation: 'The gold-standard men\'s formal look for galas, award nights & black-tie events.',
            palette: _paletteValuesForLabels(const ['Charcoal', 'White', 'Silver']),
            paletteLabels: const ['Charcoal', 'White', 'Silver'],
          ),
          DashboardRecommendation(
            id: 'formal-m2',
            title: 'Navy Double-Breasted Blazer',
            occasion: 'Formal',
            category: 'Tailored',
            mood: 'Power Elegance',
            imageUrl: 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400&q=80',
            outfit: 'Navy double-breasted blazer, light grey trousers, white spread-collar shirt & burgundy loafers',
            hairstyle: 'Clean taper fade',
            explanation: 'Bold double-breasted tailoring for high-profile corporate dinners and galas.',
            palette: _paletteValuesForLabels(const ['Navy Blue', 'Grey', 'Burgundy']),
            paletteLabels: const ['Navy Blue', 'Grey', 'Burgundy'],
          ),
          DashboardRecommendation(
            id: 'formal-m3',
            title: 'Classic Black Tuxedo & Bow Tie',
            occasion: 'Formal',
            category: 'Black Tie',
            mood: 'Timeless Luxe',
            imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80',
            outfit: 'Classic black tuxedo with satin lapel, white dress shirt, black bow tie & patent Oxford shoes',
            hairstyle: 'Slick back with pomade',
            explanation: 'The ultimate black-tie ensemble for red-carpet evenings and prestige events.',
            palette: _paletteValuesForLabels(const ['Jet Black', 'White', 'Ivory']),
            paletteLabels: const ['Jet Black', 'White', 'Ivory'],
          ),
        ];
      }
      return [
        DashboardRecommendation(
          id: 'formal-1',
          title: 'Floor-Length Satin Evening Gown',
          occasion: 'Formal',
          category: 'Formal',
          mood: 'Majestic & Sophisticated',
          imageUrl: 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?w=400&q=80',
          outfit: 'Floor-length heavy satin gown with a subtle leg slit, diamond drop earrings & satin clutch',
          hairstyle: 'Chignon low bun',
          explanation: 'Classic formal elegance for black-tie galas and prestigious award nights.',
          palette: _paletteValuesForLabels(const ['Navy Blue', 'Silver', 'Sapphire']),
          paletteLabels: const ['Navy Blue', 'Silver', 'Sapphire'],
        ),
        DashboardRecommendation(
          id: 'formal-2',
          title: 'Tailored Velvet Tuxedo Suit Set',
          occasion: 'Formal',
          category: 'Tailored',
          mood: 'Power Elegance',
          imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&q=80',
          outfit: 'Double-breasted velvet tuxedo blazer, silk lapel, cigarette pants & pointed pumps',
          hairstyle: 'Sleek backcomb wet look',
          explanation: 'A high-fashion alternative to evening dresses for formal corporate galas.',
          palette: _paletteValuesForLabels(const ['Classic Black', 'White', 'Gold']),
          paletteLabels: const ['Classic Black', 'White', 'Gold'],
        ),
        DashboardRecommendation(
          id: 'formal-3',
          title: 'One-Shoulder Draped Crepe Gown',
          occasion: 'Formal',
          category: 'Haute Couture',
          mood: 'Minimalist Luxe',
          imageUrl: 'https://images.unsplash.com/photo-1617922001439-4a2e6562f328?w=400&q=80',
          outfit: 'Asymmetric one-shoulder crepe gown with structured cape detail & crystal bangles',
          hairstyle: 'Asymmetric side bun',
          explanation: 'Architectural formal gown designed for red-carpet events and gala dinners.',
          palette: _paletteValuesForLabels(const ['Deep Plum', 'Rose Gold', 'Black']),
          paletteLabels: const ['Deep Plum', 'Rose Gold', 'Black'],
        ),
      ];
    }

    // ── OFFICE / WORK ──────────────────────────────────────────────────────
    if (lower.contains('office') || lower.contains('work')) {
      if (male) {
        return [
          DashboardRecommendation(
            id: 'office-m1',
            title: 'Linen Blazer & Slim Chinos',
            occasion: 'Office',
            category: 'Workwear',
            mood: 'Professional & Polished',
            imageUrl: 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=400&q=80',
            outfit: 'Unstructured linen blazer, slim chinos, tucked Oxford shirt & leather loafers',
            hairstyle: 'Neat side part',
            explanation: 'Breathable smart-casual office look for productive all-day meetings.',
            palette: _paletteValuesForLabels(const ['Camel', 'Navy', 'White']),
            paletteLabels: const ['Camel', 'Navy', 'White'],
          ),
          DashboardRecommendation(
            id: 'office-m2',
            title: 'Oxford Shirt & Suit Trousers',
            occasion: 'Office',
            category: 'Corporate',
            mood: 'Sleek Executive',
            imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&q=80',
            outfit: 'Crisp Oxford button-down, slim-fit suit trousers, leather belt & Derby shoes',
            hairstyle: 'Combed-back clean look',
            explanation: 'Timeless shirt-and-trousers corporate look for boardrooms and client meetings.',
            palette: _paletteValuesForLabels(const ['Light Blue', 'Charcoal', 'White']),
            paletteLabels: const ['Light Blue', 'Charcoal', 'White'],
          ),
          DashboardRecommendation(
            id: 'office-m3',
            title: 'Smart Casual Kurta & Formal Pants',
            occasion: 'Office',
            category: 'Ethnic Smart Casual',
            mood: 'Modern Power',
            imageUrl: 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400&q=80',
            outfit: 'Mandarin-collar cotton kurta, straight formal trousers & clean leather loafers',
            hairstyle: 'Neatly groomed with trimmed beard',
            explanation: 'Indian ethnic office wear balancing cultural roots with corporate presentation.',
            palette: _paletteValuesForLabels(const ['Slate Grey', 'White', 'Black']),
            paletteLabels: const ['Slate Grey', 'White', 'Black'],
          ),
        ];
      }
      return [
        DashboardRecommendation(
          id: 'office-1',
          title: 'Linen Blazer & High-Waist Trousers',
          occasion: 'Office',
          category: 'Workwear',
          mood: 'Professional & Polished',
          imageUrl: 'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=400&q=80',
          outfit: 'Single-breasted linen blazer, silk camisole, high-waisted wide-leg trousers & leather loafers',
          hairstyle: 'Neat low ponytail',
          explanation: 'Comfortable, breathable executive office attire suited for all-day meetings.',
          palette: _paletteValuesForLabels(const ['Camel', 'Ivory', 'Beige']),
          paletteLabels: const ['Camel', 'Ivory', 'Beige'],
        ),
        DashboardRecommendation(
          id: 'office-2',
          title: 'Tailored Shift Dress & Trench Coat',
          occasion: 'Office',
          category: 'Corporate',
          mood: 'Sleek Executive',
          imageUrl: 'https://images.unsplash.com/photo-1580913428023-02c695666d61?w=400&q=80',
          outfit: 'Structured knee-length shift dress, classic midi trench coat & leather tote bag',
          hairstyle: 'Soft blowout',
          explanation: 'Sharp corporate dress ensemble that seamlessly transitions from desk to dinner.',
          palette: _paletteValuesForLabels(const ['Navy', 'Beige', 'White']),
          paletteLabels: const ['Navy', 'Beige', 'White'],
        ),
        DashboardRecommendation(
          id: 'office-3',
          title: 'Plaid Suit Set & Leather Oxfords',
          occasion: 'Office',
          category: 'Tailored',
          mood: 'Modern Power',
          imageUrl: 'https://images.unsplash.com/photo-1548778943-5bbeeb1ba6c1?w=400&q=80',
          outfit: 'Checked plaid blazer and cropped trousers with crisp white shirt & leather oxfords',
          hairstyle: 'Sleek middle-parted bob',
          explanation: 'Smart-casual office suit set offering contemporary power dressing.',
          palette: _paletteValuesForLabels(const ['Grey Plaid', 'White', 'Black']),
          paletteLabels: const ['Grey Plaid', 'White', 'Black'],
        ),
      ];
    }

    // ── FESTIVAL ───────────────────────────────────────────────────────────
    if (lower.contains('festival') || lower.contains('diwali') || lower.contains('eid') || lower.contains('dashain') || lower.contains('tihar')) {
      if (male) {
        return [
          DashboardRecommendation(
            id: 'festival-m1',
            title: 'Embroidered Silk Kurta & Pyjama',
            occasion: 'Festival',
            category: 'Ethnic',
            mood: 'Joyful & Traditional',
            imageUrl: 'https://images.unsplash.com/photo-1519657306-a8d6a4bc0a5e?w=400&q=80',
            outfit: 'Vibrant silk embroidered kurta with printed pyjama, embroidered Nehru waistcoat & Kolhapuri sandals',
            hairstyle: 'Neatly oiled & groomed',
            explanation: 'Festive kurta-pyjama ensemble crafted for traditional family gatherings and pujas.',
            palette: _paletteValuesForLabels(const ['Mustard Yellow', 'Maroon', 'Gold']),
            paletteLabels: const ['Mustard Yellow', 'Maroon', 'Gold'],
          ),
          DashboardRecommendation(
            id: 'festival-m2',
            title: 'Nehru Jacket & Cotton Kurta Set',
            occasion: 'Festival',
            category: 'Handcrafted',
            mood: 'Serene & Festive',
            imageUrl: 'https://images.unsplash.com/photo-1617196034176-5e80c4d01432?w=400&q=80',
            outfit: 'Block-printed Nehru jacket over plain cotton kurta, matching trousers & embroidered Juttis',
            hairstyle: 'Natural with light styling',
            explanation: 'Heritage-inspired Nehru jacket over festive cotton kurta — perfect for Diwali & Eid.',
            palette: _paletteValuesForLabels(const ['Mint Green', 'Ivory', 'Gold']),
            paletteLabels: const ['Mint Green', 'Ivory', 'Gold'],
          ),
          DashboardRecommendation(
            id: 'festival-m3',
            title: 'Silk Dhoti Kurta & Temple Jewelry',
            occasion: 'Festival',
            category: 'Traditional',
            mood: 'Sacred & Festive',
            imageUrl: 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400&q=80',
            outfit: 'Pure silk kurta with dhoti, angavastram draped over shoulder & traditional rudraksha jewelry',
            hairstyle: 'Traditional clean look with tilak',
            explanation: 'Authentic temple-style silk kurta-dhoti ensemble for religious festivals and rituals.',
            palette: _paletteValuesForLabels(const ['Ruby Red', 'Gold', 'Saffron']),
            paletteLabels: const ['Ruby Red', 'Gold', 'Saffron'],
          ),
        ];
      }
      return [
        DashboardRecommendation(
          id: 'festival-1',
          title: 'Chanderi Silk Kurta & Palazzo Set',
          occasion: 'Festival',
          category: 'Ethnic',
          mood: 'Joyful & Traditional',
          imageUrl: 'https://images.unsplash.com/photo-1610189352649-1a7b2d7e9be5?w=400&q=80',
          outfit: 'Woven Chanderi silk straight kurta, embroidered dupatta, palazzo pants & embroidered Juttis',
          hairstyle: 'Traditional braid with parandi',
          explanation: 'Vibrant festive kurta set designed for traditional family pujas and festival gatherings.',
          palette: _paletteValuesForLabels(const ['Mustard Yellow', 'Maroon', 'Gold']),
          paletteLabels: const ['Mustard Yellow', 'Maroon', 'Gold'],
        ),
        DashboardRecommendation(
          id: 'festival-2',
          title: 'Hand-Embroidered Chikankari Anarkali',
          occasion: 'Festival',
          category: 'Handcrafted',
          mood: 'Serene & Graceful',
          imageUrl: 'https://images.unsplash.com/photo-1596177267006-04e3a93c2d1b?w=400&q=80',
          outfit: 'Pure cotton Chikankari hand-embroidered Anarkali suit with organza dupatta & silver oxidised jewelry',
          hairstyle: 'Soft open hair with maang tikka',
          explanation: 'Ethereal handcrafted Anarkali suit perfect for festive daytime celebrations.',
          palette: _paletteValuesForLabels(const ['Mint Green', 'Silver', 'Ivory']),
          paletteLabels: const ['Mint Green', 'Silver', 'Ivory'],
        ),
        DashboardRecommendation(
          id: 'festival-3',
          title: 'Traditional Kanjeevaram Heritage Saree',
          occasion: 'Festival',
          category: 'Traditional',
          mood: 'Sacred & Festive',
          imageUrl: 'https://images.unsplash.com/photo-1571290274554-6a2eaa771e5f?w=400&q=80',
          outfit: 'Heavy Kanjeevaram silk saree with zari border, brocade blouse & temple jewelry set',
          hairstyle: 'Classic bun with gajra',
          explanation: 'Authentic Indian heritage saree crafted for festival mornings and auspicious rituals.',
          palette: _paletteValuesForLabels(const ['Ruby Red', 'Gold', 'Emerald']),
          paletteLabels: const ['Ruby Red', 'Gold', 'Emerald'],
        ),
      ];
    }

    // ── CASUAL FALLBACK (Weekend / Travel / Beach / Street Style) ──────────
    if (male) {
      return [
        DashboardRecommendation(
          id: '$lower-m1',
          title: '$occasion Relaxed Jeans & Polo',
          occasion: occasion,
          category: 'Casual',
          mood: 'Relaxed & Cool',
          imageUrl: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400&q=80',
          outfit: 'Slim-fit jeans, classic polo shirt, clean white sneakers & minimal watch',
          hairstyle: 'Effortless natural style',
          explanation: 'A versatile everyday casual look tailored for your $occasion plans.',
          palette: _paletteValuesForLabels(const ['Denim', 'Navy', 'White']),
          paletteLabels: const ['Denim', 'Navy', 'White'],
        ),
        DashboardRecommendation(
          id: '$lower-m2',
          title: '$occasion Linen Shirt & Shorts',
          occasion: occasion,
          category: 'Summer Casual',
          mood: 'Fresh & Breezy',
          imageUrl: 'https://images.unsplash.com/photo-1542060748-10c28b62716f?w=400&q=80',
          outfit: 'Relaxed linen shirt, tailored shorts, canvas sneakers & crossbody bag',
          hairstyle: 'Tousled casual',
          explanation: 'Airy linen combination ideal for warm days and relaxed $occasion outings.',
          palette: _paletteValuesForLabels(const ['Sand', 'Sky Blue', 'Off-White']),
          paletteLabels: const ['Sand', 'Sky Blue', 'Off-White'],
        ),
        DashboardRecommendation(
          id: '$lower-m3',
          title: '$occasion Cargo Pants & Oversized Hoodie',
          occasion: occasion,
          category: 'Street Casual',
          mood: 'Urban & Comfortable',
          imageUrl: 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=400&q=80',
          outfit: 'Utility cargo pants, oversized graphic hoodie, chunky sneakers & cap',
          hairstyle: 'Cap on; natural underneath',
          explanation: 'Urban streetwear layering that keeps you comfortable and stylish all day.',
          palette: _paletteValuesForLabels(const ['Olive', 'Grey', 'Cream']),
          paletteLabels: const ['Olive', 'Grey', 'Cream'],
        ),
      ];
    }
    return [
      DashboardRecommendation(
        id: '$lower-1',
        title: '$occasion Straight Denim & Bodysuit',
        occasion: occasion,
        category: 'Casual',
        mood: 'Relaxed & Chic',
        imageUrl: 'https://images.unsplash.com/photo-1536243298747-ea8874136d64?w=400&q=80',
        outfit: 'High-waisted straight jeans, fitted ribbed bodysuit, lightweight trench coat & leather sneakers',
        hairstyle: 'Effortless top knot',
        explanation: 'A versatile, stylish outfit tailored for your $occasion plans.',
        palette: _paletteValuesForLabels(const ['Denim', 'Off-White', 'Camel']),
        paletteLabels: const ['Denim', 'Off-White', 'Camel'],
      ),
      DashboardRecommendation(
        id: '$lower-2',
        title: '$occasion Floral Linen Sundress',
        occasion: occasion,
        category: 'Summer Casual',
        mood: 'Fresh & Airy',
        imageUrl: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&q=80',
        outfit: 'Midi floral linen sundress, woven straw tote bag & leather slide sandals',
        hairstyle: 'Soft beachy waves',
        explanation: 'Breezy linen dress ideal for warm sunny days and casual outings.',
        palette: _paletteValuesForLabels(const ['Pastel Floral', 'Straw', 'White']),
        paletteLabels: const ['Pastel Floral', 'Straw', 'White'],
      ),
      DashboardRecommendation(
        id: '$lower-3',
        title: '$occasion Slouchy Knit & Satin Skirt',
        occasion: occasion,
        category: 'Elevated Casual',
        mood: 'Cozy Glam',
        imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&q=80',
        outfit: 'Oversized slouchy knit sweater, satin midi skirt & clean white leather sneakers',
        hairstyle: 'Messy low bun',
        explanation: 'A chic blend of cozy knit textures and sleek satin for daytime gatherings.',
        palette: _paletteValuesForLabels(const ['Cream', 'Sage', 'Gold']),
        paletteLabels: const ['Cream', 'Sage', 'Gold'],
      ),
    ];
  }

  DashboardRecommendation _generateRecommendation({
    required String occasion,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    String excludedCategory = '',
  }) {
    final list = _generateOccasionRecommendationsList(
      occasion,
      profileData,
      preferenceScores,
    );
    return list.first;
  }

  // Legacy cache migration data; live Discover content comes from the AI API.
  // ignore: unused_element
  List<DiscoverEntry> _discoverCatalog() {
    return const [
      DiscoverEntry(
        id: 'discover-1',
        title: 'Soft Tailoring',
        category: 'Trending',
        imageUrl: 'https://images.unsplash.com/photo-1548778943-5bbeeb1ba6c1?w=400&q=80',
        caption: 'Fluid neutrals with a polished silhouette.',
        height: 252,
      ),
      DiscoverEntry(
        id: 'discover-2',
        title: 'Cafe Casual',
        category: 'Casual',
        imageUrl: 'https://images.unsplash.com/photo-1542060748-10c28b62716f?w=400&q=80',
        caption: 'Easy layers and warm everyday tones.',
        height: 188,
      ),
      DiscoverEntry(
        id: 'discover-3',
        title: 'Modern Evening',
        category: 'Formal',
        imageUrl: 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?w=400&q=80',
        caption: 'Minimal glamour with clean lines.',
        height: 226,
      ),
      DiscoverEntry(
        id: 'discover-4',
        title: 'After Dark',
        category: 'Party',
        imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80',
        caption: 'Berry accents and sleek structure.',
        height: 210,
      ),
      DiscoverEntry(
        id: 'discover-5',
        title: 'Weekend Layers',
        category: 'Casual',
        imageUrl: 'https://images.unsplash.com/photo-1536243298747-ea8874136d64?w=400&q=80',
        caption: 'Relaxed pieces that still feel editorial.',
        height: 244,
      ),
      DiscoverEntry(
        id: 'discover-6',
        title: 'Editorial Neutrals',
        category: 'Trending',
        imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&q=80',
        caption: 'Soft pinks, stone, and cocoa tones.',
        height: 196,
      ),
      DiscoverEntry(
        id: 'discover-7',
        title: 'Street Essentials',
        category: 'Streetwear',
        imageUrl: 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=400&q=80',
        caption: 'Relaxed silhouettes with an elevated edge.',
        height: 212,
      ),
      DiscoverEntry(
        id: 'discover-8',
        title: 'Sport Luxe',
        category: 'Athleisure',
        imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&q=80',
        caption: 'Performance textures styled for the city.',
        height: 238,
      ),
      DiscoverEntry(
        id: 'discover-9',
        title: 'Vintage Denim',
        category: 'Vintage',
        imageUrl: 'https://images.unsplash.com/photo-1475180098004-ca77a66827be?w=400&q=80',
        caption: 'Classic washes and timeless layering.',
        height: 192,
      ),
      DiscoverEntry(
        id: 'discover-10',
        title: 'Monochrome Minimal',
        category: 'Minimal',
        imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&q=80',
        caption: 'Clean lines, quiet texture, sharp finish.',
        height: 224,
      ),
      DiscoverEntry(
        id: 'discover-11',
        title: 'Night Street',
        category: 'Streetwear',
        imageUrl: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400&q=80',
        caption: 'Dark layers and confident proportions.',
        height: 206,
      ),
      DiscoverEntry(
        id: 'discover-12',
        title: 'Off-Duty Set',
        category: 'Athleisure',
        imageUrl: 'https://images.unsplash.com/photo-1580913428023-02c695666d61?w=400&q=80',
        caption: 'Matching sets that look intentional.',
        height: 200,
      ),
      DiscoverEntry(
        id: 'discover-13',
        title: 'Retro Knit',
        category: 'Vintage',
        imageUrl: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&q=80',
        caption: 'Warm tones with a throwback mood.',
        height: 236,
      ),
      DiscoverEntry(
        id: 'discover-14',
        title: 'Soft Structure',
        category: 'Minimal',
        imageUrl: 'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=400&q=80',
        caption: 'Neutral palette with tailored restraint.',
        height: 188,
      ),
    ];
  }


  // Kept as a migration reference; sendChatMessage never uses local replies.
  // ignore: unused_element
  String _generateChatReply(String message) {
    final lower = message.toLowerCase();
    final recommendation = state.currentRecommendation;
    final profile = state.profileData;
    final palette = recommendation.paletteLabels;

    // Occasion-based responses
    if (lower.contains('wedding') || lower.contains('marriage')) {
      final responses = [
        'For a wedding, I\'d suggest a ${recommendation.category.toLowerCase()} foundation with ${palette.first.toLowerCase()} accents. Consider ${recommendation.outfit.toLowerCase()} for an elegant touch.',
        'Wedding attire should be refined. I\'d go with ${recommendation.category.toLowerCase()} pieces in ${palette.join(' and ')}, styled with ${recommendation.hairstyle.toLowerCase()} for a polished look.',
        'For a wedding guest look, try ${recommendation.outfit.toLowerCase()}. The ${palette.first.toLowerCase()} tones will complement your ${profile.skinTone.toLowerCase()} complexion beautifully.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('office') ||
        lower.contains('work') ||
        lower.contains('professional')) {
      final responses = [
        'For the office, I recommend ${recommendation.category.toLowerCase()} separates in ${palette.first.toLowerCase()} and ${palette[1].toLowerCase()}. ${recommendation.outfit.toLowerCase()} strikes the right professional balance.',
        'Workwear should be sharp yet comfortable. Try ${recommendation.category.toLowerCase()} pieces with ${recommendation.outfit.toLowerCase()} - perfect for your ${profile.styleMood.toLowerCase()} style.',
        'Professional style calls for ${recommendation.category.toLowerCase()} essentials. The ${palette.join(', ')} palette works beautifully for office settings.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('party') ||
        lower.contains('night out') ||
        lower.contains('club')) {
      final responses = [
        'For a party, go bold with ${recommendation.category.toLowerCase()} pieces in ${palette.first.toLowerCase()}. ${recommendation.outfit.toLowerCase()} will make you stand out.',
        'Night out calls for something striking. I\'d suggest ${recommendation.category.toLowerCase()} with ${recommendation.outfit.toLowerCase()} - perfect for making an impression.',
        'Party style should be fun! Try ${recommendation.category.toLowerCase()} in ${palette.join(' and ')}, styled with ${recommendation.hairstyle.toLowerCase()} for a complete look.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('date') || lower.contains('romantic')) {
      final responses = [
        'For a date, I\'d recommend ${recommendation.category.toLowerCase()} in ${palette.first.toLowerCase()}. ${recommendation.outfit.toLowerCase()} creates a romantic yet sophisticated vibe.',
        'Date night calls for something special. Try ${recommendation.category.toLowerCase()} pieces with ${recommendation.outfit.toLowerCase()} - perfect for your ${profile.styleMood.toLowerCase()} aesthetic.',
        'Romantic occasions deserve ${recommendation.category.toLowerCase()} elegance. The ${palette.join(', ')} tones will complement your ${profile.skinTone.toLowerCase()} skin tone beautifully.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    // Weather-based responses
    if (lower.contains('cold') ||
        lower.contains('winter') ||
        lower.contains('snow')) {
      final responses = [
        'For cold weather, layer ${recommendation.category.toLowerCase()} pieces in ${palette.first.toLowerCase()}. ${recommendation.outfit.toLowerCase()} provides warmth while staying stylish.',
        'Winter calls for cozy layers. I\'d suggest ${recommendation.category.toLowerCase()} with ${recommendation.outfit.toLowerCase()} - perfect for staying warm and fashionable.',
        'Cold weather styling: start with ${recommendation.category.toLowerCase()} basics in ${palette.join(' and ')}, then add layers as needed.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('hot') ||
        lower.contains('summer') ||
        lower.contains('warm')) {
      final responses = [
        'For hot weather, choose breathable ${recommendation.category.toLowerCase()} in ${palette.first.toLowerCase()}. ${recommendation.outfit.toLowerCase()} keeps you cool and stylish.',
        'Summer style should be light and airy. Try ${recommendation.category.toLowerCase()} pieces with ${recommendation.outfit.toLowerCase()} - perfect for warm days.',
        'Hot weather calls for ${recommendation.category.toLowerCase()} in ${palette.join(', ')}. Lightweight fabrics in these colors will keep you comfortable.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('rain') || lower.contains('rainy')) {
      final responses = [
        'For rainy days, opt for ${recommendation.category.toLowerCase()} in ${palette.first.toLowerCase()}. ${recommendation.outfit.toLowerCase()} works well with rain gear.',
        'Rainy day style: ${recommendation.category.toLowerCase()} pieces in ${palette.join(' and ')} paired with practical footwear.',
        'When it rains, choose ${recommendation.category.toLowerCase()} that can handle moisture. ${recommendation.outfit.toLowerCase()} is a great base.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('casual') || lower.contains('relaxed')) {
      final responses = [
        'For a casual look, try ${recommendation.category.toLowerCase()} in ${palette.first.toLowerCase()}. ${recommendation.outfit.toLowerCase()} is perfect for everyday wear.',
        'Casual style should be effortless. I\'d suggest ${recommendation.category.toLowerCase()} with ${recommendation.outfit.toLowerCase()} - ideal for your ${profile.styleMood.toLowerCase()} vibe.',
        'Relaxed occasions call for ${recommendation.category.toLowerCase()} in ${palette.join(' and ')}. Keep it simple and comfortable.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('formal') ||
        lower.contains('elegant') ||
        lower.contains('dressy')) {
      final responses = [
        'For formal events, choose ${recommendation.category.toLowerCase()} in ${palette.first.toLowerCase()}. ${recommendation.outfit.toLowerCase()} creates an elegant silhouette.',
        'Formal attire should be sophisticated. Try ${recommendation.category.toLowerCase()} pieces with ${recommendation.outfit.toLowerCase()} - perfect for dressing up.',
        'Elegant occasions call for ${recommendation.category.toLowerCase()} in ${palette.join(', ')}. These colors convey refinement and style.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('color') ||
        lower.contains('colour') ||
        lower.contains('palette')) {
      final responses = [
        'Based on your ${profile.skinTone.toLowerCase()} skin tone, ${palette.join(', ')} will look stunning on you.',
        'Your color palette should feature ${palette.join(', ')}. These complement your ${profile.bodyType.toLowerCase()} body type beautifully.',
        'I recommend building your wardrobe around ${palette.join(', ')}. These colors work perfectly with your ${profile.styleMood.toLowerCase()} style.',
        'For your complexion, ${palette.first.toLowerCase()} and ${palette[1].toLowerCase()} are particularly flattering. Consider ${palette[2].toLowerCase()} as an accent.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('hair') || lower.contains('hairstyle')) {
      final responses = [
        'I\'d pair this look with ${recommendation.hairstyle}. It complements your ${profile.faceShape.toLowerCase()} face shape perfectly.',
        'For your ${profile.faceShape.toLowerCase()} face shape, ${recommendation.hairstyle} works beautifully with this outfit.',
        'Hairstyle suggestion: ${recommendation.hairstyle}. This balances your ${profile.bodyType.toLowerCase()} body type and completes the look.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('body') ||
        lower.contains('fit') ||
        lower.contains('shape')) {
      final responses = [
        'For your ${profile.bodyType.toLowerCase()} body type, ${recommendation.category.toLowerCase()} pieces in ${palette.first.toLowerCase()} will be most flattering.',
        'Your ${profile.bodyType.toLowerCase()} shape looks great in ${recommendation.category.toLowerCase()}. Try ${recommendation.outfit.toLowerCase()} for a balanced silhouette.',
        'Body type styling: ${recommendation.category.toLowerCase()} in ${palette.join(' and ')} accentuates your best features.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('outfit') ||
        lower.contains('wear') ||
        lower.contains('look')) {
      final responses = [
        'I\'d suggest ${recommendation.outfit.toLowerCase()}. This ${recommendation.category.toLowerCase()} look suits your ${profile.styleMood.toLowerCase()} style perfectly.',
        'Try ${recommendation.outfit.toLowerCase()}. The ${palette.join(', ')} palette complements your ${profile.skinTone.toLowerCase()} complexion.',
        'For a complete look, go with ${recommendation.outfit.toLowerCase()}. Style it with ${recommendation.hairstyle} for a polished finish.',
        'This ${recommendation.category.toLowerCase()} outfit works well: ${recommendation.outfit.toLowerCase()}. Perfect for your ${profile.bodyType.toLowerCase()} body type.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    if (lower.contains('help') ||
        lower.contains('suggest') ||
        lower.contains('recommend')) {
      final responses = [
        'I can help with outfit suggestions! Tell me about the occasion (wedding, office, party, date), weather, or style preference you have in mind.',
        'Need style advice? I can suggest outfits for different occasions, weather conditions, or based on your body type and skin tone.',
        'I\'m here to help! Ask me about outfits for specific occasions, color recommendations, or styling tips for your body type.',
      ];
      return responses[_random.nextInt(responses.length)];
    }

    final defaultResponses = [
      'I\'d recommend a ${recommendation.category.toLowerCase()} approach with ${palette.first.toLowerCase()} accents. ${recommendation.outfit.toLowerCase()} suits your ${profile.styleMood.toLowerCase()} style.',
      'Based on your profile, try ${recommendation.category.toLowerCase()} in ${palette.join(' and ')}. ${recommendation.outfit.toLowerCase()} would look great on you.',
      'For your ${profile.skinTone.toLowerCase()} skin tone and ${profile.bodyType.toLowerCase()} body type, ${recommendation.category.toLowerCase()} pieces in ${palette.first.toLowerCase()} are ideal.',
      'I suggest ${recommendation.outfit.toLowerCase()}. This ${recommendation.category.toLowerCase()} look complements your ${profile.faceShape.toLowerCase()} face shape.',
      'Try building around ${recommendation.category.toLowerCase()} in ${palette.join(', ')}. ${recommendation.hairstyle} would complete the look perfectly.',
    ];

    return defaultResponses[_random.nextInt(defaultResponses.length)];
  }

  String _toTitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return value;
    }
    return trimmed
        .split(RegExp(r'\s+'))
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  List<String> _defaultPreferencesForTone(String skinTone) {
    final normalized = skinTone.toLowerCase();
    if (normalized.contains('warm')) {
      return ['Earthy', 'Minimal', 'Tailored'];
    }
    if (normalized.contains('olive')) {
      return ['Muted', 'Layered', 'Smart'];
    }
    if (normalized.contains('deep')) {
      return ['Bold', 'Refined', 'Evening'];
    }
    return ['Soft', 'Clean', 'Minimal'];
  }

  String _defaultMoodForTone(String skinTone) {
    final normalized = skinTone.toLowerCase();
    if (normalized.contains('warm')) {
      return 'Warm editorial';
    }
    if (normalized.contains('olive')) {
      return 'Soft luxe';
    }
    if (normalized.contains('deep')) {
      return 'Confident elevated';
    }
    return 'Polished minimal';
  }

  String _id(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(9999)}';
  }

  Future<void> _syncWardrobeWithBackend() async {
    try {
      await _dashboardHome.syncWardrobe(state.wardrobeItems);
    } catch (_) {
      // Keep local state when backend sync is unavailable.
    }
  }
}
