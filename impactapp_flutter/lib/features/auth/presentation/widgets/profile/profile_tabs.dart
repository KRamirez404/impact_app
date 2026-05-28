import 'package:flutter/material.dart';

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFECECF0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          labelColor: Color(0xFF0A0A0A),
          unselectedLabelColor: Color(0xFF0A0A0A),
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Mis Campañas'),
            Tab(text: 'Donaciones'),
          ],
        ),
      ),
    );
  }
}
