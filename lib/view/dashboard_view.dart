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

        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [

            /// MENU ICON
            const Icon(
              Icons.menu,
              color: Color(0xff6B0000),
            ),

            /// LOGO
            const Text(
              "FashioMe",
              style: TextStyle(
                color: Color(0xff6B0000),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),

            /// PROFILE ICON
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
      body: const SafeArea(
        child: Center(
          child: Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}