import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/error/error_mapper.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../controllers/campaign_detail_controller.dart';
import '../widgets/create_campaign/campaign_card_wrapper.dart';

class EditCampaignPage extends StatefulWidget {
  const EditCampaignPage({super.key});

  @override
  State<EditCampaignPage> createState() => _EditCampaignPageState();
}

class _EditCampaignPageState extends State<EditCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _metaCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _cuentaCtrl = TextEditingController();

  final CampaignDetailController _controller = Get.find<CampaignDetailController>();
  final CampaignRepository _repository = Get.find<CampaignRepository>();

  final List<Map<String, dynamic>> _cities = [];
  final List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _saving = false;
  String _selectedHelpType = 'economica';
  String? _selectedDepartment;
  int? _selectedCityId;
  int? _selectedCategoryId;
  late int _campaignId;

  @override
  void initState() {
    super.initState();
    _campaignId = int.parse(Get.parameters['id'] ?? '0');
    _load();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _metaCtrl.dispose();
    _fechaFinCtrl.dispose();
    _cuentaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      var campaign = _controller.campaign.value;
      if (campaign == null || campaign.idCampania != _campaignId) {
        await _controller.loadCampaign(_campaignId);
        campaign = _controller.campaign.value;
      }
      final results = await Future.wait([
        _repository.getCities(),
        _repository.getCategories(),
      ]);
      if (!mounted) return;
      _cities
        ..clear()
        ..addAll(results[0].cast<Map<String, dynamic>>());
      _categories
        ..clear()
        ..addAll(results[1].cast<Map<String, dynamic>>());
      if (campaign != null) {
        _tituloCtrl.text = campaign.titulo;
        _descripcionCtrl.text = campaign.descripcion;
        _metaCtrl.text = campaign.metaMonetaria == 0
            ? ''
            : campaign.metaMonetaria.toStringAsFixed(0);
        _fechaFinCtrl.text = campaign.fechaFin;
        _cuentaCtrl.text = campaign.cuentaRecaudo ?? '';
        _selectedHelpType = campaign.tipoAyudaRequerida;
        _selectedCategoryId = campaign.idCategoria;
        _selectedCityId = campaign.idCiudad;
        final city = _cities.cast<Map<String, dynamic>?>().firstWhere(
              (c) => c?['id_ciudad'] == campaign!.idCiudad,
              orElse: () => null,
            );
        _selectedDepartment = city?['departamento']?.toString();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        friendlyError(e),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          (city) => (city['departamento'] ?? '').toString() == _selectedDepartment,
        )
        .toList();
  }

  InputDecoration _inputDecoration(String hint, {bool enabled = true}) {
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
      fillColor: enabled ? const Color(0xFFF3F3F5) : const Color(0xFFE5E7EB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
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

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now().add(const Duration(days: 1));
    try {
      initial = DateTime.parse(_fechaFinCtrl.text);
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime(2000)) ? DateTime.now().add(const Duration(days: 1)) : initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _fechaFinCtrl.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityId == null || _selectedCategoryId == null) return;
    final campaign = _controller.campaign.value;
    final payload = <String, dynamic>{
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'id_ciudad': _selectedCityId,
      'id_categoria': _selectedCategoryId,
      'tipo_ayuda_requerida': _selectedHelpType,
      'meta_monetaria': double.tryParse(_metaCtrl.text.trim()) ?? 0.0,
      'fecha_fin': _fechaFinCtrl.text.trim(),
    };
    if (campaign?.estado != 'activa') {
      payload['cuenta_recaudo'] = _cuentaCtrl.text.trim();
    }
    setState(() => _saving = true);
    final updated = await _controller.editCampaign(_campaignId, payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated != null) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final campaign = _controller.campaign.value;
    final cuentaBloqueada = campaign?.estado == 'activa';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        title: const Text('Editar campaña'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  CampaignCardWrapper(
                    title: 'Información de la campaña',
                    description: 'Actualiza los detalles descriptivos de tu campaña',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Título de la campaña *'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _tituloCtrl,
                            decoration: _inputDecoration('Título'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Título es obligatorio' : null,
                          ),
                          const SizedBox(height: 12),
                          _label('Descripción detallada *'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _descripcionCtrl,
                            maxLines: 3,
                            decoration: _inputDecoration('Descripción'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Descripción es obligatoria' : null,
                          ),
                          const SizedBox(height: 12),
                          _label('Categoría *'),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedCategoryId,
                            isExpanded: true,
                            items: _categories
                                .map((c) => DropdownMenuItem<int>(
                                      value: c['id_categoria'] as int?,
                                      child: Text((c['nombre'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategoryId = v),
                            decoration: _inputDecoration('Categoría'),
                            validator: (v) => v == null ? 'Categoría es obligatoria' : null,
                          ),
                          const SizedBox(height: 12),
                          _label('Departamento *'),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDepartment,
                            isExpanded: true,
                            items: _departments
                                .map((d) => DropdownMenuItem<String>(value: d, child: Text(d, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _selectedDepartment = v;
                              _selectedCityId = null;
                            }),
                            decoration: _inputDecoration('Departamento'),
                            validator: (v) => v == null || v.isEmpty ? 'Departamento es obligatorio' : null,
                          ),
                          const SizedBox(height: 12),
                          _label('Ciudad *'),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            initialValue: _availableCities.any((c) => c['id_ciudad'] == _selectedCityId) ? _selectedCityId : null,
                            isExpanded: true,
                            items: _availableCities
                                .map((c) => DropdownMenuItem<int>(
                                      value: c['id_ciudad'] as int?,
                                      child: Text((c['nombre'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCityId = v),
                            decoration: _inputDecoration('Ciudad'),
                            validator: (v) => v == null ? 'Ciudad es obligatoria' : null,
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
                              DropdownMenuItem(value: 'medicamentos', child: Text('Medicamentos')),
                              DropdownMenuItem(value: 'mixta', child: Text('Mixta')),
                            ],
                            onChanged: (v) => setState(() => _selectedHelpType = v ?? 'economica'),
                            decoration: _inputDecoration('Tipo de ayuda'),
                          ),
                          const SizedBox(height: 12),
                          _label('Meta de recaudación (COP)'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _metaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Ej: 500000'),
                          ),
                          const SizedBox(height: 12),
                          _label('Fecha límite *'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _fechaFinCtrl,
                            readOnly: true,
                            onTap: _pickDate,
                            decoration: _inputDecoration('YYYY-MM-DD').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF717182)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Fecha límite es obligatoria' : null,
                          ),
                          const SizedBox(height: 12),
                          _label('Cuenta de recaudo'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _cuentaCtrl,
                            enabled: !cuentaBloqueada,
                            decoration: _inputDecoration(
                              'Cuenta o llave de recaudo',
                              enabled: !cuentaBloqueada,
                            ),
                          ),
                          if (cuentaBloqueada) ...[
                            const SizedBox(height: 6),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lock_outline, size: 16, color: Color(0xFF717182)),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'No se puede modificar la cuenta de recaudo de una campaña verificada/aprobada.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF717182)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                  ),
                ],
              ),
            ),
    );
  }
}
