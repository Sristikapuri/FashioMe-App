import 'package:equatable/equatable.dart';
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';

export 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';

class DashboardState extends Equatable {
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
    this.searchQuery = '',
    this.preferenceScore = 0,
    this.stylePreferenceScores = const {},
    this.chatMessages = const [],
    this.isChatTyping = false,
    required this.profileData,
  });

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
  final String searchQuery;
  final int preferenceScore;
  final Map<String, int> stylePreferenceScores;
  final List<ChatMessage> chatMessages;
  final bool isChatTyping;
  final DashboardProfileData profileData;

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
    String? searchQuery,
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
      searchQuery: searchQuery ?? this.searchQuery,
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
    searchQuery,
    preferenceScore,
    stylePreferenceScores,
    chatMessages,
    isChatTyping,
    profileData,
  ];
}
