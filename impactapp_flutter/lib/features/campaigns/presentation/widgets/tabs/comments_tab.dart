import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../ratings/infrastructure/datasources/rating_remote_datasource.dart';
import '../../../../ratings/infrastructure/repositories/rating_repository_impl.dart';

class CommentsTab extends StatefulWidget {
  final int campaignId;
  final List<Map<String, dynamic>> comments;
  final Future<void> Function() onCommentPublished;

  const CommentsTab({
    super.key,
    required this.campaignId,
    required this.comments,
    required this.onCommentPublished,
  });

  @override
  State<CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<CommentsTab> {
  final TextEditingController _commentController = TextEditingController();
  var _isPublishingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _publishComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        'Comentario vacío',
        'Escribe algo antes de publicar',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    if (!Get.isRegistered<AuthController>() || Get.find<AuthController>().user.value == null) {
      Get.snackbar(
        'Inicia sesión',
        'Debes iniciar sesión para comentar',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isPublishingComment = true);
    final repository = RatingRepositoryImpl(RatingRemoteDataSource());
    try {
      await repository.rateCampaign(
        idCampania: widget.campaignId,
        calificacion: 5,
        comentario: text,
      );
      _commentController.clear();
      await widget.onCommentPublished();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic> ? data['error']?.toString() : null;
      if (!mounted) return;
      Get.snackbar(
        'Error',
        message ?? 'No se pudo publicar el comentario',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isPublishingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Get.isRegistered<AuthController>() ? Get.find<AuthController>().user.value : null;
    final userInitials = authUser != null
        ? '${authUser.nombre.isNotEmpty ? authUser.nombre[0] : ''}${authUser.apellido.isNotEmpty ? authUser.apellido[0] : ''}'
            .toUpperCase()
        : '?';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1976D2),
                child: Text(
                  userInitials.isEmpty ? '?' : userInitials,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      minLines: 2,
                      enabled: !_isPublishingComment,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF717182)),
                        filled: true,
                        fillColor: const Color(0xFFF3F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isPublishingComment ? null : _publishComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(75, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isPublishingComment
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Publicar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (widget.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No hay comentarios aún',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF717182),
                    fontFamily: 'Segoe UI Emoji',
                  ),
                ),
              ],
            ),
          )
        else
          ...widget.comments.map((comment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CommentCard(comment: comment),
              )),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final Map<String, dynamic> comment;

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = comment['usuario'] as Map<String, dynamic>?;
    final nombre = usuario != null
        ? '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim()
        : 'Usuario';
    final initials = nombre.isNotEmpty
        ? nombre.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase()
        : 'U';
    final body = (comment['comentario'] ?? '').toString();
    final fecha = _formatDate((comment['fecha_valoracion'] ?? '').toString());
    final calificacion = (comment['calificacion'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFECECF0),
            child: Text(
              initials,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre.isEmpty ? 'Usuario' : nombre,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(fecha, style: const TextStyle(fontSize: 12, color: Color(0xFF717182))),
                  ],
                ),
                if (calificacion > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < calificacion ? Icons.star : Icons.star_border,
                        size: 14,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF717182))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
