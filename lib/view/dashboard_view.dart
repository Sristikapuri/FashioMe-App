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
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [

            /// MENU
            const Icon(
              Icons.menu,
              color: Color(0xff6B0000),
            ),

            /// LOGO
            const Text(
              "FashioMe",
              style: TextStyle(
                color: Color(0xff6B0000),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            /// PROFILE
            Container(
              padding: const EdgeInsets.all(4),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                border: Border.all(
                  color: const Color(0xff6B0000),
                ),
              ),

              child: const Icon(
                Icons.person_outline,
                size: 18,
                color: Color(0xff6B0000),
              ),
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ================= TODAY CURATION =================
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

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

              // ================= MAIN BANNER =================
              Container(
                height: 220,
                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(22),

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
                    borderRadius:
                        BorderRadius.circular(22),

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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      /// TAG
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color:
                              const Color(0xffD8C15B),

                          borderRadius:
                              BorderRadius.circular(
                                  20),
                        ),

                        child: const Text(
                          "Fusion Edit",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const Spacer(),

                      /// TITLE
                      const Text(
                        "Velvet Heritage\nMeets Urban Edge",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 28,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// SUBTITLE
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

              // ================= PALETTE =================
              const SizedBox(height: 35),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

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
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(18),

                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,

                  child: Row(
                    children: const [

                      PaletteColor(
                        color: Color(0xff7B0000),
                      ),

                      SizedBox(width: 12),

                      PaletteColor(
                        color: Color(0xff8B6B00),
                      ),

                      SizedBox(width: 12),

                      PaletteColor(
                        color: Color(0xffF8F2F0),
                      ),

                      SizedBox(width: 12),

                      PaletteColor(
                        color: Color(0xffDFC1B8),
                      ),

                      SizedBox(width: 12),

                      PaletteColor(
                        color: Color(0xff3F4630),
                      ),

                      SizedBox(width: 12),

                      PaletteColor(
                        color: Color(0xffF1D0C8),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= HAIRSTYLES =================
              const SizedBox(height: 35),

              const Text(
                "Personalized Hairstyles",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2A2323),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [

                  Expanded(
                    child: hairstyleCard(
                      image:
                          'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                      title: 'TEXTURED PIXIE',
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: hairstyleCard(
                      image:
                          'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df',
                      title: 'SOFT LAYERS',
                    ),
                  ),
                ],
              ),

              // ================= OCCASIONS =================
              const SizedBox(height: 35),

              const Text(
                "Explore Occasions",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2A2323),
                ),
              ),

              const SizedBox(height: 18),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: Row(
                  children: [

                    occasionCard(
                      image:
                          'https://images.unsplash.com/photo-1519741497674-611481863552',
                      title: 'WEDDING',
                    ),

                    const SizedBox(width: 14),

                    occasionCard(
                      image:
                          'https://images.unsplash.com/photo-1507679799987-c73779587ccf',
                      title: 'OFFICE',
                    ),

                    const SizedBox(width: 14),

                    occasionCard(
                      image:
                          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819',
                      title: 'PARTY',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,

        selectedItemColor:
            const Color(0xff6B0000),

        unselectedItemColor:
            Colors.brown.shade300,

        backgroundColor:
            const Color(0xffF8F5F2),

        elevation: 0,

        type: BottomNavigationBarType.fixed,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),

        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.auto_awesome_outlined,
            ),
            label: "AI Sync",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: "Closet",
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.face_retouching_natural_outlined,
            ),
            label: "Advisor",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Me",
          ),
        ],
      ),
    );
  }

  // ================= HAIRSTYLE CARD =================
  Widget hairstyleCard({
    required String image,
    required String title,
  }) {
    return Column(
      children: [

        Container(
          height: 230,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),

            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ================= OCCASION CARD =================
  Widget occasionCard({
    required String image,
    required String title,
  }) {
    return Column(
      children: [

        Container(
          width: 95,
          height: 95,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),

            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ================= PALETTE COLOR =================
class PaletteColor extends StatelessWidget {
  final Color color;

  const PaletteColor({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,

      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,

        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}