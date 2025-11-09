import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 47, 117, 223),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Contact Section ---
            const Text(
              'Get in Touch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildContactInfo(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@drukfunding.bt',
              onTap: () {
                // TODO: Implement deep link for emailing (e.g., using url_launcher)
              },
            ),
            _buildContactInfo(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+975 17XXXXXX (Mon-Fri, 9am-5pm)',
              onTap: () {
                // TODO: Implement deep link for calling
              },
            ),

            const SizedBox(height: 30),

            // --- FAQ Section ---
            const Text(
              'Frequently Asked Questions (FAQs)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildFAQSection(),

            const SizedBox(height: 20),

            // --- Index Troubleshooting Reminder (Kept for internal reference) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Troubleshooting Tip (Developers)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Text(
                          'If data (like notifications/projects) is missing, ensure all required Composite Indexes are created in the Firestore console.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[600]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQSection() {
    // ⭐ EXPANDED List of FAQ data
    final faqs = [
      {
        'question': 'How do I submit a new project?',
        'answer': 'Navigate to the "Create" tab (the plus icon) and fill out the required details, including the project title, goal amount, description, and images. Once submitted, your project will be reviewed for approval.',
      },
      {
        'question': 'How does funding (pledging) work?',
        'answer': 'You can pledge funds to any listed project using the backing feature on the project detail page. Funds are only charged and collected if the project successfully reaches its goal by the deadline.',
      },
      {
        'question': 'What happens if a project doesn\'t meet its goal?',
        'answer': 'If a project fails to meet its goal, the creator receives nothing, and backers will not be charged any money for their pledge.',
      },
      {
        'question': 'How can I reset my password?',
        'answer': 'Go to the Profile Settings page and click "Reset Password." A link will be sent to your registered email address to securely create a new password.',
      },
      {
        'question': 'Where can I see the projects I have created?',
        'answer': 'Go to the Profile page, and select the "My Creations" tab. This list dynamically retrieves all projects where you are listed as the creator.',
      },
      {
        'question': 'Where can I see the projects I have backed?',
        'answer': 'Go to the Profile page, and select the "Backed Projects" tab. This list dynamically retrieves all projects for which you have made a pledge recorded in the Pledges collection.',
      },
      {
        'question': 'How long does project review take?',
        'answer': 'Project reviews typically take 24-48 hours. You will receive a notification once your project has been approved or declined by the moderator.',
      },
    ];

    return Column(
      children: faqs.map((faq) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300)
          ),
          child: ExpansionTile(
            iconColor: Colors.blue,
            collapsedIconColor: Colors.grey,
            title: Text(
              faq['question']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Text(
                  faq['answer']!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}