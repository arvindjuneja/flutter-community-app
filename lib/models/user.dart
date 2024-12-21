import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, editor, admin }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isVerified;
  final String? avatarURL;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isVerified,
    this.avatarURL,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] as bool? ?? false,
      avatarURL: data['avatarURL'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isVerified': isVerified,
      'avatarURL': avatarURL,
    };
  }

  User copyWith({
    String? name,
    String? email,
    UserRole? role,
    DateTime? lastLoginAt,
    bool? isVerified,
    String? avatarURL,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      avatarURL: avatarURL ?? this.avatarURL,
    );
  }
} 