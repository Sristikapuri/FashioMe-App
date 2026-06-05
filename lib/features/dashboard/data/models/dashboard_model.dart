import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:fashio_me/features/dashboard/domain/entities/occasion.dart';
import 'package:fashio_me/features/dashboard/domain/entities/hairstyle.dart';

class DashboardModel {
  final List<OccasionModel> occasions;
  final List<HairstyleModel> hairstyles;

  DashboardModel({
    required this.occasions,
    required this.hairstyles,
  });

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
          imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=400&q=80',
        ),
        OccasionModel(
          id: '2',
          name: 'OFFICE',
          imageUrl: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=400&q=80',
        ),
        OccasionModel(
          id: '3',
          name: 'PARTY',
          imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=400&q=80',
        ),
        OccasionModel(
          id: '4',
          name: 'DATE NIGHT',
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        ),
        OccasionModel(
          id: '5',
          name: 'BRUNCH',
          imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=400&q=80',
        ),
        OccasionModel(
          id: '6',
          name: 'FESTIVAL',
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=400&q=80',
        ),
        OccasionModel(
          id: '7',
          name: 'CASUAL',
          imageUrl: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=400&q=80',
        ),
      ],
      hairstyles: [
        HairstyleModel(
          id: '1',
          name: 'TEXTURED PIXIE',
          imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        ),
        HairstyleModel(
          id: '2',
          name: 'SOFT LAYERS',
          imageUrl: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=400&q=80',
        ),
      ],
    );
  }
}

class OccasionModel {
  final String id;
  final String name;
  final String imageUrl;

  OccasionModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  Occasion toEntity() {
    return Occasion(
      id: id,
      name: name,
      imageUrl: imageUrl,
    );
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
    return Hairstyle(
      id: id,
      name: name,
      imageUrl: imageUrl,
    );
  }
}
