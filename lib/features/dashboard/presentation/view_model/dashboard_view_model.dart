import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/read_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/persist_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/upload_item_photo_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/get_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/save_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/presentation/providers/silhouette_profile_providers.dart';

class DashboardViewModel extends Notifier<DashboardState> {
  late final UserSessionService _userSessionService;
  late final GetSilhouetteProfileUsecase _getSilhouetteProfileUsecase;
  late final SaveSilhouetteProfileUsecase _saveSilhouetteProfileUsecase;
  late final ReadDashboardStateUsecase _readDashboardStateUsecase;
  late final PersistDashboardStateUsecase _persistDashboardStateUsecase;
  late final UploadItemPhotoUsecase _uploadItemPhotoUsecase;
  final ImagePicker _imagePicker = ImagePicker();
  final Random _random = Random();
  bool _usedPersistedProfileData = false;

  @override
  DashboardState build() {
    _userSessionService = ref.read(userSessionServiceProvider);
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

    final initial = _buildStateFromCache(const <String, dynamic>{});
    Future.microtask(_initialize);
    return initial;
  }

  Future<void> _initialize() async {
    final sessionUser = _userSessionService.getCurrentUser();
    final cachedResult = await _readDashboardStateUsecase();
    cachedResult.fold((_) {}, (cachedData) {
      if (cachedData.isNotEmpty) {
        state = _buildStateFromCache(cachedData);
      }
    });

    // Always refresh profile data from current session user
    if (sessionUser != null) {
      await _refreshProfileFromSession();
    }

    await _hydrateFromSilhouetteIfNeeded();
  }

