import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F5F2),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xffF8F5F2),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.menu, color: Color(0xff6B0000)),
            Text(
              "FashioMe",
              style: TextStyle(
                color: Color(0xff6B0000),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.person_outline,
                size: 18, color: Color(0xff6B0000)),
          ],
        ),
      ),

      // ================= BODY =================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),

              // ================= TITLE =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Today's Curation",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2A2323),
                    ),
                  ),
                  Text(
                    "VIEW ALL",
                    style: TextStyle(
                      color: Color(0xffA7831A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ================= BANNER =================
              _banner(),

              const SizedBox(height: 35),

              // ================= SEASONAL PALETTE HEADER =================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      "Your Seasonal Palette",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2A2323),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "DEEP AUTUMN",
                      style: TextStyle(
                        color: Color(0xffA7831A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ================= PALETTE =================
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: const [
                      PaletteColor(color: Color(0xff7B0000)),
                      SizedBox(width: 12),
                      PaletteColor(color: Color(0xff8B6B00)),
                      SizedBox(width: 12),
                      PaletteColor(color: Color(0xffF8F2F0)),
                      SizedBox(width: 12),
                      PaletteColor(color: Color(0xffDFC1B8)),
                      SizedBox(width: 12),
                      PaletteColor(color: Color(0xff3F4630)),
                      SizedBox(width: 12),
                      PaletteColor(color: Color(0xffF1D0C8)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ================= HAIRSTYLES =================
              const Text(
                "Personalized Hairstyles",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _imageCard(
                      "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
                      "TEXTURED PIXIE",
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _imageCard(
                      "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
                      "SOFT LAYERS",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // ================= OCCASIONS =================
              const Text(
                "Explore Occasions",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _circleCard(
                      "https://images.unsplash.com/photo-1519741497674-611481863552",
                      "WEDDING",
                    ),
                    const SizedBox(width: 14),
                    _circleCard(
                      "https://images.unsplash.com/photo-1507679799987-c73779587ccf",
                      "OFFICE",
                    ),
                    const SizedBox(width: 14),
                    _circleCard(
                      "https://images.unsplash.com/photo-1514525253161-7a46d19cd819",
                      "PARTY",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Discover your AI fashion recommendations daily ✨",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ================= BANNER =================
  Widget _banner() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: const DecorationImage(
          image: NetworkImage(
            "https://images.unsplash.com/photo-1529139574466-a303027c1d8b",
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(),
            Text(
              "Velvet Heritage\nMeets Urban Edge",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Modern fashion inspiration",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // ================= IMAGE CARD =================
  Widget _imageCard(String image, String title) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ================= OCCASION CARD =================
  Widget _circleCard(String image, String title) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title),
      ],
    );
  }
}

// ================= PALETTE =================
class PaletteColor extends StatelessWidget {
  final Color color;

  const PaletteColor({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}