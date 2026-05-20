import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../controllers/campaign_list_controller.dart';
import 'create_collection_point_modal.dart';
import '../../../collection_points/domain/usecases/create_collection_point_usecase.dart';
import '../../infrastructure/datasources/campaign_remote_datasource.dart';

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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintMaxLines: 1,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        height: 1.19,
        color: Color(0xFF717182),
      ),
      filled: true,
      fillColor: const Color(0xFFF3F3F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _card({
    required String title,
    required String description,
    required Widget child,
    EdgeInsetsGeometry? contentPadding,
    double? height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.33,
                    color: Color(0xFF717182),
                  ),
                ),
              ],
            ),
          ),
          if (contentPadding != null)
            Padding(padding: contentPadding, child: child)
          else
            child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.43,
        color: Color(0xFF0A0A0A),
      ),
    );
  }

  Widget _buildBasicsCard() {
    final categoryItems = _categories
        .map(
          (category) => DropdownMenuItem<String>(
            value: '${category['id_categoria']}',
            child: Text(
              (category['nombre'] ?? '').toString(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.43,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ),
        )
        .toList();
    final departmentItems = _departments
        .map(
          (dept) => DropdownMenuItem<String>(
            value: dept,
            child: Text(
              dept,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.43,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ),
        )
        .toList();
    final cityItems = _availableCities
        .map(
          (city) => DropdownMenuItem<String>(
            value: '${city['id_ciudad']}',
            child: Text(
              (city['nombre'] ?? '').toString(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.43,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ),
        )
        .toList();

    return _card(
      title: 'Información Básica',
      description: 'Datos principales de la campaña',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Título de la campaña *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _tituloCtrl,
              decoration: _inputDecoration(
                'Ej: Ayuda para reconstrucción de escuela',
              ),
              maxLines: 1,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Título es obligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            _label('Descripción detallada *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: _inputDecoration(
                'Describe la situación, qué ayuda necesitas...',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Descripción es obligatoria'
                  : null,
            ),
            const SizedBox(height: 12),
            _label('Categoría *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId == null
                  ? null
                  : '$_selectedCategoryId',
              isExpanded: true,
              items: categoryItems,
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value == null ? null : int.parse(value);
                });
              },
              decoration: _inputDecoration('Selecciona una categoría'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Categoría es obligatoria'
                  : null,
            ),
            const SizedBox(height: 12),
            _label('Departamento *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              isExpanded: true,
              items: departmentItems,
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                  _selectedCityId = null;
                });
              },
              decoration: _inputDecoration('Departamento'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Departamento es obligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            _label('Ciudad *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedCityId == null ? null : '$_selectedCityId',
              isExpanded: true,
              items: cityItems,
              onChanged: (value) {
                setState(() {
                  _selectedCityId = value == null ? null : int.parse(value);
                });
              },
              decoration: _inputDecoration('Selecciona una ciudad'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ciudad es obligatoria'
                  : null,
            ),
            const SizedBox(height: 12),
            _label('Tipo de ayuda *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedHelpType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'economica', child: Text('Económica')),
                DropdownMenuItem(value: 'alimentos', child: Text('Alimentos')),
                DropdownMenuItem(value: 'ropa', child: Text('Ropa')),
                DropdownMenuItem(
                  value: 'medicamentos',
                  child: Text('Medicamentos'),
                ),
                DropdownMenuItem(value: 'mixta', child: Text('Mixta')),
              ],
              onChanged: (value) =>
                  setState(() => _selectedHelpType = value ?? 'economica'),
              decoration: _inputDecoration('Tipo de ayuda'),
            ),
            const SizedBox(height: 12),
            _label('Meta de recaudación (COP) *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _metaCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Ej: 50000000'),
              maxLines: 1,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Meta es obligatoria' : null,
            ),
            const SizedBox(height: 12),
            _label('Fecha límite *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _fechaFinCtrl,
              decoration: _inputDecoration('YYYY-MM-DD'),
              maxLines: 1,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Fecha límite es obligatoria'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerCard() {
    return _card(
      title: 'Información del Organizador',
      description: 'Datos de contacto del responsable',
      height: 243.59,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Inserte número de Cuenta o Bre-B'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _cuentaCtrl,
              decoration: _inputDecoration('Ej: @tucuenta123'),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _label('Correo de contacto *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _correoCtrl,
              decoration: _inputDecoration('Ej: contacto@campana.org'),
              maxLines: 1,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Correo es obligatorio'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCard() {
    return _card(
      title: 'Evidencias y Documentos',
      description: 'Adjunta documentos que respalden tu campaña',
      height: 274.77,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.8, 24.79, 24.8, 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 163.19,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1.6,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_outlined,
                    size: 40,
                    color: Color(0xFF717182),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Documentos oficiales, fotos, enlaces a medios',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.33,
                      color: Color(0xFF717182),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _pickAttachments,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(153.6, 32),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.black.withOpacity(0.1),
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: const Color(0xFF0A0A0A),
                    ),
                    child: const Text(
                      'Seleccionar archivos',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_attachments.length} archivo(s) seleccionado(s)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF717182),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return _card(
      title: 'Puntos de Recolección (Opcional)',
      description: 'Ubicaciones para donaciones físicas',
      height: 143.59 + (_draftPoints.isEmpty ? 0 : 44.0 * _draftPoints.length),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.8, 24, 24.8, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              onPressed: _openPointModal,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 32),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.black.withOpacity(0.1),
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: const Color(0xFF0A0A0A),
              ),
              child: const Text(
                'Agregar punto de recolección',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
            ),
            if (_draftPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._draftPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: Text(
                      '${point.nombre} · ${point.direccion}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
      'meta_monetaria': double.parse(_metaCtrl.text.trim()),
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
          'horario': point.horario,
          'contacto': _correoCtrl.text.trim(),
        });
      }
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 54,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'I',
                      style: TextStyle(
                        fontFamily: 'Audiowide',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Crear Campaña',
                    style: TextStyle(
                      fontFamily: 'Segoe UI Emoji',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loadingOptions
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      children: [
                        _buildBasicsCard(),
                        const SizedBox(height: 16),
                        _buildOrganizerCard(),
                        const SizedBox(height: 16),
                        _buildEvidenceCard(),
                        const SizedBox(height: 16),
                        _buildPointsCard(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          _submit();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(36),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _submitting ? 'Creando...' : 'Crear Campaña',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.43,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _submitting ? null : () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(88, 36),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.black.withOpacity(0.1),
                                  width: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                foregroundColor: const Color(0xFF0A0A0A),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Las campañas serán verificadas en 24-48 horas antes de publicarse.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 1.33,
                            color: Color(0xFF717182),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
