import 'package:cloud_firestore/cloud_firestore.dart';

class OpeningHours {
  final String open;
  final String close;
  final bool isClosed;

  const OpeningHours({
    required this.open,
    required this.close,
    this.isClosed = false,
  });

  factory OpeningHours.fromMap(Map<String, dynamic> data) {
    return OpeningHours(
      open: data['open'] as String,
      close: data['close'] as String,
      isClosed: data['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'open': open,
      'close': close,
      'isClosed': isClosed,
    };
  }
}

class Business {
  final String id;
  final String name;
  final String description;
  final String authorId;
  final String category;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final String? imageURL;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, OpeningHours>? openingHours;
  final GeoPoint location;

  const Business({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.category,
    required this.address,
    this.phone,
    this.email,
    this.website,
    this.imageURL,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.openingHours,
    required this.location,
  });

  factory Business.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Business(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      authorId: data['authorId'] as String,
      category: data['category'] as String,
      address: data['address'] as String,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      imageURL: data['imageURL'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      openingHours: data['openingHours'] != null
          ? (data['openingHours'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                OpeningHours.fromMap(value as Map<String, dynamic>),
              ),
            )
          : null,
      location: data['location'] as GeoPoint,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'authorId': authorId,
      'category': category,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'imageURL': imageURL,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'openingHours': openingHours?.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'location': location,
    };
  }

  Business copyWith({
    String? name,
    String? description,
    String? category,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? imageURL,
    bool? isVerified,
    DateTime? updatedAt,
    Map<String, OpeningHours>? openingHours,
    GeoPoint? location,
  }) {
    return Business(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      authorId: authorId,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      imageURL: imageURL ?? this.imageURL,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      openingHours: openingHours ?? this.openingHours,
      location: location ?? this.location,
    );
  }
} 