import 'package:flutter/material.dart';

import '../controllers/campaign_list_controller.dart';

class ExploreFiltersSheet extends StatefulWidget {
  const ExploreFiltersSheet({
    super.key,
    required this.controller,
  });

  final CampaignListController controller;

  @override
  State<ExploreFiltersSheet> createState() => _ExploreFiltersSheetState();
}

class _ExploreFiltersSheetState extends State<ExploreFiltersSheet> {
  static const _categoryOptions = <String>[
    'Salud',
    'Educación',
    'Vivienda',
    'Desastre Natural',
    'Alimentación',
    'Otros',
  ];

  static const _cityOptions = <String>[
    'Antioquia',
    'Amazonas',
    'Arauca',
    'Atlántico',
    'Bogotá D.C.',
    'Bolívar',
    'Boyacá',
    'Caldas',
    'Caquetá',
    'Casanare',
    'Cauca',
    'Cesar',
    'Chocó',
    'Córdoba',
    'Cundinamarca',
    'Guainía',
    'Guaviare',
    'Huila',
    'La Guajira',
    'Magdalena',
    'Meta',
    'Nariño',
    'Norte de Santander',
    'Putumayo',
    'Quindío',
    'Risaralda',
    'San Andrés y Providencia',
    'Santander',
    'Sucre',
    'Tolima',
    'Valle del Cauca',
    'Vaupés',
    'Vichada',
  ];

  late final List<String> _selectedCategories;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.controller.selectedCategoryLabels.toList();
    _selectedCity = widget.controller.selectedCityLabel.value ?? 'Antioquia';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 631,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 0.8)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Filtros de Búsqueda',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Personaliza tu búsqueda de campañas',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.43,
                      color: Color(0xFF717182),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 27, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Categorías'),
                    const SizedBox(height: 12),
                    const _SectionHint('✓ Selecciona una o más categorías'),
                    const SizedBox(height: 16),
                    ..._categoryOptions.map(
                      (label) => _CheckboxRow(
                        label: label,
                        selected: _selectedCategories.contains(label),
                        onTap: () {
                          setState(() {
                            if (_selectedCategories.contains(label)) {
                              _selectedCategories.remove(label);
                            } else {
                              _selectedCategories.add(label);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Ubicación'),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCity,
                            isExpanded: true,
                            items: _cityOptions
                                .map(
                                  (city) => DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(
                                      city,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.43,
                                        color: Color(0xFF0A0A0A),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF1976D2), size: 20),
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.9), width: 0.8),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.9), width: 0.8),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1976D2), width: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  Container(height: 1, color: const Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.controller.setFilters(
                          categoryLabels: _selectedCategories,
                          cityLabel: _selectedCity,
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Ver resultados',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: Color(0xFF0A0A0A),
      ),
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        height: 1.33,
        color: Color(0xFF717182),
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF008236) : Colors.white,
                  border: Border.all(color: const Color(0xFF008236), width: 1.2),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.0,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
