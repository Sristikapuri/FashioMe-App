import 'package:equatable/equatable.dart';

class OnboardingItem extends Equatable {
  final String title;
  final String subtitle;
  final String imageUrl;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [title, subtitle, imageUrl];
}

const kOnboardingItems = [
  OnboardingItem(
    title: 'Your AI Stylist,\nReimagined.',
    subtitle:
        'Merging the heritage of the Saree with the edge of modern tailoring.',
    imageUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c',
  ),
  OnboardingItem(
    title: 'Luxury Meets\nTechnology.',
    subtitle:
        'Discover premium fashion recommendations powered by AI intelligence.',
    imageUrl: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b',
  ),
  OnboardingItem(
    title: 'Create Your\nOwn Identity.',
    subtitle:
        'Fashion curated uniquely for your personality and culture.',
    imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f',
  ),
];
