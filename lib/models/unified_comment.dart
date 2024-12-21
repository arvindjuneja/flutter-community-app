import 'package:cloud_firestore/cloud_firestore.dart';

enum CommentTargetType { news, hydePark, business }

class UnifiedComment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String? parentId;
  final String targetId;
  final CommentTargetType targetType;
  final int likes;
  final bool isEdited;
  final String? threadTitle;

  const UnifiedComment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.parentId,
    required this.targetId,
    required this.targetType,
    required this.likes,
    required this.isEdited,
    this.threadTitle,
  });

  factory UnifiedComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnifiedComment(
      id: doc.id,
      content: data['content'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      parentId: data['parentId'] as String?,
      targetId: data['targetId'] as String,
      targetType: CommentTargetType.values.firstWhere(
        (e) => e.toString() == 'CommentTargetType.${data['targetType']}',
        orElse: () => CommentTargetType.news,
      ),
      likes: data['likes'] as int? ?? 0,
      isEdited: data['isEdited'] as bool? ?? false,
      threadTitle: data['threadTitle'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentId': parentId,
      'targetId': targetId,
      'targetType': targetType.toString().split('.').last,
      'likes': likes,
      'isEdited': isEdited,
      'threadTitle': threadTitle,
    };
  }

  UnifiedComment copyWith({
    String? content,
    String? authorName,
    String? parentId,
    int? likes,
    bool? isEdited,
    String? threadTitle,
  }) {
    return UnifiedComment(
      id: id,
      content: content ?? this.content,
      authorId: authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt,
      parentId: parentId ?? this.parentId,
      targetId: targetId,
      targetType: targetType,
      likes: likes ?? this.likes,
      isEdited: isEdited ?? this.isEdited,
      threadTitle: threadTitle ?? this.threadTitle,
    );
  }
} 