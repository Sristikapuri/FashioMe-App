import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/app/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final silhouetteProfileProvider = FutureProvider<SilhouetteProfile?>((
  ref,
) async {
  final usecase = ref.read(getSilhouetteProfileUsecaseProvider);
  final result = await usecase();
  return result.fold((_) => null, (profile) => profile);
});
