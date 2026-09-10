import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/storage_keys.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex});
  final int currentIndex;

  String _currentRole() {
    final cached = GetStorage().read<String>(StorageKeys.user);
    if (cached == null || cached.isEmpty) return 'donante';
    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      return (data['rol'] as String? ?? 'donante').toLowerCase();
    } catch (_) {
      return 'donante';
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _currentRole();
    final canCreate = role != 'donante';
    final items = <_NavSpec>[
      _NavSpec(Icons.home_outlined, 'Inicio', 0, AppRoutes.home),
      _NavSpec(Icons.explore_outlined, 'Explorar', 1, AppRoutes.explore),
      if (canCreate)
        _NavSpec(Icons.add_circle_outline, 'Crear', 2, AppRoutes.createCampaign),
      _NavSpec(Icons.person_outline, 'Perfil', 3, AppRoutes.profile),
    ];
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
            children: items.map((item) => _navItem(item, currentIndex)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _navItem(_NavSpec spec, int currentIndex) {
    final isActive = currentIndex == spec.index;
    return GestureDetector(
      onTap: () {
        if (spec.index == 0) {
          Get.offAllNamed(spec.route);
        } else {
          Get.toNamed(spec.route);
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
          Icon(spec.icon, size: 24, color: isActive ? const Color(0xFF1976D2) : const Color(0xFF000000)),
          const SizedBox(height: 4),
          Text(
            spec.label,
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

class _NavSpec {
  final IconData icon;
  final String label;
  final int index;
  final String route;
  const _NavSpec(this.icon, this.label, this.index, this.route);
}
