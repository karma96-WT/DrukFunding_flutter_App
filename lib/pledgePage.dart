import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drukfunding/model/project.dart'; // Ensure you import your Project model
// Assuming you have a way to fetch project details (e.g., from Firestore)

// ⚠️ IMPORTANT: Placeholder Project data structure for demonstration
// Replace this with your actual Firestore fetching logic later.
class Reward {
  final String id;
  final String title;
  final String description;
  final double amount;
  final int limit;
  Reward({required this.id, required this.title, required this.description, required this.amount, required this.limit});
}

// ⚠️ IMPORTANT: Mock data for testing the UI
final List<Reward> mockRewards = [
  Reward(id: 'r1', title: 'Nu. 50 Supporter', description: 'A big thank you and an exclusive digital wallpaper.', amount: 50.0, limit: 100),
  Reward(id: 'r2', title: 'Nu. 500 Early Bird', description: 'One unit of the product at 10% off retail price.', amount: 500.0, limit: 50),
  Reward(id: 'r3', title: 'Nu. 1,500 Complete Kit', description: 'The complete product kit plus a limited edition print.', amount: 1500.0, limit: 20),
  Reward(id: 'r4', title: 'Pledge Any Amount', description: 'Support the project without selecting a specific reward.', amount: 0.0, limit: 999),
];

// --- Main Pledge Page Widget ---

class PledgePage extends StatefulWidget {
  final String projectId;

  const PledgePage({super.key, required this.projectId});

  @override
  State<PledgePage> createState() => _PledgePageState();
}

class _PledgePageState extends State<PledgePage> {
  Reward? _selectedReward;
  double _currentPledgeAmount = 0.0;

  // ⚠️ NOTE: In a real app, you would fetch project details here to get the real rewards list.
  // For now, we'll use mockRewards for the UI.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Back Project'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Title (Placeholder)
            Text(
              'Back the "Project Title Goes Here" Project', // Replace with actual project title
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const Divider(height: 30),

            // 1. Reward Selection Section
            const Text(
              '1. Select your Reward Tier',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // List of Reward Options
            ...mockRewards.map((reward) => RewardItem(
              reward: reward,
              isSelected: _selectedReward?.id == reward.id,
              onSelect: (selectedReward) {
                setState(() {
                  _selectedReward = selectedReward;
                  // If it's the "Pledge Any Amount" option, initialize to a minimal amount
                  _currentPledgeAmount = selectedReward.amount > 0 ? selectedReward.amount : 10.0;
                });
              },
            )).toList(),

            const Divider(height: 30),

            // 2. Pledge Amount Adjustment (Only if a reward is selected)
            if (_selectedReward != null) ...[
              const Text(
                '2. Confirm Pledge Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              if (_selectedReward!.amount == 0) // Special input for "Pledge Any Amount"
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    initialValue: _currentPledgeAmount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custom Pledge Amount (Nu.)',
                      border: OutlineInputBorder(),
                      prefixText: 'Nu. ',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _currentPledgeAmount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                )
              else
                Text(
                  'Your pledge amount is fixed at Nu. ${_selectedReward!.amount.toStringAsFixed(0)} for the ${_selectedReward!.title} reward.',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),

              const Divider(height: 30),

              // 3. Final Summary and Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Final Pledge Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Nu. ${_currentPledgeAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red[700]),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _currentPledgeAmount > 0 ? _startPaymentFlow : null,
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    'Continue to Payment (Nu. ${_currentPledgeAmount.toStringAsFixed(0)})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startPaymentFlow() {
    // 🛑 To be implemented: This is where you would navigate to the
    // payment processing screen (e.g., Stripe/Razorpay integration).
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing pledge of Nu. ${_currentPledgeAmount.toStringAsFixed(2)} for ${widget.projectId}'))
    );
    // Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen(amount: _currentPledgeAmount, reward: _selectedReward)));
  }
}

// --- Reward Item Widget (Used in PledgePage) ---

class RewardItem extends StatelessWidget {
  final Reward reward;
  final bool isSelected;
  final Function(Reward) onSelect;

  const RewardItem({
    super.key,
    required this.reward,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.blue[700]!, width: 3.0)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelect(reward),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reward.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue[700] : Colors.black87,
                ),
              ),
              if (reward.amount > 0)
                Text(
                  'Pledge: Nu. ${reward.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              const SizedBox(height: 8),
              Text(
                reward.description,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              if (reward.limit > 0)
                Text(
                  'Limited to ${reward.limit} backers.',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}