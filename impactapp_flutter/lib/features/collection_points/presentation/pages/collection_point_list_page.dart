import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../controllers/collection_point_controller.dart';

class CollectionPointListPage extends StatefulWidget {
  const CollectionPointListPage({super.key});

  @override
  State<CollectionPointListPage> createState() => _CollectionPointListPageState();
}

class _CollectionPointListPageState extends State<CollectionPointListPage> {
  final CollectionPointController controller = Get.find<CollectionPointController>();

  @override
  void initState() {
    super.initState();
    final id = int.parse(Get.parameters['id'] ?? '0');
    Future.microtask(() => controller.load(id));
  }

  @override
  Widget build(BuildContext context) {
    final id = int.parse(Get.parameters['id'] ?? '0');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntos de recolección'),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('${AppRoutes.collectionPoints}/$id/create'),
            icon: const Icon(Icons.add_location_alt),
          )
        ],
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.points.isEmpty) return const Center(child: Text('Sin puntos'));
          return ListView.builder(
            itemCount: controller.points.length,
            itemBuilder: (_, i) {
              final p = controller.points[i];
              return ListTile(
                title: Text(p.nombre),
                subtitle: Text('${p.direccion}\n${p.horario}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
