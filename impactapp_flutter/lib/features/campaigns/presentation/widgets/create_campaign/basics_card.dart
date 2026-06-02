import 'package:flutter/material.dart';
import 'campaign_card_wrapper.dart';

class BasicsCard extends StatelessWidget {
  const BasicsCard({
    super.key,
    required this.tituloCtrl,
    required this.descripcionCtrl,
    required this.metaCtrl,
    required this.fechaFinCtrl,
    required this.categories,
    required this.departments,
    required this.availableCities,
    required this.selectedCategoryId,
    required this.selectedDepartment,
    required this.selectedCityId,
    required this.selectedHelpType,
    required this.onCategoryChanged,
    required this.onDepartmentChanged,
    required this.onCityChanged,
    required this.onHelpTypeChanged,
  });

  final TextEditingController tituloCtrl;
  final TextEditingController descripcionCtrl;
  final TextEditingController metaCtrl;
  final TextEditingController fechaFinCtrl;
  final List<Map<String, dynamic>> categories;
  final List<String> departments;
  final List<Map<String, dynamic>> availableCities;
  final int? selectedCategoryId;
  final String? selectedDepartment;
  final int? selectedCityId;
  final String selectedHelpType;
  final void Function(int?) onCategoryChanged;
  final void Function(String?) onDepartmentChanged;
  final void Function(int?) onCityChanged;
  final void Function(String?) onHelpTypeChanged;

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

  @override
  Widget build(BuildContext context) {
    final categoryItems = categories
        .map((c) => DropdownMenuItem<String>(
              value: '${c['id_categoria']}',
              child: Text(
                (c['nombre'] ?? '').toString(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 14, height: 1.43, color: Color(0xFF0A0A0A),
                ),
              ),
            ))
        .toList();
    final departmentItems = departments
        .map((dept) => DropdownMenuItem<String>(
              value: dept,
              child: Text(
                dept,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 14, height: 1.43, color: Color(0xFF0A0A0A),
                ),
              ),
            ))
        .toList();
    final cityItems = availableCities
        .map((city) => DropdownMenuItem<String>(
              value: '${city['id_ciudad']}',
              child: Text(
                (city['nombre'] ?? '').toString(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 14, height: 1.43, color: Color(0xFF0A0A0A),
                ),
              ),
            ))
        .toList();

    return CampaignCardWrapper(
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
              controller: tituloCtrl,
              decoration: _inputDecoration('Ej: Ayuda para reconstrucción de escuela'),
              maxLines: 1,
              validator: (v) => v == null || v.trim().isEmpty ? 'Título es obligatorio' : null,
            ),
            const SizedBox(height: 12),
            _label('Descripción detallada *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: descripcionCtrl,
              maxLines: 3,
              decoration: _inputDecoration('Describe la situación, qué ayuda necesitas...'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Descripción es obligatoria' : null,
            ),
            const SizedBox(height: 12),
            _label('Categoría *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: selectedCategoryId == null ? null : '$selectedCategoryId',
              isExpanded: true,
              items: categoryItems,
              onChanged: (value) => onCategoryChanged(value == null ? null : int.parse(value)),
              decoration: _inputDecoration('Selecciona una categoría'),
              validator: (value) => value == null || value.isEmpty ? 'Categoría es obligatoria' : null,
            ),
            const SizedBox(height: 12),
            _label('Departamento *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: selectedDepartment,
              isExpanded: true,
              items: departmentItems,
              onChanged: onDepartmentChanged,
              decoration: _inputDecoration('Departamento'),
              validator: (value) => value == null || value.isEmpty ? 'Departamento es obligatorio' : null,
            ),
            const SizedBox(height: 12),
            _label('Ciudad *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: selectedCityId == null ? null : '$selectedCityId',
              isExpanded: true,
              items: cityItems,
              onChanged: (value) => onCityChanged(value == null ? null : int.parse(value)),
              decoration: _inputDecoration('Selecciona una ciudad'),
              validator: (value) => value == null || value.isEmpty ? 'Ciudad es obligatoria' : null,
            ),
            const SizedBox(height: 12),
            _label('Tipo de ayuda *'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: selectedHelpType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'economica', child: Text('Económica')),
                DropdownMenuItem(value: 'alimentos', child: Text('Alimentos')),
                DropdownMenuItem(value: 'ropa', child: Text('Ropa')),
                DropdownMenuItem(value: 'medicamentos', child: Text('Medicamentos')),
                DropdownMenuItem(value: 'mixta', child: Text('Mixta')),
              ],
              onChanged: onHelpTypeChanged,
              decoration: _inputDecoration('Tipo de ayuda'),
            ),
            const SizedBox(height: 12),
            _label(selectedHelpType == 'economica' || selectedHelpType == 'mixta'
                ? 'Meta de recaudación (COP) *'
                : 'Meta de recaudación (COP) (Opcional)'),
            const SizedBox(height: 4),
            TextFormField(
              controller: metaCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Ej: 50000000'),
              maxLines: 1,
              validator: (v) {
                if (selectedHelpType == 'economica' || selectedHelpType == 'mixta') {
                  if (v == null || v.trim().isEmpty) {
                    return 'Meta es obligatoria';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _label('Fecha límite *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: fechaFinCtrl,
              decoration: _inputDecoration('YYYY-MM-DD'),
              maxLines: 1,
              validator: (v) => v == null || v.trim().isEmpty ? 'Fecha límite es obligatoria' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter', fontSize: 14, height: 1.43, color: Color(0xFF0A0A0A),
      ),
    );
  }
}
