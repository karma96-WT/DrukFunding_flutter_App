import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Note: Removed unused 'qr_flutter' import
import 'package:drukfunding/Reward.dart';

// Assuming the Reward class is correctly imported from its central file

class PaymentScreen extends StatefulWidget {
  final String projectId;
  final Reward selectedReward;
  final double pledgeAmount;

  const PaymentScreen({
    super.key,
    required this.projectId,
    required this.selectedReward,
    required this.pledgeAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinFormKey = GlobalKey<FormState>(); // New key for PIN form

  String? _selectedBankType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _pinController = TextEditingController(); // New controller for PIN

  bool _isLoading = false;
  // State to control UI flow: false -> Form, true -> PIN Input
  bool _pinVerificationPending = false;
  String _pledgeId = '';
  // ⭐ SIMULATION: In a real app, this would come from the server after sending the OTP
  String _simulatedOtp = '123456';

  final List<String> _bankOptions = [
    'Bank of Bhutan (BOB)',
    'Bhutan National Bank (BNB)',
    'T Bank',
    'Druk PNB',
    'Bhutan Development Bank (BDB)'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _referenceController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ⭐ STEP 1: Process form and simulate sending OTP
  Future<void> _processPledge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 1. Create the pledge record as 'pending_otp' status
    final pledgeData = {
      'userId': userId,
      'projectId': widget.projectId,
      'rewardId': widget.selectedReward.id,
      'rewardTitle': widget.selectedReward.title,
      'pledgeAmount': widget.pledgeAmount,
      'pledgeDate': Timestamp.now(),
      'backerName': _nameController.text.trim(),
      'backerContact': _contactController.text.trim(),
      'bankType': _selectedBankType,
      'accountNumber': _referenceController.text.trim(), // Renamed to accountNumber
      'status': 'pending_otp_verification',
    };

    try {
      final newPledgeRef = await FirebaseFirestore.instance.collection('Pledges').add(pledgeData);
      _pledgeId = newPledgeRef.id;

      // ⭐ 2. Simulate OTP sending delay and success
      await _sendOtp(_contactController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pledge details submitted. A 6-digit PIN sent to ${_contactController.text.trim()}'),
          backgroundColor: Colors.blueGrey,
          duration: const Duration(seconds: 4),
        ),
      );

      // 3. Update state to switch to PIN input view
      setState(() {
        _pinVerificationPending = true;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start pledge: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ⭐ Dummy function to simulate sending OTP
  Future<void> _sendOtp(String contact) async {
    // In a real application, you would call a cloud function or external SMS service here.
    // The server would generate and send the actual PIN.
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    print('SIMULATION: OTP sent to $contact. OTP is: $_simulatedOtp');
  }

  // ⭐ STEP 2: Verify PIN and finalize transaction
  // ⭐ STEP 2: Verify PIN and finalize transaction (UPDATED for Project amount)
  // ⭐ STEP 2: Verify PIN and finalize transaction (UPDATED to use 'raised' field)
  Future<void> _verifyOtpAndFinalize() async {
    if (!_pinFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final enteredPin = _pinController.text.trim();
    final projectRef = FirebaseFirestore.instance.collection('Projects').doc(widget.projectId);
    final pledgeRef = FirebaseFirestore.instance.collection('Pledges').doc(_pledgeId);
    final pledgeAmount = widget.pledgeAmount; // The amount to add

    // 1. Compare entered PIN with the expected PIN (REALITY: Check against server/database)
    if (enteredPin == _simulatedOtp) { // ⭐ SUCCESS PATH
      try {
        // 2. Use a Firestore Transaction for atomicity and correct concurrency control
        await FirebaseFirestore.instance.runTransaction((transaction) async {

          // 2a. Read the current Project data within the transaction
          DocumentSnapshot projectSnapshot = await transaction.get(projectRef);

          if (!projectSnapshot.exists) {
            throw Exception("Project not found!");
          }

          // Get the current raised amount from the EXISTING FIELD 'raised'
          final double currentRaised = (projectSnapshot.data() as Map<String, dynamic>)?['raised']?.toDouble() ?? 0.0;

          // Calculate the new raised amount
          final double newRaised = currentRaised + pledgeAmount;

          // 2b. Update the Project document using the EXISTING FIELD NAME 'raised'
          transaction.update(projectRef, {
            'raised': newRaised, // ⭐ FIX: Updated field name from 'raisedAmount' to 'raised'
          });

          // 2c. Update the Pledge document status to 'successful'
          transaction.update(pledgeRef, {
            'status': 'successful',
            'transactionTime': Timestamp.now(),
          });

        }, maxAttempts: 3); // Allow up to 3 attempts for the transaction

        // 3. Show Success and Navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction Successful! Project amount updated.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Navigate back to project page or success screen
        Navigator.of(context).popUntil((route) => route.isFirst);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finalize pledge or update project: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } else { // ⭐ FAILURE PATH
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PIN. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }


  // ⭐ New Widget to display the PIN input form
  Widget _buildPinInputForm() {
    return Form(
      key: _pinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          Text(
            'A 6-digit PIN has been sent to ${_contactController.text.trim()}. Please enter it below to confirm your pledge.',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Enter 6-Digit PIN',
              counterText: "", // Hide character counter
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.length != 6) {
                return 'PIN must be 6 digits.';
              }
              return null;
            },
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyOtpAndFinalize,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                _isLoading ? 'Verifying...' : 'Verify PIN and Finalize Pledge',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _isLoading ? null : () => _sendOtp(_contactController.text.trim()),
            child: const Text('Resend PIN'),
          )
        ],
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final reward = widget.selectedReward;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pinVerificationPending ? 'Verify Pledge' : 'Confirm & Pay'),
        backgroundColor: Colors.blue[700],
        automaticallyImplyLeading: !_pinVerificationPending,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Pledge Summary ---
            Text(
              'Reward: ${reward.title}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Pledge Total: Nu. ${widget.pledgeAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blue[800]),
            ),
            const Divider(height: 30),

            // ⭐ Conditional View: Show Form or PIN Input
            if (_pinVerificationPending)
              _buildPinInputForm()
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Backer Information ---
                    const Text('Backer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name (Bank Holder Full Name)',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Name is required.' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact that is Linked to Bank',
                        prefixIcon: Icon(Icons.phone_android),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Contact is required.' : null,
                    ),
                    const SizedBox(height: 30),

                    // --- Payment Method ---
                    const Text('Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Bank Used for Transfer',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedBankType,
                      items: _bankOptions.map((bank) {
                        return DropdownMenuItem(value: bank, child: Text(bank));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBankType = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a bank.' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _referenceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Account number:',
                        hintText: 'Bank account number',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Account number is required.' : null,
                    ),
                    const SizedBox(height: 40),

                    // --- Submission Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _processPledge,
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.lock_open, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Submitting...' : 'Confirm Details and Send PIN',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}