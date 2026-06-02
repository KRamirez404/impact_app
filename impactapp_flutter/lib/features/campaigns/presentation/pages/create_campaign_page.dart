import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../controllers/campaign_list_controller.dart';
import 'create_collection_point_modal.dart';
import '../../../collection_points/domain/usecases/create_collection_point_usecase.dart';
import '../../infrastructure/datasources/campaign_remote_datasource.dart';
import '../widgets/create_campaign/basics_card.dart';
import '../widgets/create_campaign/organizer_card.dart';
import '../widgets/create_campaign/evidence_card.dart';
import '../widgets/create_campaign/points_card.dart';

class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({super.key});

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _metaCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _cuentaCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();

  final _picker = ImagePicker();
  final CampaignListController controller = Get.find<CampaignListController>();
  final CampaignRemoteDataSource _remoteDataSource =
      Get.find<CampaignRemoteDataSource>();
  final CreateCollectionPointUseCase _createCollectionPointUseCase =
      Get.find<CreateCollectionPointUseCase>();

  final List<Map<String, dynamic>> _cities = [];
  final List<Map<String, dynamic>> _categories = [];
  final List<CollectionPointDraft> _draftPoints = [];
  final List<XFile> _attachments = [];

  bool _loadingOptions = true;
  bool _submitting = false;
  String _selectedHelpType = 'economica';
  String? _selectedDepartment;
  int? _selectedCityId;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _metaCtrl.dispose();
    _fechaFinCtrl.dispose();
    _cuentaCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      _remoteDataSource.getCities(),
      _remoteDataSource.getCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _cities
        ..clear()
        ..addAll(results[0].cast<Map<String, dynamic>>());
      _categories
        ..clear()
        ..addAll(results[1].cast<Map<String, dynamic>>());
      _loadingOptions = false;
    });
  }

  List<String> get _departments {
    return _cities
        .map((city) => (city['departamento'] ?? '').toString())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<Map<String, dynamic>> get _availableCities {
    if (_selectedDepartment == null) return const [];
    return _cities
        .where(
          (city) =>
              (city['departamento'] ?? '').toString() == _selectedDepartment,
        )
        .toList();
  }

  Future<void> _pickAttachments() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    if (picked.isEmpty) return;
    setState(() {
      _attachments
        ..clear()
        ..addAll(picked);
    });
  }

  Future<void> _openPointModal() async {
    final draft = await showDialog<CollectionPointDraft>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CreateCollectionPointModal(),
    );
    if (draft == null) return;
    setState(() {
      _draftPoints.add(draft);
    });
  }

  Future<void> _submit() async {
    if (_selectedCityId == null || _selectedCategoryId == null) return;
    setState(() => _submitting = true);
    final campaign = await controller.createCampaign({
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'id_ciudad': _selectedCityId,
      'id_categoria': _selectedCategoryId,
      'tipo_ayuda_requerida': _selectedHelpType,
      'meta_monetaria': double.tryParse(_metaCtrl.text.trim()) ?? 0.0,
      'fecha_fin': _fechaFinCtrl.text.trim(),
    });
    if (!mounted) return;
    if (campaign == null) {
      setState(() => _submitting = false);
      return;
    }

    try {
      for (final point in _draftPoints) {
        await _createCollectionPointUseCase({
          'id_campania': campaign.idCampania,
          'id_ciudad': _selectedCityId,
          'nombre': point.nombre,
          'direccion': point.direccion,
          'horario': '${point.horario} (Artículos: ${point.articulosAceptados})',
          'contacto': _correoCtrl.text.trim(),
        });
      }

      for (final attachment in _attachments) {
        await _remoteDataSource.uploadSupport(campaign.idCampania, 'foto', attachment.path);
      }

      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        'Error', e.toString(),
        backgroundColor: Colors.red, colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        children: [
          BasicsCard(
            tituloCtrl: _tituloCtrl,
            descripcionCtrl: _descripcionCtrl,
            metaCtrl: _metaCtrl,
            fechaFinCtrl: _fechaFinCtrl,
            categories: _categories,
            departments: _departments,
            availableCities: _availableCities,
            selectedCategoryId: _selectedCategoryId,
            selectedDepartment: _selectedDepartment,
            selectedCityId: _selectedCityId,
            selectedHelpType: _selectedHelpType,
            onCategoryChanged: (v) => setState(() => _selectedCategoryId = v),
            onDepartmentChanged: (v) => setState(() { _selectedDepartment = v; _selectedCityId = null; }),
            onCityChanged: (v) => setState(() => _selectedCityId = v),
            onHelpTypeChanged: (v) => setState(() => _selectedHelpType = v ?? 'economica'),
          ),
          const SizedBox(height: 16),
          OrganizerCard(
            cuentaCtrl: _cuentaCtrl,
            correoCtrl: _correoCtrl,
          ),
          const SizedBox(height: 16),
          EvidenceCard(
            attachmentsCount: _attachments.length,
            onPickAttachments: _pickAttachments,
          ),
          const SizedBox(height: 16),
          PointsCard(
            draftPoints: _draftPoints,
            onAddPoint: _openPointModal,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) _submit();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(36),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _submitting ? 'Creando...' : 'Crear Campaña',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _submitting ? null : () => Get.back(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(88, 36),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.black.withOpacity(0.1), width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: const Color(0xFF0A0A0A),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Las campañas serán verificadas en 24-48 horas antes de publicarse.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.33, color: Color(0xFF717182)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 54,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Crear Campaña',
                    style: TextStyle(fontFamily: 'Segoe UI Emoji', fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loadingOptions
                ? const Center(child: CircularProgressIndicator())
                : _buildForm(),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
