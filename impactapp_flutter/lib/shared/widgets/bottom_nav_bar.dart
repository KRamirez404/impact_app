import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1A000000), width: 1)),
        color: Colors.white,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.home_outlined, 'Inicio', 0, AppRoutes.home),
              _navItem(Icons.explore_outlined, 'Explorar', 1, AppRoutes.explore),
              _navItem(Icons.add_circle_outline, 'Crear', 2, AppRoutes.createCampaign),
              _navItem(Icons.person_outline, 'Perfil', 3, AppRoutes.profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, String route) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Get.offAllNamed(route);
        } else {
          Get.toNamed(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              width: 24,
              height: 2,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(1)),
              ),
            )
          else
            const SizedBox(height: 6),
          Icon(icon, size: 24, color: isActive ? const Color(0xFF1976D2) : const Color(0xFF000000)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF1976D2) : const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }
}
