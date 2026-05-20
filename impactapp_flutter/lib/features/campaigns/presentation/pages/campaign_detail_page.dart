import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../ratings/infrastructure/datasources/rating_remote_datasource.dart';
import '../../../ratings/infrastructure/repositories/rating_repository_impl.dart';
import '../controllers/campaign_detail_controller.dart';
import '../widgets/tabs/info_tab.dart';
import '../widgets/tabs/comments_tab.dart';
import '../widgets/tabs/tracking_tab.dart';
import '../widgets/tabs/docs_tab.dart';

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
          _CategoryBadge(label: campaign.categoriaNombre),
          if (isVerified) const _VerifiedBadge(),
        ];
        final comments = _commentItems(campaign.valoraciones);
        final collected =
            (campaign.porcentajeAvance / 100) * campaign.metaMonetaria;
        final daysRemaining = _calculateDaysRemaining(campaign.fechaFin);

        return Column(
          children: [
            _buildHeader(
              campaign.titulo,
              badges,
              onBack: Get.back,
              imageUrl: campaign.soportes.isNotEmpty
                  ? campaign.soportes.first['url_o_ruta']
                  : null,
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
                      _IconText(
                        icon: Icons.location_on_outlined,
                        text: campaign.ciudadNombre.isNotEmpty
                            ? campaign.ciudadNombre
                            : 'Sin ubicación',
                      ),
                      const SizedBox(width: 16),
                      _IconText(
                        icon: Icons.people_outline,
                        text: '${campaign.donantesCount} donantes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildProgressSection(
                    collected: collected,
                    goal: campaign.metaMonetaria,
                    percentage: campaign.porcentajeAvance,
                    daysRemaining: daysRemaining,
                  ),
                  const SizedBox(height: 20),
                  _buildQuickActions(
                    commentsCount: comments.length,
                    onComments: () => _tabController.animateTo(1),
                    onRate: () => _showRateCampaignDialog(id),
                  ),
                  const SizedBox(height: 12),
                  _buildDonationButtons(
                    onDonateMoney: () => _showMoneyDonationDialog(id),
                    onDonatePhysical: () => _showPhysicalDonationDialog(
                      id,
                      campaign.puntosRecoleccion,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTabsHeader(comments.length),
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

  Widget _buildHeader(
    String title,
    List<Widget> badges, {
    required VoidCallback onBack,
    String? imageUrl,
  }) {
    return Stack(
      children: [
        Container(
          height: 256,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: imageUrl == null
                ? const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        Container(
          height: 256,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x80000000), Color(0x00000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Row(children: badges),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonationButtons({
    required VoidCallback onDonateMoney,
    required VoidCallback onDonatePhysical,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDonateMoney,
            icon: const Icon(Icons.volunteer_activism, size: 16),
            label: const Text('Donar dinero'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDonatePhysical,
            icon: const Icon(Icons.handshake_outlined, size: 16),
            label: const Text('Donar físico'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A0A0A),
              side: BorderSide(
                color: Colors.black.withOpacity(0.1),
                width: 0.8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showMoneyDonationDialog(int campaignId) async {
    final amountController = TextEditingController(text: '50000');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: 384,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.1),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Realizar Donación',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Ingresa el monto que deseas donar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF717182)),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Monto (COP)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF3F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF717182),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _AmountChip(
                          label: '\$20.000',
                          onTap: () =>
                              setState(() => amountController.text = '20000'),
                        ),
                        const SizedBox(width: 8),
                        _AmountChip(
                          label: '\$50.000',
                          onTap: () =>
                              setState(() => amountController.text = '50000'),
                        ),
                        const SizedBox(width: 8),
                        _AmountChip(
                          label: '\$100.000',
                          onTap: () =>
                              setState(() => amountController.text = '100000'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final amount =
                              double.tryParse(
                                amountController.text
                                    .replaceAll('.', '')
                                    .trim(),
                              ) ??
                              0;
                          if (amount <= 0) {
                            Get.snackbar(
                              'Monto inválido',
                              'Ingresa un monto válido para continuar',
                              backgroundColor: const Color(0xFFD32F2F),
                              colorText: Colors.white,
                            );
                            return;
                          }
                          Navigator.of(dialogContext).pop();
                          _showPaymentProcessDialog(campaignId, amount);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirmar Donación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    amountController.dispose();
  }

  Future<void> _showPaymentProcessDialog(int campaignId, double amount) async {
    var acceptTerms = false;
    var isSaving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: 382,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.1),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card,
                          color: Color(0xFF1976D2),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Realizar Donación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x0D1976D2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x331976D2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monto a donar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717182),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatCurrency(amount),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Método de pago',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x0D1976D2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1976D2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0x1A1976D2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF1976D2),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Llave Bre-B',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '300 1234567',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF717182),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.qr_code,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x0D2196F3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comprobante de Transferencia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 90,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload,
                                  color: Color(0xFF717182),
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Subir comprobante',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF717182),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: acceptTerms,
                          onChanged: isSaving
                              ? null
                              : (value) => setState(
                                  () => acceptTerms = value ?? false,
                                ),
                          activeColor: const Color(0xFF1976D2),
                        ),
                        const Expanded(
                          child: Text(
                            'Acepto los términos y condiciones y autorizo el débito correspondiente.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717182),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFB9F8CF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: Color(0xFF00A63E),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tu información está protegida con encriptación de 256 bits.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF016630),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: !acceptTerms || isSaving
                            ? null
                            : () async {
                                final navigator = Navigator.of(dialogContext);
                                setState(() => isSaving = true);
                                await controller.donate({
                                  'id_campania': campaignId,
                                  'tipo': 'economica',
                                  'monto_estimado': amount,
                                  'descripcion': 'Donación económica',
                                });
                                if (!mounted) return;
                                navigator.pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guardar Donación',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: const Text(
                          'Volver',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabsHeader(int commentsCount) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFECECF0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF0A0A0A),
        unselectedLabelColor: const Color(0xFF0A0A0A),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelPadding: EdgeInsets.zero,
        tabs: [
          const Tab(text: 'Info'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16),
                const SizedBox(width: 6),
                Text(commentsCount.toString()),
              ],
            ),
          ),
          const Tab(text: 'Avances'),
          const Tab(text: 'Docs'),
        ],
      ),
    );
  }

  Widget _buildProgressSection({
    required double collected,
    required double goal,
    required double percentage,
    required int daysRemaining,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrencyDetailed(collected),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'de ${_formatCurrencyDetailed(goal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF717182),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ((percentage / 100).clamp(0.0, 1.0)).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}% alcanzado',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF717182),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$daysRemaining días restantes',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF717182),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      final millones = (amount / 1000000).toStringAsFixed(1);
      return '\$${millones.replaceAll('.', ',')}M';
    }
    if (amount >= 1000) {
      final miles = (amount / 1000).toStringAsFixed(0);
      return '\$$miles.000';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  String _formatCurrencyDetailed(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '\$ $formatted';
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

  Widget _buildQuickActions({
    required int commentsCount,
    required VoidCallback onComments,
    required VoidCallback onRate,
  }) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.favorite_border,
          label: '0',
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Icons.chat_bubble_outline,
          label: commentsCount.toString(),
          onTap: onComments,
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Icons.star_border,
          label: 'Calificar',
          onTap: onRate,
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: () {},
        ),
      ],
    );
  }

  Future<void> _showPhysicalDonationDialog(
    int campaignId,
    List<Map<String, dynamic>> puntosRecoleccion,
  ) async {
    final commentController = TextEditingController();
    final availableTypes = const [
      {'label': 'Alimentos', 'value': 'alimentos'},
      {'label': 'Medicamentos', 'value': 'medicamentos'},
      {'label': 'Ropa', 'value': 'ropa'},
      {'label': 'Otro', 'value': 'otros'},
    ];
    var selectedType = availableTypes.first['value']!;
    int? selectedPointId;
    if (puntosRecoleccion.isNotEmpty) {
      selectedPointId = puntosRecoleccion.first['id_punto'] as int?;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: 384,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.1),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Realizar Donación Físico',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Ingrese lo donado',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF717182)),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selecciona Punto Físico',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedPointId,
                          isExpanded: true,
                          items: puntosRecoleccion
                              .map(
                                (point) => DropdownMenuItem<int>(
                                  value: point['id_punto'] as int?,
                                  child: Text(
                                    (point['nombre'] ?? '').toString(),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedPointId = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Qué Donó',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          items: availableTypes
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item['value']!,
                                  child: Text(
                                    item['label']!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(
                            () => selectedType = value ?? selectedType,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Añade un Comentario (opcional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Escribe aquí',
                        filled: true,
                        fillColor: const Color(0xFFF3F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Compártenos una imagen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 65,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F5),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            color: Color(0xFF2A343D),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tomar Foto',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717182),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedPointId == null) {
                            Get.snackbar(
                              'Punto requerido',
                              'Selecciona un punto de recolección',
                              backgroundColor: const Color(0xFFD32F2F),
                              colorText: Colors.white,
                            );
                            return;
                          }
                          final navigator = Navigator.of(dialogContext);
                          await controller.donate({
                            'id_campania': campaignId,
                            'id_punto': selectedPointId,
                            'tipo': selectedType,
                            'monto_estimado': 0,
                            'descripcion': commentController.text.trim(),
                          });
                          if (!mounted) return;
                          navigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirmar Donación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    commentController.dispose();
  }

  Future<void> _showRateCampaignDialog(int campaignId) async {
    final commentController = TextEditingController();
    var ratingValue = 5;
    var isSaving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: 277,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Calificar Campaña',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      '¿Qué te parece esta campaña?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF717182)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          iconSize: 20,
                          onPressed: isSaving
                              ? null
                              : () => setState(() => ratingValue = starIndex),
                          icon: Icon(
                            starIndex <= ratingValue
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFF0A0A0A),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Comentario (opcional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Cuéntanos tu experiencia...',
                        filled: true,
                        fillColor: const Color(0xFFF3F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final navigator = Navigator.of(dialogContext);
                                setState(() => isSaving = true);
                                final repository = RatingRepositoryImpl(
                                  RatingRemoteDataSource(),
                                );
                                try {
                                  await repository.rateCampaign(
                                    idCampania: campaignId,
                                    calificacion: ratingValue,
                                    comentario: commentController.text.trim(),
                                  );
                                  await controller.loadCampaign(campaignId);
                                } on DioException catch (e) {
                                  final data = e.response?.data;
                                  final message = data is Map<String, dynamic>
                                      ? data['error']?.toString()
                                      : null;
                                  if (!mounted) return;
                                  setState(() => isSaving = false);
                                  Get.snackbar(
                                    'Error',
                                    message ??
                                        'No se pudo registrar la valoración',
                                    backgroundColor: const Color(0xFFD32F2F),
                                    colorText: Colors.white,
                                  );
                                  return;
                                }
                                if (!mounted) return;
                                navigator.pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Enviar Calificación',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    commentController.dispose();
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0A0A0A),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 6),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0A0A0A),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 0.8,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0A0A0A)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Segoe UI Emoji',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.isEmpty ? 'Categoría' : label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF00A63E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Verificada',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF717182)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF717182),
            fontFamily: 'Segoe UI Emoji',
          ),
        ),
      ],
    );
  }
}
