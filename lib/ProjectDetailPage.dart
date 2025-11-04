import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final String projectId; // Firestore document ID

  const DetailPage({super.key, required this.projectId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getProjectDetails() {
    return _firestore.collection('Projects').doc(widget.projectId).get();
  }

  String _formatCurrency(num amount) {
    return 'Nu. ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _onSubmit(){
    // Logic goes here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getProjectDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Project not found.'));
          }

          final project = snapshot.data!.data()!;

          // Safely extract fields
          final String title = project['title'] ?? 'No Title';
          final String tagline = project['tagline'] ?? '';
          final String creator = project['creator'] ?? 'Unknown';
          final String category = project['category'] ?? 'Uncategorized';
          final String description = project['description'] ?? '';
          final String imageUrl = project['imageUrl'] ?? '';
          final num raised = project['raised'] ?? 0;
          final num goal = project['goal'] ?? 0;
          final String duration = project['duration'] ?? 'N/A';
          final Timestamp? createdAt = project['createdAt'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Image
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                if (tagline.isNotEmpty)
                  Text(
                    tagline,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                const Divider(height: 30),

                // Creator Info
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Creator: ', style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),),
                    Text(
                      creator,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category
                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Category: ', style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),),
                    Text(
                      category,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Goal and Raised
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Goal: ${_formatCurrency(goal)}',
                      style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'Raised: ${_formatCurrency(raised)}',
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Duration
                Row(
                  children: [
                    const Icon(Icons.timelapse, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: $duration left',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Date Created
                if (createdAt != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Created on: ${_formatDate(createdAt)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ()=> {

                      _onSubmit,
                      },
                      child: const Text('Back Project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 8
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
