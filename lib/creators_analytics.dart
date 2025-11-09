import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Note: Assuming you have a Project model or know the field names (goal, raised)

class CreatorAnalyticsPage extends StatelessWidget {
  final String projectId;
  final String projectTitle;

  const CreatorAnalyticsPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  // Function to fetch the Project data
  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchProjectDetails() {
    return FirebaseFirestore.instance.collection('Projects').doc(projectId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics for: $projectTitle',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 47, 117, 223),
        foregroundColor: Colors.white,
      ),

      // ⭐ STEP 1: Fetch Project Details (Goal, Raised Amount)
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchProjectDetails(),
        builder: (context, projectSnapshot) {
          if (projectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (projectSnapshot.hasError) {
            return Center(child: Text('Error loading project details: ${projectSnapshot.error}'));
          }

          if (!projectSnapshot.hasData || !projectSnapshot.data!.exists) {
            return const Center(child: Text('Project details not found.'));
          }

          final projectData = projectSnapshot.data!.data()!;

          // Use the correct field names: 'goal' and 'raised'
          final double goal = (projectData['goal'] as num?)?.toDouble() ?? 1.0;
          final double raised = (projectData['raised'] as num?)?.toDouble() ?? 0.0;
          final double progress = raised / goal;
          final String statusText = progress >= 1.0 ? 'Goal Achieved' : 'Funding in Progress';
          final Color statusColor = progress >= 1.0 ? Colors.green : Colors.orange;

          // ⭐ STEP 2: Display the Details and then the Backer Stream
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PROJECT STATUS CARD ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Goal: Nu. ${goal.toStringAsFixed(0)}'),
                        Text('Raised: Nu. ${raised.toStringAsFixed(0)}'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}% Funded | $statusText',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- BACKER LIST HEADER ---
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                child: Text(
                  'Backers (${projectTitle})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              // --- BACKER LIST (StreamBuilder) ---
              Expanded(
                // Use a nested StreamBuilder to fetch Pledges
                child: _buildBackerListStream(projectId),
              ),
            ],
          );
        },
      ),
    );
  }


  // Extracted StreamBuilder logic for clarity
  Widget _buildBackerListStream(String projectId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Pledges')
          .where('projectId', isEqualTo: projectId)
          .orderBy('pledgeDate', descending: true)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading backer list: ${snapshot.error}'));
        }

        final pledges = snapshot.data?.docs ?? [];

        if (pledges.isEmpty) {
          return const Center(
            child: Text('No backers yet right now! Let \'em know your project is posted!!'),
          );
        }

        // Calculate total amount backed from the pledges stream for the header in the parent
        final double totalBacked = pledges.fold(0.0, (sum, doc) => sum + (doc['pledgeAmount'] as num).toDouble());
        final int totalBackers = pledges.length;

        // This is where you can update the status card's backer count if needed,
        // but it's simpler to rely on the list length or show the count in the list header.

        return ListView.builder(
          itemCount: pledges.length,
          itemBuilder: (context, index) {
            final pledgeData = pledges[index].data() as Map<String, dynamic>;

            final amount = (pledgeData['pledgeAmount'] as num).toStringAsFixed(0);
            final String backerName = pledgeData['backerName'] ?? 'Anonymous Backer';
            final String contact = pledgeData['backerContact'] ?? 'N/A'; // Get contact details
            final String bankType = pledgeData['bankType'] ?? 'N/A';
            final String rewardTitle = pledgeData['rewardTitle'] ?? 'No Reward';


            final Timestamp? pledgeTimestamp = pledgeData['pledgeDate'];
            final String formattedDate = pledgeTimestamp != null
                ? DateFormat('MMM d, yyyy h:mm a').format(pledgeTimestamp.toDate())
                : 'Unknown Date';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(backerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact: $contact (Bank: $bankType)', style: const TextStyle(fontSize: 12)),
                    Text('Reward: $rewardTitle', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Date: $formattedDate', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                trailing: Text(
                  'Nu. $amount',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}