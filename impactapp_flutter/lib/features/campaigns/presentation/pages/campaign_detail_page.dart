import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../controllers/campaign_detail_controller.dart';

class CampaignDetailPage extends StatefulWidget {
  const CampaignDetailPage({super.key});

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  final CampaignDetailController controller = Get.find<CampaignDetailController>();

  @override
  void initState() {
    super.initState();
    final id = int.parse(Get.parameters['id'] ?? '0');
    Future.microtask(() => controller.loadCampaign(id));
  }

  @override
  Widget build(BuildContext context) {
    final id = int.parse(Get.parameters['id'] ?? '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle campaña')),
      body: Obx(
        () {
          final campaign = controller.campaign.value;
          if (controller.isLoading.value || campaign == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(campaign.titulo, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(campaign.descripcion),
              const SizedBox(height: 12),
              ProgressBar(progress: campaign.porcentajeAvance),
              const SizedBox(height: 8),
              Text('Estado: ${campaign.estado}'),
              const SizedBox(height: 20),
              const Text('Soportes', style: TextStyle(fontWeight: FontWeight.bold)),
              ...campaign.soportes
                  .map((s) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text((s['tipo'] ?? '').toString()),
                        subtitle: Text((s['descripcion'] ?? s['url_o_ruta'] ?? '').toString()),
                      )),
              const SizedBox(height: 12),
              const Text('Valoraciones', style: TextStyle(fontWeight: FontWeight.bold)),
              ...campaign.valoraciones
                  .map((r) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Calificación: ${(r['calificacion'] ?? '-').toString()}'),
                        subtitle: Text((r['comentario'] ?? '').toString()),
                      )),
              const SizedBox(height: 12),
              const Text('Puntos de recolección', style: TextStyle(fontWeight: FontWeight.bold)),
              ...campaign.puntosRecoleccion
                  .map((p) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text((p['nombre'] ?? '').toString()),
                        subtitle: Text((p['direccion'] ?? '').toString()),
                      )),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => Get.toNamed('${AppRoutes.donate}/$id'),
                    child: const Text('Donar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('${AppRoutes.uploadSupport}/$id'),
                    child: const Text('Subir soporte'),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('${AppRoutes.collectionPoints}/$id'),
                    child: const Text('Puntos'),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('${AppRoutes.rate}/$id'),
                    child: const Text('Valorar'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
