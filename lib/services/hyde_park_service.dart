import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class HydeParkService extends FirebaseService {
  HydeParkService({
    super.firestore,
    super.auth,
    super.storage,
  });

  Future<List<HydeParkPost>> getPosts({
    PostCategory? category,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = firestore
          .collection('hydeParkPosts')
          .where('status', isEqualTo: PostStatus.active.toString().split('.').last)
          .orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => HydeParkPost.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting posts: $e');
      rethrow;
    }
  }

  Future<HydeParkPost> getPostById(String postId) async {
    try {
      final doc = await firestore
          .collection('hydeParkPosts')
          .doc(postId)
          .get();

      if (!doc.exists) {
        throw Exception('Post not found');
      }

      return HydeParkPost.fromFirestore(doc);
    } catch (e) {
      print('Error getting post by id: $e');
      rethrow;
    }
  }

  Future<HydeParkPost> createPost({
    required String title,
    required String content,
    required PostCategory category,
    String? imageURL,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to create a post');
      }

      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User data not found');
      }

      final now = DateTime.now();
      final data = {
        'title': title,
        'content': content,
        'authorId': currentUserId,
        'authorName': user.name,
        'createdAt': now,
        'updatedAt': now,
        'likes': 0,
        'commentsCount': 0,
        'imageURL': imageURL,
        'isEdited': false,
        'category': category.toString().split('.').last,
        'status': PostStatus.active.toString().split('.').last,
      };

      final doc = await firestore.collection('hydeParkPosts').add(data);
      return HydeParkPost.fromFirestore(await doc.get());
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> updatePost({
    required String postId,
    String? title,
    String? content,
    PostCategory? category,
    String? imageURL,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to update a post');
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      };

      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (category != null) {
        updates['category'] = category.toString().split('.').last;
      }
      if (imageURL != null) updates['imageURL'] = imageURL;

      await firestore
          .collection('hydeParkPosts')
          .doc(postId)
          .update(updates);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to delete a post');
      }

      final post = await getPostById(postId);
      if (post.imageURL != null) {
        await deleteFile(post.imageURL!);
      }

      await firestore
          .collection('hydeParkPosts')
          .doc(postId)
          .update({
        'status': PostStatus.deleted.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to like a post');
      }

      final likeRef = firestore
          .collection('hydeParkPosts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId);

      final likeDoc = await likeRef.get();
      
      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await firestore
            .collection('hydeParkPosts')
            .doc(postId)
            .update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'createdAt': FieldValue.serverTimestamp(),
        });
        await firestore
            .collection('hydeParkPosts')
            .doc(postId)
            .update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }

  Stream<List<HydeParkPost>> watchPosts({
    PostCategory? category,
    int limit = 10,
  }) {
    try {
      var query = firestore
          .collection('hydeParkPosts')
          .where('status', isEqualTo: PostStatus.active.toString().split('.').last)
          .orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      return query
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => HydeParkPost.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error watching posts: $e');
      rethrow;
    }
  }

  Future<List<HydeParkPost>> getUserPosts() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to get their posts');
      }

      final snapshot = await firestore
          .collection('hydeParkPosts')
          .where('authorId', isEqualTo: currentUserId)
          .where('status', isEqualTo: PostStatus.active.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => HydeParkPost.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user posts: $e');
      rethrow;
    }
  }

  Future<bool> isPostLiked(String postId) async {
    try {
      if (!isAuthenticated) return false;

      final likeDoc = await firestore
          .collection('hydeParkPosts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking if post is liked: $e');
      return false;
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