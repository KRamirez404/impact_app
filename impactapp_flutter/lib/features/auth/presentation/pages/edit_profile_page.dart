import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final AuthController _controller = Get.find<AuthController>();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = _controller.user.value;
    if (user != null) {
      final fullName = '${user.nombre} ${user.apellido}'.trim();
      _fullNameCtrl.text = fullName;
      _emailCtrl.text = user.correo;
      _phoneCtrl.text = user.telefono ?? '';
      _bioCtrl.text = user.biografia ?? '';
    }
    _fullNameCtrl.addListener(_onNameChanged);
    _bioCtrl.addListener(_onBioChanged);
  }

  @override
  void dispose() {
    _bioCtrl.removeListener(_onBioChanged);
    _fullNameCtrl.removeListener(_onNameChanged);
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _onBioChanged() => setState(() {});
  void _onNameChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = _controller.user.value;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 412),
                    child: Column(
                      children: [
                        _buildHero(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  icon: Icons.person_outline,
                                  title: 'Información Personal',
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _fullNameCtrl,
                                  label: 'Nombre completo',
                                  hint: 'María González',
                                  icon: Icons.person_outline,
                                  validator: (value) => Validators.requiredField(value, 'Nombre completo'),
                                  isRequired: true,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _emailCtrl,
                                  label: 'Correo electrónico',
                                  hint: 'maria.gonzalez@email.com',
                                  icon: Icons.mail_outline,
                                  validator: Validators.email,
                                  isRequired: true,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Este será tu correo de contacto público',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _phoneCtrl,
                                  label: 'Teléfono (opcional)',
                                  hint: '+57 300 123 4567',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 24),
                                _buildSectionTitle(
                                  icon: Icons.description_outlined,
                                  title: 'Sobre ti',
                                ),
                                const SizedBox(height: 16),
                                _buildBioField(),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${_bioCtrl.text.length}/500 caracteres',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildTipCard(),
                                const SizedBox(height: 24),
                                _buildAccountInfo(user?.fechaRegistro),
                                const SizedBox(height: 24),
                                _buildActions(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Text(
            'Editar Perfil',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF43A047)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: _selectedImage != null
                        ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                        : (_controller.user.value?.fotoPerfil != null
                            ? Image.network('${ApiConstants.baseUrl.replaceAll('/api', '')}${_controller.user.value!.fotoPerfil}', fit: BoxFit.cover)
                            : CircleAvatar(
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                child: Text(
                                  _fullNameCtrl.text.isNotEmpty
                                      ? _fullNameCtrl.text.trim().substring(0, 1).toUpperCase()
                                      : 'I',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Toca para cambiar foto',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            if (isRequired)
              const Text(' *', style: TextStyle(fontSize: 14, color: Color(0xFFD4183D))),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBg,
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biografía (opcional)',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _bioCtrl,
          maxLines: 4,
          maxLength: 500,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.5),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBg,
            isDense: true,
            counterText: '',
            hintText: 'Cuéntanos un poco sobre ti, tus intereses o cómo te gusta ayudar...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '💡 Consejo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Un perfil completo genera más confianza en la comunidad.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(String? fechaRegistro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1A000000))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de cuenta',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Miembro desde',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                _formatMemberSince(fechaRegistro),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _controller.isUpdatingProfile.value ? null : _saveChanges,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: Text(_controller.isUpdatingProfile.value ? 'Guardando...' : 'Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x1A000000)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              foregroundColor: AppColors.textPrimary,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final ext = picked.name.split('.').last.toLowerCase();
      if (ext == 'avif' || ext == 'heic' || ext == 'heif') {
        final bytes = await picked.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final jpegBytes = img.encodeJpg(decoded, quality: 90);
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(jpegBytes);
          setState(() => _selectedImage = XFile(tempFile.path));
          return;
        }
      }
      setState(() => _selectedImage = picked);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final fullName = _fullNameCtrl.text.trim();
    final parts = _splitFullName(fullName);
    final telefono = _phoneCtrl.text.trim();
    final biografia = _bioCtrl.text.trim();

    String? fotoPerfilUrl = _controller.user.value?.fotoPerfil;
    if (_selectedImage != null) {
      _controller.isUpdatingProfile.value = true;
      try {
        fotoPerfilUrl = await DioClient.instance.uploadFile(_selectedImage!.path);
      } catch (e) {
        _controller.isUpdatingProfile.value = false;
        _controller.showError('Error al subir imagen: $e');
        return;
      }
    }

    final success = await _controller.updateProfile(
      nombre: parts.$1,
      apellido: parts.$2,
      correo: _emailCtrl.text.trim(),
      telefono: telefono.isEmpty ? null : telefono,
      biografia: biografia.isEmpty ? null : biografia,
      fotoPerfil: fotoPerfilUrl,
    );
    if (success && mounted) {
      Get.back();
    }
  }

  (String, String) _splitFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return ('', '');
    final parts = trimmed.split(RegExp(r'\s+'));
    final nombre = parts.first;
    final apellido = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return (nombre, apellido);
  }

  String _formatMemberSince(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'No disponible';
    try {
      final parsed = DateTime.parse(isoDate);
      const months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${months[parsed.month - 1]} de ${parsed.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
