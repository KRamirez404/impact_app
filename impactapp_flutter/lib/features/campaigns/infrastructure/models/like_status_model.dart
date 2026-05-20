import '../../domain/entities/like_status_entity.dart';

class LikeStatusModel extends LikeStatusEntity {
  const LikeStatusModel({
    required super.likesCount,
    required super.liked,
  });

  factory LikeStatusModel.fromJson(Map<String, dynamic> json) {
    return LikeStatusModel(
      likesCount: json['likes_count'] ?? 0,
      liked: json['liked'] ?? false,
    );
  }
}
