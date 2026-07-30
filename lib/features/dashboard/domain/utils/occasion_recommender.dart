import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';

/// Ported from the web app's `DiscoverTab.tsx` occasion-recommendation
/// logic, so the "For You" card picks the same occasion given the same
/// profile/wardrobe/archive inputs.
const List<String> kRecommendableOccasions = [
  'Office',
  'Party',
  'Festival',
  'Casual',
  'Date Night',
  'Brunch',
  'Wedding',
];

String _combinedStyleText(DashboardProfileData profileData) {
  final styleMood = profileData.styleMood.toLowerCase();
  final stylePrefs = profileData.stylePreferences.join(' ').toLowerCase();
  return '$styleMood $stylePrefs';
}

String normalizeArchiveOccasion(String value) {
  final text = value.toLowerCase();
  if (text.contains('office') || text.contains('work')) return 'Office';
  if (text.contains('party') ||
      text.contains('glam') ||
      text.contains('night')) {
    return 'Party';
  }
  if (text.contains('festival') ||
      text.contains('wedding') ||
      text.contains('sangeet')) {
    return 'Festival';
  }
  if (text.contains('date')) return 'Date Night';
  if (text.contains('brunch')) return 'Brunch';
  if (text.contains('travel') ||
      text.contains('casual') ||
      text.contains('weekend')) {
    return 'Casual';
  }
  return 'Casual';
}

String deriveBestOccasion(
  DashboardProfileData profileData,
  List<String> wardrobeCategories,
  List<String> archiveOccasions,
) {
  final combined = _combinedStyleText(profileData);
  final categoryBlob = wardrobeCategories.join(' ').toLowerCase();

  String bestOccasion = kRecommendableOccasions.first;
  int bestScore = -1 << 30;

  for (final occasion in kRecommendableOccasions) {
    var score = 0;
    if (combined.contains(occasion.toLowerCase())) score += 6;
    if (occasion == 'Office' &&
        (combined.contains('work') ||
            combined.contains('formal') ||
            combined.contains('smart'))) {
      score += 4;
    }
    if (occasion == 'Party' &&
        (combined.contains('glam') ||
            combined.contains('bold') ||
            combined.contains('evening'))) {
      score += 4;
    }
    if (occasion == 'Festival' &&
        (combined.contains('festival') ||
            combined.contains('wedding') ||
            combined.contains('ethnic'))) {
      score += 4;
    }
    if (occasion == 'Casual' &&
        (combined.contains('casual') ||
            combined.contains('relaxed') ||
            combined.contains('weekend'))) {
      score += 4;
    }
    if (occasion == 'Date Night' &&
        (combined.contains('date') || combined.contains('romantic'))) {
      score += 3;
    }
    if (occasion == 'Brunch' &&
        (combined.contains('soft') ||
            combined.contains('light') ||
            combined.contains('easy'))) {
      score += 3;
    }

    if (wardrobeCategories.isNotEmpty) {
      if (occasion == 'Office' &&
          (categoryBlob.contains('shirts') ||
              categoryBlob.contains('blazers') ||
              categoryBlob.contains('pants'))) {
        score += 3;
      }
      if (occasion == 'Party' &&
          (categoryBlob.contains('dresses') ||
              categoryBlob.contains('skirts') ||
              categoryBlob.contains('outerwear'))) {
        score += 3;
      }
      if (occasion == 'Festival' &&
          (categoryBlob.contains('dresses') ||
              categoryBlob.contains('skirts') ||
              categoryBlob.contains('tops'))) {
        score += 2;
      }
      if (occasion == 'Casual' &&
          (categoryBlob.contains('tops') ||
              categoryBlob.contains('pants') ||
              categoryBlob.contains('shoes'))) {
        score += 3;
      }
      if (occasion == 'Date Night' &&
          (categoryBlob.contains('dresses') ||
              categoryBlob.contains('outerwear') ||
              categoryBlob.contains('shoes'))) {
        score += 2;
      }
      if (occasion == 'Brunch' &&
          (categoryBlob.contains('tops') ||
              categoryBlob.contains('skirts') ||
              categoryBlob.contains('accessories'))) {
        score += 2;
      }
    }

    final priorCount = archiveOccasions
        .where((item) => item == occasion)
        .length;
    score -= priorCount * 2;

    if (score > bestScore) {
      bestScore = score;
      bestOccasion = occasion;
    }
  }

  return bestOccasion;
}

String deriveAutoReason(DashboardProfileData profileData) {
  final styleMood = profileData.styleMood.toLowerCase();
  final stylePrefs = profileData.stylePreferences.join(', ');
  final styleParts = [
    styleMood,
    stylePrefs,
  ].where((part) => part.trim().isNotEmpty).toList();

  if (styleParts.isNotEmpty) {
    return 'Based on your style profile: ${styleParts.join(' / ')}';
  }

  return 'Based on the current day and your live wardrobe context';
}

List<String> explainOccasionChoice(
  DashboardProfileData profileData,
  List<String> wardrobeCategories,
  List<String> archiveOccasions,
  String chosenOccasion,
) {
  final reasons = <String>[];
  final combined = _combinedStyleText(profileData);

  if (combined.contains('office') ||
      combined.contains('work') ||
      combined.contains('formal')) {
    reasons.add('style profile leans office/formal');
  }
  if (combined.contains('party') ||
      combined.contains('glam') ||
      combined.contains('evening')) {
    reasons.add('style profile leans party/evening');
  }
  if (combined.contains('wedding') ||
      combined.contains('sangeet') ||
      combined.contains('festival')) {
    reasons.add('style profile leans festive');
  }
  if (wardrobeCategories.isNotEmpty) {
    reasons.add('wardrobe supports ${wardrobeCategories.take(3).join(', ')}');
  }
  if (archiveOccasions.contains(chosenOccasion)) {
    reasons.add(
      'recent archive activity includes ${chosenOccasion.toLowerCase()}',
    );
  }
  if (reasons.isEmpty) {
    reasons.add('current day fallback and wardrobe context');
  }

  return reasons.take(3).toList();
}
