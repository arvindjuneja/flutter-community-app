import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class NewsService extends FirebaseService {
  NewsService({
    super.firestore,
    super.auth,
    super.storage,
  });

  Future<List<News>> getNews({
    NewsCategory? category,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = firestore
          .collection('news')
          .where('isPublished', isEqualTo: true)
          .orderBy('publishedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => News.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting news: $e');
      rethrow;
    }
  }

  Future<News> getNewsById(String newsId) async {
    try {
      final doc = await firestore
          .collection('news')
          .doc(newsId)
          .get();

      if (!doc.exists) {
        throw Exception('News article not found');
      }

      return News.fromFirestore(doc);
    } catch (e) {
      print('Error getting news by id: $e');
      rethrow;
    }
  }

  Future<News> createNews({
    required String title,
    required String content,
    required NewsCategory category,
    String? imageURL,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to create news');
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
        'publishedAt': now,
        'isPublished': user.role != UserRole.user, // Auto-publish for editors and admins
        'imageURL': imageURL,
        'commentsCount': 0,
        'category': category.toString().split('.').last,
        'isVerifiedAuthor': user.isVerified,
      };

      final doc = await firestore.collection('news').add(data);
      return News.fromFirestore(await doc.get());
    } catch (e) {
      print('Error creating news: $e');
      rethrow;
    }
  }

  Future<void> updateNews({
    required String newsId,
    String? title,
    String? content,
    NewsCategory? category,
    String? imageURL,
    bool? isPublished,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to update news');
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (category != null) {
        updates['category'] = category.toString().split('.').last;
      }
      if (imageURL != null) updates['imageURL'] = imageURL;
      if (isPublished != null) {
        updates['isPublished'] = isPublished;
        if (isPublished) {
          updates['publishedAt'] = FieldValue.serverTimestamp();
        }
      }

      await firestore
          .collection('news')
          .doc(newsId)
          .update(updates);
    } catch (e) {
      print('Error updating news: $e');
      rethrow;
    }
  }

  Future<void> deleteNews(String newsId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to delete news');
      }

      final news = await getNewsById(newsId);
      if (news.imageURL != null) {
        await deleteFile(news.imageURL!);
      }

      await firestore
          .collection('news')
          .doc(newsId)
          .delete();
    } catch (e) {
      print('Error deleting news: $e');
      rethrow;
    }
  }

  Stream<List<News>> watchNews({
    NewsCategory? category,
    int limit = 10,
  }) {
    try {
      var query = firestore
          .collection('news')
          .where('isPublished', isEqualTo: true)
          .orderBy('publishedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      return query
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => News.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error watching news: $e');
      rethrow;
    }
  }

  Future<List<News>> getDraftNews() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to get draft news');
      }

      final snapshot = await firestore
          .collection('news')
          .where('authorId', isEqualTo: currentUserId)
          .where('isPublished', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => News.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting draft news: $e');
      rethrow;
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