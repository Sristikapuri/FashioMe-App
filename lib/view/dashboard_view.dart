import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F5F2),

      appBar: AppBar(
        backgroundColor: const Color(0xffF8F5F2),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.menu, color: Color(0xff6B0000)),
            Text(
              "FashioMe",
              style: TextStyle(
                color: Color(0xff6B0000),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Icon(Icons.person_outline, size: 22, color: Color(0xff6B0000)),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),

              /// SECTION TITLE
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
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// MAIN BANNER
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1529139574466-a303027c1d8b',
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
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.2),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffD8C15B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Fusion Edit",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const Spacer(),

                      const Text(
                        "Velvet Heritage\nMeets Urban Edge",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Combining classical embroidery\nwith modern silhouettes",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// ================= SEASONAL PALETTE =================
              const SizedBox(height: 35),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Your Seasonal Palette",
                      style: const TextStyle(
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

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey),
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
            ],
          ),
        ),
      ),
    );
  }
}

class PaletteColor extends StatelessWidget {
  final Color color;

  const PaletteColor({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }
}