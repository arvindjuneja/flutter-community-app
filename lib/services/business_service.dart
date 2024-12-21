import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class BusinessService extends FirebaseService {
  BusinessService({
    super.firestore,
    super.auth,
    super.storage,
  });

  Future<List<Business>> getBusinesses({
    String? category,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = firestore
          .collection('businesses')
          .orderBy('name');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => Business.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting businesses: $e');
      rethrow;
    }
  }

  Future<Business> getBusinessById(String businessId) async {
    try {
      final doc = await firestore
          .collection('businesses')
          .doc(businessId)
          .get();

      if (!doc.exists) {
        throw Exception('Business not found');
      }

      return Business.fromFirestore(doc);
    } catch (e) {
      print('Error getting business by id: $e');
      rethrow;
    }
  }

  Future<Business> createBusiness({
    required String name,
    required String description,
    required String category,
    required String address,
    required GeoPoint location,
    String? phone,
    String? email,
    String? website,
    String? imageURL,
    Map<String, OpeningHours>? openingHours,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to create a business');
      }

      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User data not found');
      }

      final now = DateTime.now();
      final data = {
        'name': name,
        'description': description,
        'authorId': currentUserId,
        'category': category,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'imageURL': imageURL,
        'isVerified': false,
        'createdAt': now,
        'updatedAt': now,
        'openingHours': openingHours?.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
        'location': location,
      };

      final doc = await firestore.collection('businesses').add(data);
      return Business.fromFirestore(await doc.get());
    } catch (e) {
      print('Error creating business: $e');
      rethrow;
    }
  }

  Future<void> updateBusiness({
    required String businessId,
    String? name,
    String? description,
    String? category,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? imageURL,
    Map<String, OpeningHours>? openingHours,
    GeoPoint? location,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to update a business');
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (address != null) updates['address'] = address;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;
      if (website != null) updates['website'] = website;
      if (imageURL != null) updates['imageURL'] = imageURL;
      if (openingHours != null) {
        updates['openingHours'] = openingHours.map(
          (key, value) => MapEntry(key, value.toMap()),
        );
      }
      if (location != null) updates['location'] = location;

      await firestore
          .collection('businesses')
          .doc(businessId)
          .update(updates);
    } catch (e) {
      print('Error updating business: $e');
      rethrow;
    }
  }

  Future<void> deleteBusiness(String businessId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to delete a business');
      }

      final business = await getBusinessById(businessId);
      if (business.imageURL != null) {
        await deleteFile(business.imageURL!);
      }

      await firestore
          .collection('businesses')
          .doc(businessId)
          .delete();
    } catch (e) {
      print('Error deleting business: $e');
      rethrow;
    }
  }

  Future<void> verifyBusiness(String businessId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to verify a business');
      }

      final user = await getCurrentUser();
      if (user == null || user.role == UserRole.user) {
        throw Exception('Only editors and admins can verify businesses');
      }

      await firestore
          .collection('businesses')
          .doc(businessId)
          .update({
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error verifying business: $e');
      rethrow;
    }
  }

  Stream<List<Business>> watchBusinesses({
    String? category,
    int limit = 10,
  }) {
    try {
      var query = firestore
          .collection('businesses')
          .orderBy('name');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      return query
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Business.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error watching businesses: $e');
      rethrow;
    }
  }

  Future<List<Business>> searchBusinesses(String query) async {
    try {
      // This is a simple search implementation
      // For better search functionality, consider using Algolia or ElasticSearch
      final snapshot = await firestore
          .collection('businesses')
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return snapshot.docs.map((doc) => Business.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching businesses: $e');
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final snapshot = await firestore
          .collection('businesses')
          .get();

      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      print('Error getting categories: $e');
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