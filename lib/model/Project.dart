class Project {
  final String title;
  final String creator;
  final String imageUrl;
  final String category;
  final double raised;
  final double goal;
  final String creatorImageUrl;

  Project({
    required this.title,
    required this.creator,
    required this.imageUrl,
    required this.category,
    required this.raised,
    required this.goal,
    required this.creatorImageUrl,
  });

  // Calculate percentage of goal achieved
  double get progress => raised / goal;
}
