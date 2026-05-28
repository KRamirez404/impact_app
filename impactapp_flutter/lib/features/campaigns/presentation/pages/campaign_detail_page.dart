import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../ratings/infrastructure/datasources/rating_remote_datasource.dart';
import '../../../ratings/infrastructure/repositories/rating_repository_impl.dart';
import '../controllers/campaign_detail_controller.dart';
import '../widgets/tabs/info_tab.dart';
import '../widgets/tabs/comments_tab.dart';
import '../widgets/tabs/tracking_tab.dart';
import '../widgets/tabs/docs_tab.dart';
import '../widgets/campaign_detail/campaign_header.dart';
import '../widgets/campaign_detail/category_badge.dart';
import '../widgets/campaign_detail/verified_badge.dart';
import '../widgets/campaign_detail/icon_text.dart';
import '../widgets/campaign_detail/progress_section.dart';
import '../widgets/campaign_detail/quick_actions.dart';
import '../widgets/campaign_detail/donation_buttons.dart';
import '../widgets/campaign_detail/tabs_header.dart';
import '../widgets/campaign_detail/money_donation_dialog.dart';
import '../widgets/campaign_detail/physical_donation_dialog.dart';
import '../widgets/campaign_detail/rate_campaign_dialog.dart';

class CampaignDetailPage extends StatefulWidget {
  const CampaignDetailPage({super.key});

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage>
    with TickerProviderStateMixin {
  final CampaignDetailController controller =
      Get.find<CampaignDetailController>();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final id = int.parse(Get.parameters['id'] ?? '0');
    Future.microtask(() => controller.loadCampaign(id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _commentItems(
    List<Map<String, dynamic>> valoraciones,
  ) {
    return valoraciones.where((item) {
      final text = (item['comentario'] ?? '').toString().trim();
      return text.isNotEmpty;
    }).toList();
  }

  String? _imageSupportUrl(List<Map<String, dynamic>> supports) {
    for (final support in supports) {
      final tipo = (support['tipo'] ?? '').toString().toLowerCase().trim();
      if (tipo != 'imagen') {
        continue;
      }
      final url = (support['url_o_ruta'] ?? '').toString().trim();
      if (url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return isoDate;
    }
  }

  int _calculateDaysRemaining(String fechaFinIso) {
    try {
      final end = DateTime.parse(fechaFinIso);
      final now = DateTime.now();
      final difference = end.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _showMoneyDonationDialog(int campaignId) {
    return showMoneyDonationDialog(
      context: context,
      campaignId: campaignId,
      onDonate: (data) => controller.donate(data),
    );
  }

  Future<void> _showPhysicalDonationDialog(
    int campaignId,
    List<Map<String, dynamic>> puntosRecoleccion,
  ) {
    return showPhysicalDonationDialog(
      context: context,
      campaignId: campaignId,
      puntosRecoleccion: puntosRecoleccion,
      onDonate: (data) => controller.donate(data),
    );
  }

  Future<void> _showRateCampaignDialog(int campaignId) {
    final ratingDataSource = RatingRemoteDataSource();
    final ratingRepo = RatingRepositoryImpl(ratingDataSource);
    return showRateCampaignDialog(
      context: context,
      campaignId: campaignId,
      onRate: (data) => ratingRepo.rateCampaign(
        idCampania: data['id_campania'] as int,
        calificacion: data['puntuacion'] as int,
        comentario: data['comentario'] as String? ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = int.parse(Get.parameters['id'] ?? '0');
    return Scaffold(
      body: Obx(() {
        final campaign = controller.campaign.value;
        if (controller.isLoading.value || campaign == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final isVerified =
            campaign.estado == 'activa' || campaign.estado == 'finalizada';
        final badges = <Widget>[
          CategoryBadge(label: campaign.categoriaNombre),
          if (isVerified) const VerifiedBadge(),
        ];
        final comments = _commentItems(campaign.valoraciones);
        final collected =
            (campaign.porcentajeAvance / 100) * campaign.metaMonetaria;
        final daysRemaining = _calculateDaysRemaining(campaign.fechaFin);
        final headerImageUrl = _imageSupportUrl(campaign.soportes);

        return Column(
          children: [
            CampaignHeader(
              badges: badges,
              onBack: Get.back,
              imageUrl: headerImageUrl,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    campaign.titulo,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconText(
                        icon: Icons.location_on_outlined,
                        text: campaign.ciudadNombre.isNotEmpty
                            ? campaign.ciudadNombre
                            : 'Sin ubicación',
                      ),
                      const SizedBox(width: 16),
                      IconText(
                        icon: Icons.people_outline,
                        text: '${campaign.donantesCount} donantes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProgressSection(
                    collected: collected,
                    goal: campaign.metaMonetaria,
                    percentage: campaign.porcentajeAvance,
                    daysRemaining: daysRemaining,
                  ),
                  const SizedBox(height: 20),
                  QuickActions(
                    likesCount: campaign.likesCount,
                    isLiked: campaign.likedByMe,
                    isLikeLoading: controller.isLiking.value,
                    commentsCount: comments.length,
                    onLike: () => controller.toggleLike(id),
                    onComments: () => _tabController.animateTo(1),
                    onRate: () => _showRateCampaignDialog(id),
                  ),
                  const SizedBox(height: 12),
                  DonationButtons(
                    onDonateMoney: () => _showMoneyDonationDialog(id),
                    onDonatePhysical: () => _showPhysicalDonationDialog(
                      id,
                      campaign.puntosRecoleccion,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TabsHeader(
                    tabController: _tabController,
                    commentsCount: comments.length,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        InfoTab(campaign: campaign),
                        CommentsTab(
                          campaignId: id,
                          comments: comments,
                          onCommentPublished: () => controller.loadCampaign(id),
                        ),
                        TrackingTab(
                          tracking: campaign.seguimientos,
                          formatDate: _formatDate,
                        ),
                        DocsTab(supports: campaign.soportes),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
