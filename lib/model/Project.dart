class Project {
  final String projectId;
  final String title;
  final String creator;
  final String imageUrl;
  final String category;
  final double raised;
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
    required this.goal,
    required this.creatorImageUrl,
    this.createdAt, // optional
  });

  double get progress => raised / goal;
}
