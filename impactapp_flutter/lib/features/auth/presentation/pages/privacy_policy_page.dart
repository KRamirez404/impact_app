import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final Dio _dio;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _policy;

  @override
  void initState() {
    super.initState();
    _dio = DioClient.instance.dio;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(ApiConstants.privacyPolicy);
      if (!mounted) return;
      setState(() {
        _policy = (response.data as Map<String, dynamic>?) ?? {};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible cargar la política. Verifica tu conexión.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Política de privacidad',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final policy = _policy ?? {};
    final List<String> finalidades =
        ((policy['finalidades'] as List?) ?? []).map((e) => e.toString()).toList();
    final List<String> derechos =
        ((policy['derechos'] as List?) ?? []).map((e) => e.toString()).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            policy['titulo'] ?? 'Política de Tratamiento de Datos Personales',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0A0A0A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Norma: ${policy['norma'] ?? 'Ley 1581 de 2012'}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF717182)),
          ),
          const SizedBox(height: 16),
          Text(
            'Responsable del tratamiento: ${policy['responsable'] ?? ''}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Finalidades del tratamiento'),
          const SizedBox(height: 8),
          ...finalidades.map((item) => _bullet(item)),
          const SizedBox(height: 24),
          _sectionTitle('Derechos del titular'),
          const SizedBox(height: 8),
          ...derechos.map((item) => _bullet(item)),
          const SizedBox(height: 24),
          _sectionTitle('Canal de atención'),
          const SizedBox(height: 8),
          Text(
            policy['canal'] ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A), height: 1.5),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Vigencia'),
          const SizedBox(height: 8),
          Text(
            policy['vigencia'] ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A), height: 1.5),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1976D2)),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF1976D2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
