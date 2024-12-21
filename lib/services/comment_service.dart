import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class CommentService extends FirebaseService {
  CommentService({
    super.firestore,
    super.auth,
    super.storage,
  });

  Future<List<UnifiedComment>> getComments({
    required String targetId,
    required CommentTargetType targetType,
    String? parentId,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = firestore
          .collection('comments')
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType.toString().split('.').last)
          .orderBy('createdAt', descending: true);

      if (parentId != null) {
        query = query.where('parentId', isEqualTo: parentId);
      } else {
        query = query.where('parentId', isNull: true);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => UnifiedComment.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting comments: $e');
      rethrow;
    }
  }

  Future<UnifiedComment> createComment({
    required String content,
    required String targetId,
    required CommentTargetType targetType,
    String? parentId,
    String? threadTitle,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to create a comment');
      }

      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User data not found');
      }

      final data = {
        'content': content,
        'authorId': currentUserId,
        'authorName': user.name,
        'createdAt': FieldValue.serverTimestamp(),
        'parentId': parentId,
        'targetId': targetId,
        'targetType': targetType.toString().split('.').last,
        'likes': 0,
        'isEdited': false,
        'threadTitle': threadTitle,
      };

      final doc = await firestore.collection('comments').add(data);
      await _incrementCommentsCount(targetId, targetType);
      return UnifiedComment.fromFirestore(await doc.get());
    } catch (e) {
      print('Error creating comment: $e');
      rethrow;
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to update a comment');
      }

      await firestore
          .collection('comments')
          .doc(commentId)
          .update({
        'content': content,
        'isEdited': true,
      });
    } catch (e) {
      print('Error updating comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to delete a comment');
      }

      final comment = await firestore
          .collection('comments')
          .doc(commentId)
          .get();

      if (!comment.exists) {
        throw Exception('Comment not found');
      }

      final data = comment.data() as Map<String, dynamic>;
      await _decrementCommentsCount(
        data['targetId'] as String,
        CommentTargetType.values.firstWhere(
          (e) => e.toString() == 'CommentTargetType.${data['targetType']}',
        ),
      );

      await firestore
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to like a comment');
      }

      final likeRef = firestore
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(currentUserId);

      final likeDoc = await likeRef.get();
      
      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await firestore
            .collection('comments')
            .doc(commentId)
            .update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'createdAt': FieldValue.serverTimestamp(),
        });
        await firestore
            .collection('comments')
            .doc(commentId)
            .update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error liking comment: $e');
      rethrow;
    }
  }

  Stream<List<UnifiedComment>> watchComments({
    required String targetId,
    required CommentTargetType targetType,
    String? parentId,
    int limit = 10,
  }) {
    try {
      var query = firestore
          .collection('comments')
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType.toString().split('.').last)
          .orderBy('createdAt', descending: true);

      if (parentId != null) {
        query = query.where('parentId', isEqualTo: parentId);
      } else {
        query = query.where('parentId', isNull: true);
      }

      return query
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => UnifiedComment.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error watching comments: $e');
      rethrow;
    }
  }

  Future<bool> isCommentLiked(String commentId) async {
    try {
      if (!isAuthenticated) return false;

      final likeDoc = await firestore
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(currentUserId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking if comment is liked: $e');
      return false;
    }
  }

  Future<void> _incrementCommentsCount(String targetId, CommentTargetType targetType) async {
    try {
      final collection = _getTargetCollection(targetType);
      await firestore
          .collection(collection)
          .doc(targetId)
          .update({
        'commentsCount': FieldValue.increment(1),
        'lastCommentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing comments count: $e');
      // We don't want to rethrow here as this is not critical
    }
  }

  Future<void> _decrementCommentsCount(String targetId, CommentTargetType targetType) async {
    try {
      final collection = _getTargetCollection(targetType);
      await firestore
          .collection(collection)
          .doc(targetId)
          .update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error decrementing comments count: $e');
      // We don't want to rethrow here as this is not critical
    }
  }

  String _getTargetCollection(CommentTargetType targetType) {
    switch (targetType) {
      case CommentTargetType.news:
        return 'news';
      case CommentTargetType.hydePark:
        return 'hydeParkPosts';
      case CommentTargetType.business:
        return 'businesses';
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      if (!isAuthenticated) return null;

      final doc = await firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (!doc.exists) return null;

      return User.fromFirestore(doc);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
} 