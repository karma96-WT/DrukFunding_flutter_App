import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String projectId;
  final String title;
  final String creator;
  final String imageUrl;
  final String category;
  final double raised;
  final int likes;
  final double goal;
  final String creatorImageUrl;
  final DateTime? createdAt; // add this field

  Project({
    required this.projectId,
    required this.title,
    required this.creator,
    required this.imageUrl,
    required this.category,
    required this.raised,
    required this.likes,
    required this.goal,
    required this.creatorImageUrl,
    this.createdAt, // optional
  });

  double get progress => raised / goal;

  factory Project.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc, // <-- Change the type here
      SnapshotOptions? options,
      ) {
    final data = doc.data()!; // Using the non-nullable operator assumes doc exists,

    // The rest of your logic remains the same:
    return Project(
      projectId: doc.id,
      title: data['title'] ?? 'Untitled Project',
      creator: data['creator'] ?? 'Unknown Creator',
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/600x400/CCCCCC/000000?text=No+Image',
      category: data['category'] ?? 'General',
      raised: (data['raised'] as num?)?.toDouble() ?? 0.0,
      likes: data['likes'] ?? 0,
      goal: (data['goal'] as num?)?.toDouble() ?? 1.0,
      creatorImageUrl: data['creatorImageUrl'] ?? 'https://placehold.co/50x50/000000/FFFFFF?text=?',
    );
  }
}
