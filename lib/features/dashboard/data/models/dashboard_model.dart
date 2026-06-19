import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:fashio_me/features/dashboard/domain/entities/occasion.dart';
import 'package:fashio_me/features/dashboard/domain/entities/hairstyle.dart';

class DashboardModel {
  final List<OccasionModel> occasions;
  final List<HairstyleModel> hairstyles;

  DashboardModel({required this.occasions, required this.hairstyles});

  DashboardEntity toEntity() {
    return DashboardEntity(
      occasions: occasions.map((e) => e.toEntity()).toList(),
      hairstyles: hairstyles.map((e) => e.toEntity()).toList(),
    );
  }

  factory DashboardModel.fromMockData() {
    return DashboardModel(
      occasions: [
        OccasionModel(
          id: '1',
          name: 'WEDDING',
          imageUrl: 'assets/images/wedding.jpg',
        ),
        OccasionModel(
          id: '2',
          name: 'OFFICE',
          imageUrl: 'assets/images/outfit.jpg',
        ),
        OccasionModel(
          id: '3',
          name: 'PARTY',
          imageUrl: 'assets/images/party.jpg',
        ),
        OccasionModel(
          id: '4',
          name: 'DATE NIGHT',
          imageUrl: 'assets/images/ai_wedding_formal.jpg',
        ),
        OccasionModel(
          id: '5',
          name: 'BRUNCH',
          imageUrl: 'assets/images/brunch.jpg',
        ),
        OccasionModel(
          id: '6',
          name: 'FESTIVAL',
          imageUrl: 'assets/images/travel.jpg',
        ),
        OccasionModel(
          id: '7',
          name: 'CASUAL',
          imageUrl: 'assets/images/weekend.jpg',
        ),
      ],
      hairstyles: [
        HairstyleModel(
          id: '1',
          name: 'TEXTURED PIXIE',
          imageUrl: 'assets/images/outfit.jpg',
        ),
        HairstyleModel(
          id: '2',
          name: 'SOFT LAYERS',
          imageUrl: 'assets/images/brunch.jpg',
        ),
      ],
    );
  }
}

class OccasionModel {
  final String id;
  final String name;
  final String imageUrl;

  OccasionModel({required this.id, required this.name, required this.imageUrl});

  Occasion toEntity() {
    return Occasion(id: id, name: name, imageUrl: imageUrl);
  }
}

class HairstyleModel {
  final String id;
  final String name;
  final String imageUrl;

  HairstyleModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  Hairstyle toEntity() {
    return Hairstyle(id: id, name: name, imageUrl: imageUrl);
  }
}
