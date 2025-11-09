import 'package:drukfunding/payment_page.dart' hide Reward;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drukfunding/Reward.dart'; // Ensure this file exists
import 'package:drukfunding/model/project.dart'; // Ensure this file exists


class PledgePage extends StatefulWidget {
  final String projectId;

  const PledgePage({super.key, required this.projectId});

  @override
  State<PledgePage> createState() => _PledgePageState();
}

class _PledgePageState extends State<PledgePage> {
  // State variables for selection and amount
  Reward? _selectedReward;
  double _currentPledgeAmount = 0.0;

  // Future to hold the Firestore fetch operation
  late Future<List<Reward>> _rewardsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future when the widget is created
    _rewardsFuture = _fetchRewards();
  }

  // Function to Fetch Tiers from Firestore
  Future<List<Reward>> _fetchRewards() async {
    try {
      // 1. Reference the 'Tiers' subcollection under the specific 'Projects' document
      final snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectId)
          .collection('Tiers')
          .get();

      // 2. Map the documents to Reward objects
      final rewards = snapshot.docs.map((doc) => Reward.fromFirestore(doc)).toList();

      return rewards;
    } catch (e) {
      // Log the error and rethrow to be caught by FutureBuilder
      print('Error fetching rewards: $e');
      rethrow;
    }
  }

  // --- UI Build and Helper Methods ---

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
            // Project Title (Placeholder) - You may want to fetch the real project title here
            Text(
              'Back the Project',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const Divider(height: 30),

            // 1. Reward Selection Section (USING FUTUREBUILDER)
            const Text(
              '1. Select your Reward Tier (or donate any amount)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<Reward>>(
              future: _rewardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading tiers: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No reward tiers found for this project.'));
                }

                final rewards = snapshot.data!;

                // List of Reward Options
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rewards.map((reward) => RewardItem(
                    reward: reward,
                    isSelected: _selectedReward?.id == reward.id,
                    onSelect: (selectedReward) {
                      setState(() {
                        _selectedReward = selectedReward;
                        // If it's the "Pledge Any Amount" option (amount 0), initialize to 10.0
                        // The user will see the TextFormField to adjust this amount.
                        _currentPledgeAmount = selectedReward.amount > 0
                            ? selectedReward.amount
                            : 10.0;
                      });
                    },
                  )).toList(),
                );
              },
            ),

            const Divider(height: 30),

            // 2. Pledge Amount Adjustment (Only if a reward is selected)
            if (_selectedReward != null) ...[
              const Text(
                '2. Confirm Pledge Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // If reward amount is 0.0, show the custom input field
              if (_selectedReward!.amount == 0.0)
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
                        // Ensure minimal pledge amount is respected (e.g., >= 10.0)
                        _currentPledgeAmount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                )
              else
              // Otherwise, show the fixed amount message
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
                  // Require a minimum pledge of 10.0 (or whatever your minimum is)
                  onPressed: _currentPledgeAmount >= 10.0 ? _startPaymentFlow : null,
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
    // Final validation before navigating
    if (_selectedReward == null || _currentPledgeAmount < 10.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reward and ensure a minimum pledge of Nu. 10.0.')),
      );
      return;
    }

    // Navigate to the PaymentScreen, passing necessary data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          projectId: widget.projectId,
          selectedReward: _selectedReward!,
          pledgeAmount: _currentPledgeAmount,
        ),
      ),
    );
  }
}

// --- Reward Item Widget ---

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
        // Highlight border for the selected reward
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
                )
              else
                const Text( // Custom text for the "Pledge Any Amount" option
                  'Pledge Any Amount',
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
              const SizedBox(height: 8),
              Text(
                reward.description,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              // Use null-aware operator for limit
              if (reward.limit != null && reward.limit! > 0)
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