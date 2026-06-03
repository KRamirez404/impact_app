import 'package:flutter/material.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../domain/entities/donor_with_donation_entity.dart';

class DonorCard extends StatelessWidget {
  const DonorCard({super.key, required this.donor});

  final DonorWithDonationEntity donor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            donor.nombreCompleto,
                            style: const TextStyle(
                              fontFamily: 'Inter', fontWeight: FontWeight.w500,
                              fontSize: 16, color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (donor.esDonacionFisica)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.cardBorder, width: 1.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textPrimary),
                                SizedBox(width: 4),
                                Text(
                                  'Donación Física',
                                  style: TextStyle(
                                    fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                    fontSize: 12, color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(donor.montoEstimado),
                          style: const TextStyle(
                            fontFamily: 'Inter', fontWeight: FontWeight.w700,
                            fontSize: 18, color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(donor.fechaDonacion),
                          style: const TextStyle(
                            fontFamily: 'Inter', fontWeight: FontWeight.w400,
                            fontSize: 12, color: Color(0xFF717182),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (donor.descripcion != null && donor.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${donor.descripcion}"',
                style: const TextStyle(
                  fontFamily: 'Inter', fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xFF717182),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (donor.esAnonimo || donor.fotoPerfil == null || donor.fotoPerfil!.isEmpty) {
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(Icons.person_outline, size: 24, color: Color(0xFF64748B)),
        ),
      );
    }
    final normalizedUrl = donor.fotoPerfil!.startsWith('/')
        ? '${ApiConstants.baseUrl.replaceAll('/api', '')}${donor.fotoPerfil}'
        : donor.fotoPerfil!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.network(
        normalizedUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Icon(Icons.person_outline, size: 24, color: Color(0xFF64748B)),
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$ ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      final hour = parsed.hour > 12 ? parsed.hour - 12 : parsed.hour;
      final period = parsed.hour >= 12 ? 'p. m.' : 'a. m.';
      return '${parsed.day} de ${months[parsed.month - 1]}, ${hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return isoDate;
    }
  }
}
