import 'package:flutter/material.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  int currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Your AI Stylist,\nReimagined.",
      "subtitle":
          "Merging the heritage of the Saree with the edge of modern tailoring.",
      "image":
          "https://images.unsplash.com/photo-1496747611176-843222e1e57c",
    },
    {
      "title": "Luxury Meets\nTechnology.",
      "subtitle":
          "Discover premium fashion recommendations powered by AI intelligence.",
      "image":
          "https://images.unsplash.com/photo-1529139574466-a303027c1d8b",
    },
    {
      "title": "Create Your\nOwn Identity.",
      "subtitle":
          "Fashion curated uniquely for your personality and culture.",
      "image":
          "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f",
    },
  ];

  void nextPage() {
    if (currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            /// logo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FashioMe',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B0000),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// pageview
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = onboardingData[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        /// image section
                        Expanded(
                          flex: 5,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              /// background card
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  color: const Color(0xFFEFE7E4),
                                ),
                              ),

                              /// image
                              Container(
                                margin: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      data['image']!,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),

                              /// gradient overlay
                              Container(
                                margin: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.35),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8D5),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'PERSONALIZED STYLE',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9B7A00),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// title
                        Text(
                          data['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// subtitle
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            data['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.6,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                        const Spacer(),

                        /// dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            onboardingData.length,
                            (index) => AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              width:
                                  currentIndex == index ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(20),
                                color: currentIndex == index
                                    ? const Color(0xFF7A0000)
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF7A0000),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: nextPage,
                            child: Text(
                              currentIndex ==
                                      onboardingData.length - 1
                                  ? 'Continue'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}