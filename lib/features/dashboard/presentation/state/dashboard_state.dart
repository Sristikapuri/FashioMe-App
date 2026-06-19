import 'package:equatable/equatable.dart';

class DashboardRecommendation extends Equatable {
  const DashboardRecommendation({
    required this.id,
    required this.title,
    required this.occasion,
    required this.category,
    required this.mood,
    required this.imageUrl,
    required this.outfit,
    required this.hairstyle,
    required this.explanation,
    required this.palette,
    required this.paletteLabels,
  });

  final String id;
  final String title;
  final String occasion;
  final String category;
  final String mood;
  final String imageUrl;
  final String outfit;
  final String hairstyle;
  final String explanation;
  final List<int> palette;
  final List<String> paletteLabels;

  factory DashboardRecommendation.fromJson(Map<String, dynamic> json) {
    return DashboardRecommendation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      occasion: (json['occasion'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      mood: (json['mood'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      outfit: (json['outfit'] ?? '').toString(),
      hairstyle: (json['hairstyle'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      palette: List<int>.from(json['palette'] ?? const []),
      paletteLabels: List<String>.from(json['paletteLabels'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'occasion': occasion,
      'category': category,
      'mood': mood,
      'imageUrl': imageUrl,
      'outfit': outfit,
      'hairstyle': hairstyle,
      'explanation': explanation,
      'palette': palette,
      'paletteLabels': paletteLabels,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    occasion,
    category,
    mood,
    imageUrl,
    outfit,
    hairstyle,
    explanation,
    palette,
    paletteLabels,
  ];
}

class WardrobeEntry extends Equatable {
  const WardrobeEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.tag,
    required this.imageUrl,
    required this.outfit,
    required this.hairstyle,
    required this.explanation,
    required this.palette,
    required this.paletteLabels,
    required this.savedAt,
    this.isFavorite = false,
    this.entryType = 'look',
  });

  final String id;
  final String title;
  final String category;
  final String tag;
  final String imageUrl;
  final String outfit;
  final String hairstyle;
  final String explanation;
  final List<int> palette;
  final List<String> paletteLabels;
  final DateTime savedAt;
  final bool isFavorite;
  final String entryType;

  WardrobeEntry copyWith({bool? isFavorite, DateTime? savedAt}) {
    return WardrobeEntry(
      id: id,
      title: title,
      category: category,
      tag: tag,
      imageUrl: imageUrl,
      outfit: outfit,
      hairstyle: hairstyle,
      explanation: explanation,
      palette: palette,
      paletteLabels: paletteLabels,
      savedAt: savedAt ?? this.savedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      entryType: entryType,
    );
  }

  factory WardrobeEntry.fromRecommendation(
    DashboardRecommendation recommendation,
  ) {
    return WardrobeEntry(
      id: recommendation.id,
      title: recommendation.title,
      category: recommendation.category,
      tag: recommendation.occasion,
      imageUrl: recommendation.imageUrl,
      outfit: recommendation.outfit,
      hairstyle: recommendation.hairstyle,
      explanation: recommendation.explanation,
      palette: recommendation.palette,
      paletteLabels: recommendation.paletteLabels,
      savedAt: DateTime.now(),
      entryType: 'look',
    );
  }

  factory WardrobeEntry.fromJson(Map<String, dynamic> json) {
    final outfit = (json['outfit'] ?? '').toString();
    final hairstyle = (json['hairstyle'] ?? '').toString();
    final explanation = (json['explanation'] ?? '').toString();
    final palette = List<int>.from(json['palette'] ?? const []);
    final paletteLabels = List<String>.from(json['paletteLabels'] ?? const []);
    final savedAt = DateTime.tryParse((json['savedAt'] ?? '').toString());
    final inferredEntryType =
        outfit.isNotEmpty ||
            hairstyle.isNotEmpty ||
            explanation.isNotEmpty ||
            palette.isNotEmpty
        ? 'look'
        : 'clothes';

    return WardrobeEntry(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      tag: (json['tag'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      outfit: outfit,
      hairstyle: hairstyle,
      explanation: explanation,
      palette: palette,
      paletteLabels: paletteLabels,
      savedAt: savedAt ?? DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      entryType: (json['entryType'] ?? inferredEntryType).toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'tag': tag,
      'imageUrl': imageUrl,
      'outfit': outfit,
      'hairstyle': hairstyle,
      'explanation': explanation,
      'palette': palette,
      'paletteLabels': paletteLabels,
      'savedAt': savedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'entryType': entryType,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    tag,
    imageUrl,
    outfit,
    hairstyle,
    explanation,
    palette,
    paletteLabels,
    savedAt,
    isFavorite,
    entryType,
  ];
}

class DiscoverEntry extends Equatable {
  const DiscoverEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.caption,
    required this.height,
  });

  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String caption;
  final double height;

  @override
  List<Object?> get props => [id, title, category, imageUrl, caption, height];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
  });

  final String id;
  final String text;
  final bool isUser;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      isUser: json['isUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isUser': isUser};
  }

  @override
  List<Object?> get props => [id, text, isUser];
}

class DashboardProfileData extends Equatable {
  const DashboardProfileData({
    required this.displayName,
    required this.email,
    required this.styleMood,
    required this.stylePreferences,
    required this.skinTone,
    required this.bodyType,
    required this.faceShape,
    required this.themePreference,
    required this.notificationsEnabled,
    required this.language,
  });

  final String displayName;
  final String email;
  final String styleMood;
  final List<String> stylePreferences;
  final String skinTone;
  final String bodyType;
  final String faceShape;
  final String themePreference;
  final bool notificationsEnabled;
  final String language;

  factory DashboardProfileData.empty() {
    return const DashboardProfileData(
      displayName: 'User',
      email: '',
      styleMood: 'Polished minimal',
      stylePreferences: ['Minimal', 'Neutral', 'Tailored'],
      skinTone: 'Warm',
      bodyType: 'Balanced',
      faceShape: 'Oval',
      themePreference: 'System',
      notificationsEnabled: true,
      language: 'English',
    );
  }

  factory DashboardProfileData.fromJson(Map<String, dynamic> json) {
    return DashboardProfileData(
      displayName: (json['displayName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      styleMood: (json['styleMood'] ?? '').toString(),
      stylePreferences: List<String>.from(json['stylePreferences'] ?? const []),
      skinTone: (json['skinTone'] ?? '').toString(),
      bodyType: (json['bodyType'] ?? '').toString(),
      faceShape: (json['faceShape'] ?? '').toString(),
      themePreference: (json['themePreference'] ?? 'System').toString(),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      language: (json['language'] ?? 'English').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'styleMood': styleMood,
      'stylePreferences': stylePreferences,
      'skinTone': skinTone,
      'bodyType': bodyType,
      'faceShape': faceShape,
      'themePreference': themePreference,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
    };
  }

  DashboardProfileData copyWith({
    String? displayName,
    String? email,
    String? styleMood,
    List<String>? stylePreferences,
    String? skinTone,
    String? bodyType,
    String? faceShape,
    String? themePreference,
    bool? notificationsEnabled,
    String? language,
  }) {
    return DashboardProfileData(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      styleMood: styleMood ?? this.styleMood,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      skinTone: skinTone ?? this.skinTone,
      bodyType: bodyType ?? this.bodyType,
      faceShape: faceShape ?? this.faceShape,
      themePreference: themePreference ?? this.themePreference,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    email,
    styleMood,
    stylePreferences,
    skinTone,
    bodyType,
    faceShape,
    themePreference,
    notificationsEnabled,
    language,
  ];
}

class DashboardState extends Equatable {
  final int currentIndex;
  final String? selectedImagePath;
  final String? uploadedAssetName;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadMessage;
  final bool uploadSucceeded;
  final bool hasCompletedStyleAnalysis;
  final String aiProcessingMessage;
  final DashboardRecommendation aiStyleOfDay;
  final DashboardRecommendation currentRecommendation;
  final List<DashboardRecommendation> homeRecommendations;
  final List<WardrobeEntry> wardrobeItems;
  final List<DiscoverEntry> discoverItems;
  final String wardrobeFilter;
  final String discoverFilter;
  final int preferenceScore;
  final Map<String, int> stylePreferenceScores;
  final List<ChatMessage> chatMessages;
  final bool isChatTyping;
  final DashboardProfileData profileData;

  const DashboardState({
    this.currentIndex = 0,
    this.selectedImagePath,
    this.uploadedAssetName,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.uploadMessage,
    this.uploadSucceeded = false,
    this.hasCompletedStyleAnalysis = false,
    required this.aiProcessingMessage,
    required this.aiStyleOfDay,
    required this.currentRecommendation,
    required this.homeRecommendations,
    required this.wardrobeItems,
    required this.discoverItems,
    this.wardrobeFilter = 'All',
    this.discoverFilter = 'Trending',
    this.preferenceScore = 0,
    this.stylePreferenceScores = const {},
    this.chatMessages = const [],
    this.isChatTyping = false,
    required this.profileData,
  });

  DashboardState copyWith({
    int? currentIndex,
    String? selectedImagePath,
    String? uploadedAssetName,
    bool? isUploading,
    double? uploadProgress,
    String? uploadMessage,
    bool? uploadSucceeded,
    bool? hasCompletedStyleAnalysis,
    String? aiProcessingMessage,
    DashboardRecommendation? aiStyleOfDay,
    DashboardRecommendation? currentRecommendation,
    List<DashboardRecommendation>? homeRecommendations,
    List<WardrobeEntry>? wardrobeItems,
    List<DiscoverEntry>? discoverItems,
    String? wardrobeFilter,
    String? discoverFilter,
    int? preferenceScore,
    Map<String, int>? stylePreferenceScores,
    List<ChatMessage>? chatMessages,
    bool? isChatTyping,
    DashboardProfileData? profileData,
    bool clearSelectedImage = false,
    bool clearUploadedAssetName = false,
    bool clearUploadMessage = false,
  }) {
    return DashboardState(
      currentIndex: currentIndex ?? this.currentIndex,
      selectedImagePath: clearSelectedImage
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
      uploadedAssetName: clearUploadedAssetName
          ? null
          : (uploadedAssetName ?? this.uploadedAssetName),
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadMessage: clearUploadMessage
          ? null
          : (uploadMessage ?? this.uploadMessage),
      uploadSucceeded: uploadSucceeded ?? this.uploadSucceeded,
      hasCompletedStyleAnalysis:
          hasCompletedStyleAnalysis ?? this.hasCompletedStyleAnalysis,
      aiProcessingMessage: aiProcessingMessage ?? this.aiProcessingMessage,
      aiStyleOfDay: aiStyleOfDay ?? this.aiStyleOfDay,
      currentRecommendation:
          currentRecommendation ?? this.currentRecommendation,
      homeRecommendations: homeRecommendations ?? this.homeRecommendations,
      wardrobeItems: wardrobeItems ?? this.wardrobeItems,
      discoverItems: discoverItems ?? this.discoverItems,
      wardrobeFilter: wardrobeFilter ?? this.wardrobeFilter,
      discoverFilter: discoverFilter ?? this.discoverFilter,
      preferenceScore: preferenceScore ?? this.preferenceScore,
      stylePreferenceScores:
          stylePreferenceScores ?? this.stylePreferenceScores,
      chatMessages: chatMessages ?? this.chatMessages,
      isChatTyping: isChatTyping ?? this.isChatTyping,
      profileData: profileData ?? this.profileData,
    );
  }

  @override
  List<Object?> get props => [
    currentIndex,
    selectedImagePath,
    uploadedAssetName,
    isUploading,
    uploadProgress,
    uploadMessage,
    uploadSucceeded,
    hasCompletedStyleAnalysis,
    aiProcessingMessage,
    aiStyleOfDay,
    currentRecommendation,
    homeRecommendations,
    wardrobeItems,
    discoverItems,
    wardrobeFilter,
    discoverFilter,
    preferenceScore,
    stylePreferenceScores,
    chatMessages,
    isChatTyping,
    profileData,
  ];
}
