import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_home_repository.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/read_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/persist_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/upload_item_photo_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/get_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/save_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/presentation/providers/silhouette_profile_providers.dart';

class DashboardViewModel extends Notifier<DashboardState> {
  late final GetCurrentUserUsecase _getCurrentUserUsecase;
  late final GetSilhouetteProfileUsecase _getSilhouetteProfileUsecase;
  late final SaveSilhouetteProfileUsecase _saveSilhouetteProfileUsecase;
  late final ReadDashboardStateUsecase _readDashboardStateUsecase;
  late final PersistDashboardStateUsecase _persistDashboardStateUsecase;
  late final UploadItemPhotoUsecase _uploadItemPhotoUsecase;
  late final IDashboardHomeRepository _dashboardHomeRepository;
  final ImagePicker _imagePicker = ImagePicker();
  final Random _random = Random();
  AuthEntity? _currentUser;
  bool _usedPersistedProfileData = false;

  @override
  DashboardState build() {
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
    _dashboardHomeRepository = ref.read(dashboardHomeRepositoryProvider);

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
      final recommendation = await _dashboardHomeRepository.generateOutfit(
        occasion: state.aiStyleOfDay.occasion,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
      );
      final trends = await _dashboardHomeRepository.fetchTrends();
      final refreshedList = [
        recommendation,
        ...state.homeRecommendations.where(
          (item) => item.id != recommendation.id,
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
      final remoteItems = await _dashboardHomeRepository.fetchWardrobe();
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

    final discoverItems = _discoverCatalog();
    final homeRecommendations = _generateHomeRecommendations(
      profileData,
      preferenceScores,
    );
    final aiStyleOfDay = cachedData['aiStyleOfDay'] is Map<String, dynamic>
        ? DashboardRecommendation.fromJson(
            Map<String, dynamic>.from(cachedData['aiStyleOfDay'] as Map),
          )
        : homeRecommendations.first;
    final currentRecommendation =
        cachedData['currentRecommendation'] is Map<String, dynamic>
        ? DashboardRecommendation.fromJson(
            Map<String, dynamic>.from(
              cachedData['currentRecommendation'] as Map,
            ),
          )
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
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
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
    final recommendation = await _generateRecommendationFromBackend(
      occasion: selectedOccasion,
      source: source,
      fallback: () => _generateRecommendation(
        occasion: selectedOccasion,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        excludedCategory: '',
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
      currentRecommendation: syncCurrentRecommendation
          ? recommendation
          : state.currentRecommendation,
      homeRecommendations: refreshedList,
      uploadSucceeded: true,
      aiProcessingMessage: 'Style board updated.',
      uploadMessage: 'AI refreshed your style recommendation.',
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

    try {
      final result = await _dashboardHomeRepository.search(
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

      state = state.copyWith(
        currentIndex: 4,
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
      final lower = trimmed.toLowerCase();
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

      state = state.copyWith(
        currentIndex: localWardrobe.isNotEmpty ? 2 : 4,
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
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
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
      await _dashboardHomeRepository.createWardrobeItem(newItem);
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
      await _dashboardHomeRepository.createWardrobeItem(newItem);
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
      await _dashboardHomeRepository.createWardrobeItem(newLook);
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
      await _dashboardHomeRepository.updateWardrobeItem(updatedItem);
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
      await _dashboardHomeRepository.updateWardrobeItem(updatedItem);
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
      await _dashboardHomeRepository.deleteWardrobeItem(item.id);
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
      await _dashboardHomeRepository.createWardrobeItem(newItem);
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
      final analysis = await _dashboardHomeRepository.generateProfile(
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

    try {
      final response = await _dashboardHomeRepository.chatWithAssistant(
        message: trimmed,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        source: source,
        currentRecommendation: state.currentRecommendation,
      );
      reply =
          (response['reply'] is String &&
              (response['reply'] as String).trim().isNotEmpty)
          ? (response['reply'] as String).trim()
          : _generateChatReply(trimmed);

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
      await Future.delayed(const Duration(milliseconds: 800));
      reply = _generateChatReply(trimmed);
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
      isChatTyping: false,
    );
    await _persistState();
  }

  Future<void> updateProfileData(
    DashboardProfileData profileData, {
    bool persistSilhouette = true,
  }) async {
    state = state.copyWith(
      profileData: profileData,
      aiStyleOfDay: _generateRecommendation(
        occasion: state.aiStyleOfDay.occasion,
        profileData: profileData,
        preferenceScores: state.stylePreferenceScores,
      ),
      currentRecommendation: _generateRecommendation(
        occasion: state.currentRecommendation.occasion,
        profileData: profileData,
        preferenceScores: state.stylePreferenceScores,
      ),
      homeRecommendations: _generateHomeRecommendations(
        profileData,
        state.stylePreferenceScores,
      ),
    );

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
        ref.invalidate(silhouetteProfileProvider);
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

  List<DashboardRecommendation> _generateHomeRecommendations(
    DashboardProfileData profileData,
    Map<String, int> preferenceScores,
  ) {
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
    return occasions
        .map(
          (occasion) => _generateRecommendation(
            occasion: occasion,
            profileData: profileData,
            preferenceScores: preferenceScores,
          ),
        )
        .toList();
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
      return await _dashboardHomeRepository.generateOutfit(
        occasion: occasion,
        profileData: state.profileData,
        preferenceScores: state.stylePreferenceScores,
        source: source,
        imageReference: imageReference,
      );
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 600));
      return fallback();
    }
  }

  DashboardRecommendation _generateRecommendation({
    required String occasion,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    String excludedCategory = '',
  }) {
    final category = _selectCategory(
      occasion: occasion,
      preferenceScores: preferenceScores,
      excludedCategory: excludedCategory,
    );
    final palette = _paletteFor(profileData.skinTone, category);
    final hairstyle = _hairstyleFor(profileData.faceShape, category);
    final outfit = _outfitFor(occasion, category, profileData.styleMood);
    final image = _imageFor(occasion, category);
    final explanation = _explanationFor(
      profileData: profileData,
      category: category,
      paletteLabels: palette.$2,
      hairstyle: hairstyle,
    );

    return DashboardRecommendation(
      id: _id('rec'),
      title: '$occasion ${_displayCategory(category)} Edit',
      occasion: occasion,
      category: category,
      mood: profileData.styleMood,
      imageUrl: image,
      outfit: outfit,
      hairstyle: hairstyle,
      explanation: explanation,
      palette: palette.$1,
      paletteLabels: palette.$2,
    );
  }

  String _selectCategory({
    required String occasion,
    required Map<String, int> preferenceScores,
    required String excludedCategory,
  }) {
    final candidates = switch (occasion) {
      'Wedding' || 'Sangeet' => ['Formal', 'Party', 'Elegant'],
      'Office' => ['Formal', 'Casual', 'Smart'],
      'Party' || 'Gala' || 'Black Tie' => ['Party', 'Bold', 'Formal'],
      'Travel' ||
      'Street Style' ||
      'Beach' ||
      'Brunch' ||
      'Casual' => ['Casual', 'Smart', 'Relaxed'],
      _ => ['Casual', 'Smart', 'Relaxed'],
    };

    final filtered = candidates
        .where((item) => item.toLowerCase() != excludedCategory.toLowerCase())
        .toList();
    if (filtered.isEmpty) {
      return candidates.first;
    }

    filtered.sort(
      (a, b) => (preferenceScores[b] ?? 0).compareTo(preferenceScores[a] ?? 0),
    );
    if ((preferenceScores[filtered.first] ?? 0) > 0 && _random.nextBool()) {
      return filtered.first;
    }
    return filtered[_random.nextInt(filtered.length)];
  }

  (List<int>, List<String>) _paletteFor(String skinTone, String category) {
    final normalized = skinTone.toLowerCase();
    if (normalized.contains('warm')) {
      return (
        [
          0xFFB86F52,
          0xFFD7B38C,
          0xFF6E7B56,
          category == 'Party' ? 0xFF7C2946 : 0xFF4A3A34,
        ],
        [
          'Terracotta',
          'Sand',
          'Olive',
          category == 'Party' ? 'Berry' : 'Cocoa',
        ],
      );
    }
    if (normalized.contains('olive')) {
      return (
        [0xFF8A6A4A, 0xFFCFC1A8, 0xFF556B5D, 0xFF3A3440],
        ['Camel', 'Stone', 'Sage', 'Espresso'],
      );
    }
    if (normalized.contains('deep')) {
      return (
        [0xFF4F2F4F, 0xFFB07AA1, 0xFFE6D9C8, 0xFF6B3D2E],
        ['Plum', 'Mauve', 'Ivory', 'Cedar'],
      );
    }
    return (
      [0xFFD9B7C3, 0xFFF2E8E5, 0xFF9AA7B1, 0xFF5D506A],
      ['Dusty Pink', 'Porcelain', 'Slate', 'Mulberry'],
    );
  }

  String _hairstyleFor(String faceShape, String category) {
    final normalized = faceShape.toLowerCase();
    if (normalized.contains('round')) {
      return 'Layered volume with a soft side part to elongate the face shape.';
    }
    if (normalized.contains('square')) {
      return 'Soft textured layers to balance strong angles and keep the look polished.';
    }
    if (normalized.contains('heart')) {
      return 'Face-framing layers with light movement around the jawline.';
    }
    return category == 'Party'
        ? 'Sleek brushed-back texture for a confident evening finish.'
        : 'Clean layered styling with natural movement and easy structure.';
  }

  String _outfitFor(String occasion, String category, String mood) {
    return switch (occasion) {
      'Wedding' =>
        'Cream tailored shirt, fluid trousers, tonal loafers, and subtle jewelry for a $mood finish.',
      'Office' =>
        'Structured blazer, soft knit base, tapered trousers, and clean leather shoes for a sharp ${category.toLowerCase()} office edit.',
      'Party' =>
        'Dark statement layer, elevated trousers, sleek footwear, and a refined accent piece for a standout evening look.',
      'Travel' =>
        'Relaxed overshirt, breathable tee, easy trousers, and supportive sneakers for polished movement.',
      _ =>
        'Relaxed top layer, dependable basics, and a clean finishing piece for an effortless day look.',
    };
  }

  String _explanationFor({
    required DashboardProfileData profileData,
    required String category,
    required List<String> paletteLabels,
    required String hairstyle,
  }) {
    final toneHint = profileData.skinTone.toLowerCase().contains('warm')
        ? 'earthy tones'
        : '${paletteLabels.first} and ${paletteLabels[1]}';
    return 'This recommendation leans into $toneHint for ${profileData.skinTone.toLowerCase()} skin, keeps the outfit in a ${category.toLowerCase()} direction, and pairs it with ${hairstyle.split('.').first.toLowerCase()}.';
  }

  String _imageFor(String occasion, String category) {
    final key = '$occasion-$category';
    return switch (key) {
      'Wedding-Formal' => 'assets/images/ai_wedding_formal.jpg',
      'Office-Formal' => 'assets/images/outfit.jpg',
      'Party-Party' => 'assets/images/party.jpg',
      'Travel-Casual' => 'assets/images/travel.jpg',
      _ => 'assets/images/weekend.jpg',
    };
  }

  List<DiscoverEntry> _discoverCatalog() {
    return const [
      DiscoverEntry(
        id: 'discover-1',
        title: 'Soft Tailoring',
        category: 'Trending',
        imageUrl: 'assets/images/ai_wedding_formal.jpg',
        caption: 'Fluid neutrals with a polished silhouette.',
        height: 252,
      ),
      DiscoverEntry(
        id: 'discover-2',
        title: 'Cafe Casual',
        category: 'Casual',
        imageUrl: 'assets/images/brunch.jpg',
        caption: 'Easy layers and warm everyday tones.',
        height: 188,
      ),
      DiscoverEntry(
        id: 'discover-3',
        title: 'Modern Evening',
        category: 'Formal',
        imageUrl: 'assets/images/wedding.jpg',
        caption: 'Minimal glamour with clean lines.',
        height: 226,
      ),
      DiscoverEntry(
        id: 'discover-4',
        title: 'After Dark',
        category: 'Party',
        imageUrl: 'assets/images/party.jpg',
        caption: 'Berry accents and sleek structure.',
        height: 210,
      ),
      DiscoverEntry(
        id: 'discover-5',
        title: 'Weekend Layers',
        category: 'Casual',
        imageUrl: 'assets/images/weekend.jpg',
        caption: 'Relaxed pieces that still feel editorial.',
        height: 244,
      ),
      DiscoverEntry(
        id: 'discover-6',
        title: 'Editorial Neutrals',
        category: 'Trending',
        imageUrl: 'assets/images/outfit.jpg',
        caption: 'Soft pinks, stone, and cocoa tones.',
        height: 196,
      ),
      DiscoverEntry(
        id: 'discover-7',
        title: 'Street Essentials',
        category: 'Streetwear',
        imageUrl: 'assets/images/travel.jpg',
        caption: 'Relaxed silhouettes with an elevated edge.',
        height: 212,
      ),
      DiscoverEntry(
        id: 'discover-8',
        title: 'Sport Luxe',
        category: 'Athleisure',
        imageUrl: 'assets/images/weekend.jpg',
        caption: 'Performance textures styled for the city.',
        height: 238,
      ),
      DiscoverEntry(
        id: 'discover-9',
        title: 'Vintage Denim',
        category: 'Vintage',
        imageUrl: 'assets/images/outfit.jpg',
        caption: 'Classic washes and timeless layering.',
        height: 192,
      ),
      DiscoverEntry(
        id: 'discover-10',
        title: 'Monochrome Minimal',
        category: 'Minimal',
        imageUrl: 'assets/images/ai_wedding_formal.jpg',
        caption: 'Clean lines, quiet texture, sharp finish.',
        height: 224,
      ),
      DiscoverEntry(
        id: 'discover-11',
        title: 'Night Street',
        category: 'Streetwear',
        imageUrl: 'assets/images/party.jpg',
        caption: 'Dark layers and confident proportions.',
        height: 206,
      ),
      DiscoverEntry(
        id: 'discover-12',
        title: 'Off-Duty Set',
        category: 'Athleisure',
        imageUrl: 'assets/images/travel.jpg',
        caption: 'Matching sets that look intentional.',
        height: 200,
      ),
      DiscoverEntry(
        id: 'discover-13',
        title: 'Retro Knit',
        category: 'Vintage',
        imageUrl: 'assets/images/brunch.jpg',
        caption: 'Warm tones with a throwback mood.',
        height: 236,
      ),
      DiscoverEntry(
        id: 'discover-14',
        title: 'Soft Structure',
        category: 'Minimal',
        imageUrl: 'assets/images/wedding.jpg',
        caption: 'Neutral palette with tailored restraint.',
        height: 188,
      ),
    ];
  }

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

  String _displayCategory(String category) {
    return category == 'Smart' || category == 'Elegant' || category == 'Bold'
        ? category
        : _toTitleCase(category);
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
      await _dashboardHomeRepository.syncWardrobe(state.wardrobeItems);
    } catch (_) {
      // Keep local state when backend sync is unavailable.
    }
  }
}
