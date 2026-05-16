import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/collection_point_entity.dart';
import '../../domain/usecases/create_collection_point_usecase.dart';
import '../../domain/usecases/get_collection_points_usecase.dart';

class CollectionPointController extends GetxController {
  CollectionPointController({
    required this.getCollectionPointsUseCase,
    required this.createCollectionPointUseCase,
  });

  final GetCollectionPointsUseCase getCollectionPointsUseCase;
  final CreateCollectionPointUseCase createCollectionPointUseCase;

  final points = <CollectionPointEntity>[].obs;
  final isLoading = false.obs;

  void _ok(String msg) => Get.snackbar('Éxito', msg, backgroundColor: Colors.green, colorText: Colors.white);
  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  Future<void> load(int campaignId) async {
    try {
      isLoading.value = true;
      points.assignAll(await getCollectionPointsUseCase(campaignId));
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    try {
      isLoading.value = true;
      await createCollectionPointUseCase(payload);
      _ok('Punto creado');
      await load(payload['id_campania'] as int);
      Get.back();
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

