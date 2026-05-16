import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) Get.offAllNamed(AppRoutes.home);
        if (index == 1) Get.toNamed(AppRoutes.createCampaign);
        if (index == 2) Get.toNamed(AppRoutes.profile);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campañas'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Crear'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}

