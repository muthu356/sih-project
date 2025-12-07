import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  final String parentId;
  final String userId;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final List<String> childrenIds;
  final DateTime createdAt;

  ParentModel({
    required this.parentId,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    this.address = '',
    this.childrenIds = const [],
    required this.createdAt,
  });

  factory ParentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParentModel(
      parentId: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      childrenIds: List<String>.from(data['childrenIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'childrenIds': childrenIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