  Future<void> _refreshProfileFromSession() async {
    final sessionUser = _userSessionService.getCurrentUser();
    if (sessionUser == null) {
      return;
    }

    final fullName = [
      sessionUser.firstName,
      sessionUser.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();

    final updatedProfile = state.profileData.copyWith(
      displayName: fullName.isEmpty ? 'User' : fullName,
      email: sessionUser.email,
    );

    state = state.copyWith(profileData: updatedProfile);
    await _persistState();
  }

  Future<void> refreshFromSession() async {
    await _refreshProfileFromSession();
  }

  Future<void> clearCacheAndRefresh() async {
    await _persistDashboardStateUsecase(
      PersistDashboardStateParams(payload: const {}),
    );

    final sessionUser = _userSessionService.getCurrentUser();
    if (sessionUser != null) {
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
    final sessionUser = _userSessionService.getCurrentUser();
    final profileData = _buildProfileData(
      rawProfile: cachedData['profileData'] as Map<String, dynamic>?,
      silhouette: null,
      sessionUser: sessionUser,
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

      final sessionUser = _userSessionService.getCurrentUser();
      final profileData = _buildProfileData(
        rawProfile: null,
        silhouette: silhouette,
        sessionUser: sessionUser,
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
    };
    await _persistDashboardStateUsecase(
      PersistDashboardStateParams(payload: payload),
    );
  }

  DashboardProfileData _buildProfileData({
    required Map<String, dynamic>? rawProfile,
    required SilhouetteProfile? silhouette,
    required SessionUser? sessionUser,
  }) {
    final fullName = [
      sessionUser?.firstName ?? '',
      sessionUser?.lastName ?? '',
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

    return DashboardProfileData(
      displayName: fullName.isEmpty ? 'User' : fullName,
      email: sessionUser?.email ?? (rawProfile?['email']?.toString() ?? ''),
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

    await Future.delayed(const Duration(milliseconds: 1800));
    final recommendation = _generateRecommendation(
      occasion: occasion ?? state.aiStyleOfDay.occasion,
      profileData: state.profileData,
      preferenceScores: state.stylePreferenceScores,
      excludedCategory: '',
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

  Future<DashboardRecommendation> generateFreshHomeRecommendation() async {
    final occasions = ['Wedding', 'Office', 'Party', 'Travel', 'Weekend'];
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

    await Future.delayed(const Duration(milliseconds: 1400));

    final recommendation = _generateRecommendation(
      occasion: nextOccasion,
      profileData: state.profileData,
      preferenceScores: state.stylePreferenceScores,
      excludedCategory: state.aiStyleOfDay.category,
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

  void addWardrobeItem(String title, String category, {String imagePath = ''}) {
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
    state = state.copyWith(wardrobeItems: [newItem, ...state.wardrobeItems]);
    _persistState();
  }

  void addCustomOutfit({
    required String title,
    required String category,
    required String imagePath,
    String outfit = '',
    String hairstyle = '',
    String explanation = '',
    List<String> paletteLabels = const [],
  }) {
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
    _persistState();
  }

  void addLookFromCloset(List<WardrobeEntry> items, {bool favorite = false}) {
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
    _persistState();
  }

  void toggleWardrobeFavorite(WardrobeEntry item) {
    state = state.copyWith(
      wardrobeItems: state.wardrobeItems
          .map(
            (e) => e.id == item.id ? e.copyWith(isFavorite: !e.isFavorite) : e,
          )
          .toList(),
    );
    _persistState();
  }

  void removeWardrobeItem(WardrobeEntry item) {
    state = state.copyWith(
      wardrobeItems: state.wardrobeItems.where((i) => i.id != item.id).toList(),
    );
    _persistState();
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
  }

  Future<bool> uploadSelectedImage() async {
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

    final recommendation = _generateRecommendation(
      occasion: state.currentRecommendation.occasion,
      profileData: state.profileData,
      preferenceScores: state.stylePreferenceScores,
    );

    state = state.copyWith(
      isUploading: false,
      uploadProgress: 1.0,
      uploadSucceeded: true,
      hasCompletedStyleAnalysis: true,
      currentRecommendation: recommendation,
      aiStyleOfDay: recommendation,
      aiProcessingMessage: 'Recommendation ready.',
      uploadMessage: 'AI style analysis complete.',
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
    await Future.delayed(const Duration(seconds: 2));

    final recommendation = _generateRecommendation(
      occasion: state.currentRecommendation.occasion,
      profileData: state.profileData,
      preferenceScores: state.stylePreferenceScores,
      excludedCategory: state.currentRecommendation.category,
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

  Future<void> sendChatMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || state.isChatTyping) {
      return;
    }

    final nextMessages = [
      ...state.chatMessages,
      ChatMessage(id: _id('chat-user'), text: trimmed, isUser: true),
    ];
    state = state.copyWith(chatMessages: nextMessages, isChatTyping: true);

    await Future.delayed(const Duration(milliseconds: 1200));
    final reply = _generateChatReply(trimmed);
    state = state.copyWith(
      chatMessages: [
        ...nextMessages,
        ChatMessage(id: _id('chat-ai'), text: reply, isUser: false),
      ],
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
    final occasions = ['Wedding', 'Office', 'Party', 'Travel', 'Weekend'];
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
      'Wedding' => ['Formal', 'Party', 'Elegant'],
      'Office' => ['Formal', 'Casual', 'Smart'],
      'Party' => ['Party', 'Bold', 'Formal'],
      'Travel' => ['Casual', 'Smart', 'Relaxed'],
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
      'Wedding-Formal' =>
        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80',
      'Office-Formal' =>
        'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?auto=format&fit=crop&w=900&q=80',
      'Party-Party' =>
        'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=900&q=80',
      'Travel-Casual' =>
        'https://images.unsplash.com/photo-1523398002811-999ca8dec234?auto=format&fit=crop&w=900&q=80',
      _ =>
        'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
    };
  }

  List<DiscoverEntry> _discoverCatalog() {
    return const [
      DiscoverEntry(
        id: 'discover-1',
        title: 'Soft Tailoring',
        category: 'Trending',
        imageUrl:
            'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=80',
        caption: 'Fluid neutrals with a polished silhouette.',
        height: 252,
      ),
      DiscoverEntry(
        id: 'discover-2',
        title: 'Cafe Casual',
        category: 'Casual',
        imageUrl:
            'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80',
        caption: 'Easy layers and warm everyday tones.',
        height: 188,
      ),
      DiscoverEntry(
        id: 'discover-3',
        title: 'Modern Evening',
        category: 'Formal',
        imageUrl:
            'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=900&q=80',
        caption: 'Minimal glamour with clean lines.',
        height: 226,
      ),
      DiscoverEntry(
        id: 'discover-4',
        title: 'After Dark',
        category: 'Party',
        imageUrl:
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80',
        caption: 'Berry accents and sleek structure.',
        height: 210,
      ),
      DiscoverEntry(
        id: 'discover-5',
        title: 'Weekend Layers',
        category: 'Casual',
        imageUrl:
            'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=900&q=80',
        caption: 'Relaxed pieces that still feel editorial.',
        height: 244,
      ),
      DiscoverEntry(
        id: 'discover-6',
        title: 'Editorial Neutrals',
        category: 'Trending',
        imageUrl:
            'https://images.unsplash.com/photo-1551232864-3f0890e580d9?auto=format&fit=crop&w=900&q=80',
        caption: 'Soft pinks, stone, and cocoa tones.',
        height: 196,
      ),
      DiscoverEntry(
        id: 'discover-7',
        title: 'Street Essentials',
        category: 'Streetwear',
        imageUrl:
            'https://images.unsplash.com/photo-1520975958225-7a20f1b2d6c2?auto=format&fit=crop&w=900&q=80',
        caption: 'Relaxed silhouettes with an elevated edge.',
        height: 212,
      ),
      DiscoverEntry(
        id: 'discover-8',
        title: 'Sport Luxe',
        category: 'Athleisure',
        imageUrl:
            'https://images.unsplash.com/photo-1526401485004-2aa7f3b14dd6?auto=format&fit=crop&w=900&q=80',
        caption: 'Performance textures styled for the city.',
        height: 238,
      ),
      DiscoverEntry(
        id: 'discover-9',
        title: 'Vintage Denim',
        category: 'Vintage',
        imageUrl:
            'https://images.unsplash.com/photo-1520975661595-6453be3f7070?auto=format&fit=crop&w=900&q=80',
        caption: 'Classic washes and timeless layering.',
        height: 192,
      ),
      DiscoverEntry(
        id: 'discover-10',
        title: 'Monochrome Minimal',
        category: 'Minimal',
        imageUrl:
            'https://images.unsplash.com/photo-1520975682071-ae4f62bb3f7a?auto=format&fit=crop&w=900&q=80',
        caption: 'Clean lines, quiet texture, sharp finish.',
        height: 224,
      ),
      DiscoverEntry(
        id: 'discover-11',
        title: 'Night Street',
        category: 'Streetwear',
        imageUrl:
            'https://images.unsplash.com/photo-1520975911319-6d9c0dce2740?auto=format&fit=crop&w=900&q=80',
        caption: 'Dark layers and confident proportions.',
        height: 206,
      ),
      DiscoverEntry(
        id: 'discover-12',
        title: 'Off-Duty Set',
        category: 'Athleisure',
        imageUrl:
            'https://images.unsplash.com/photo-1526401485002-2c5bf7c51240?auto=format&fit=crop&w=900&q=80',
        caption: 'Matching sets that look intentional.',
        height: 200,
      ),
      DiscoverEntry(
        id: 'discover-13',
        title: 'Retro Knit',
        category: 'Vintage',
        imageUrl:
            'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=900&q=80',
        caption: 'Warm tones with a throwback mood.',
        height: 236,
      ),
      DiscoverEntry(
        id: 'discover-14',
        title: 'Soft Structure',
        category: 'Minimal',
        imageUrl:
            'https://images.unsplash.com/photo-1520975867549-4b7d2b2d2e86?auto=format&fit=crop&w=900&q=80',
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
}
