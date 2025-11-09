import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BackedPledgeDetailsPage extends StatelessWidget {
  final String projectId;
  final String projectTitle;

  const BackedPledgeDetailsPage({
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
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        appBar: MyAppBar(title: 'Pledge Details'),
        body: Center(child: Text('User not authenticated.')),
      );
    }

    return Scaffold(
      appBar: MyAppBar(title: 'Details for: $projectTitle'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: Project Summary (FutureBuilder) ---
            _buildProjectSummary(context),

            // --- SECTION 2: Current User's Pledge Details (StreamBuilder) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                'Your Private Pledge Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
            ),
            _buildCurrentUserPledge(context, userId),

            // --- SECTION 3: All Backers List (StreamBuilder) ---
            const Padding(
              padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 10.0),
              child: Text(
                'All Project Backers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
            ),
            _buildAllBackersList(context),
          ],
        ),
      ),
    );
  }

  // 1. PROJECT SUMMARY WIDGET
  Widget _buildProjectSummary(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _fetchProjectDetails(),
      builder: (context, projectSnapshot) {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (!projectSnapshot.hasData || !projectSnapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Error: Project details not found.'),
          );
        }

        final projectData = projectSnapshot.data!.data()!;
        final double goal = (projectData['goal'] as num?)?.toDouble() ?? 1.0;
        final double raised = (projectData['raised'] as num?)?.toDouble() ?? 0.0;
        final double progress = raised / goal;
        final String statusText = progress >= 1.0 ? 'Goal Achieved!' : 'In Progress';
        final Color statusColor = progress >= 1.0 ? Colors.green : Colors.orange;

        return Padding(
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
                  _buildDetailRow('Goal:', 'Nu. ${goal.toStringAsFixed(0)}', Colors.black),
                  _buildDetailRow('Raised:', 'Nu. ${raised.toStringAsFixed(0)}', Colors.green),
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
        );
      },
    );
  }

  // 2. CURRENT USER'S PLEDGE WIDGET (The original content)
  Widget _buildCurrentUserPledge(BuildContext context, String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Pledges')
            .where('userId', isEqualTo: userId)
            .where('projectId', isEqualTo: projectId)
            .limit(1)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LinearProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('You have not made a confirmed pledge for this project.', style: TextStyle(color: Colors.red));
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          final amount = (data['pledgeAmount'] as num).toStringAsFixed(0);
          final bank = data['bankType'] ?? 'N/A';
          final accountNumber = data['accountNumber'] ?? 'N/A';
          final contact = data['backerContact'] ?? 'N/A';
          final status = data['status'] ?? 'N/A';
          final rewardTitle = data['rewardTitle'] ?? 'No Reward Selected';

          final pledgeDate = (data['pledgeDate'] as Timestamp).toDate();
          final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(pledgeDate);

          return _buildDetailsCard(
            amount: amount,
            bank: bank,
            accountNumber: accountNumber,
            contact: contact,
            status: status,
            rewardTitle: rewardTitle,
            formattedDate: formattedDate,
          );
        },
      ),
    );
  }

  // 3. ALL BACKERS LIST WIDGET
  Widget _buildAllBackersList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: StreamBuilder<QuerySnapshot>(
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
              child: Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
                child: Text('No other backers recorded yet.'),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Text('Total Backers: ${pledges.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              // Use shrinkWrap and disable scrolling because the parent is scrollable
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: pledges.length,
                itemBuilder: (context, index) {
                  final pledgeData = pledges[index].data() as Map<String, dynamic>;

                  final amount = (pledgeData['pledgeAmount'] as num).toStringAsFixed(0);
                  final String backerName = pledgeData['backerName'] ?? 'Anonymous Backer';
                  final String rewardTitle = pledgeData['rewardTitle'] ?? 'No Reward';
                  final Timestamp? pledgeTimestamp = pledgeData['pledgeDate'];

                  final String formattedDate = pledgeTimestamp != null
                      ? DateFormat('MMM d, yyyy').format(pledgeTimestamp.toDate())
                      : 'Unknown Date';

                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.deepOrange),
                    title: Text(backerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('Reward: $rewardTitle | Pledged: $formattedDate'),
                    trailing: Text(
                      'Nu. $amount',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget to display the sensitive data securely (Kept as is)
  Widget _buildDetailsCard({
    required String amount,
    required String bank,
    required String accountNumber,
    required String contact,
    required String status,
    required String rewardTitle,
    required String formattedDate,
  }) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Pledge Status: ${status.toUpperCase()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: status == 'successful' ? Colors.green[700] : Colors.orange,
                ),
              ),
            ),
            const Divider(height: 30),

            _buildDetailRow('Pledged Amount:', 'Nu. $amount', Colors.green),
            _buildDetailRow('Backed On:', formattedDate, Colors.black54),
            _buildDetailRow('Reward Selected:', rewardTitle, Colors.indigo),

            const Divider(height: 30),

            const Text(
              'Your Transaction Details (Private)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Bank Used:', bank, Colors.black87),
            _buildDetailRow('Account Number:', accountNumber, Colors.black87),
            _buildDetailRow('Contact Number:', contact, Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Simple custom AppBar for clean look
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const MyAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
      backgroundColor: const Color.fromARGB(255, 47, 117, 223),
      foregroundColor: Colors.white,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}