import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/rating_controller.dart';

class RateCampaignPage extends StatelessWidget {
  RateCampaignPage({super.key});
  final RatingController controller = Get.find<RatingController>();
  final _commentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final id = int.parse(Get.parameters['id'] ?? '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Valorar campaña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Obx(
              () => RatingBar.builder(
                initialRating: controller.rating.value,
                minRating: 1,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (_, index) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (value) => controller.rating.value = value,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _commentCtrl,
              label: 'Comentario',
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Obx(
              () => CustomButton(
                text: controller.isLoading.value ? 'Enviando...' : 'Enviar valoración',
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.submit(
                          idCampania: id,
                          comentario: _commentCtrl.text.trim(),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
