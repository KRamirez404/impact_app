import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../shared/theme/app_theme.dart';

class DangerItem extends StatelessWidget {
  const DangerItem({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.defaultDialog(
        title: 'Confirmar',
        middleText: '¿Deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
        textCancel: 'Cancelar',
        textConfirm: 'Eliminar',
        cancelTextColor: AppColors.subtitle,
        confirmTextColor: Colors.white,
        buttonColor: AppColors.dangerText,
        onConfirm: () {
          Get.back();
          Get.snackbar('Eliminado', 'Cuenta marcada para eliminación',
              snackPosition: SnackPosition.BOTTOM);
        },
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.dangerIconBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.dangerText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Eliminar cuenta',
                    style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w500,
                      fontSize: 14, color: AppColors.dangerText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w400,
                      fontSize: 12, color: AppColors.dangerSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.dangerSubtitle),
          ],
        ),
      ),
    );
  }
}
