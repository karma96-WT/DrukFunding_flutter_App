import 'package:cloud_firestore/cloud_firestore.dart';

class Reward {
  final String id;
  final String title;
  final String description;
  final double amount;
  final int? limit;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    this.limit,
  });

  // Factory method to create a Reward object from a Firestore DocumentSnapshot
  factory Reward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reward(
      id: doc.id,
      title: data['name'] ?? 'Tier Name',
      description: data['description'] ?? 'No description provided.',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      limit: (data['limit'] as int?),
    );
  }
}