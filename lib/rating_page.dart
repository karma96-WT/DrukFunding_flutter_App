import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add 'intl: ^0.18.1' to your pubspec.yaml if missing

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  double _currentRating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- Firestore Submission Function ---

  Future<void> _submitRating() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a rating.')),
      );
      return;
    }
    if (_currentRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 1. Fetch the username from the 'users' collection
    String? username;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      username = userDoc.data()?['username'];
    } catch (e) {
      print('Error fetching username: $e');
    }

    // 2. Prepare the data payload
    final ratingData = {
      'userId': currentUser!.uid,
      'username': username ?? 'Anonymous User',
      'email': currentUser!.email, // Email from FirebaseAuth
      'rating': _currentRating,
      'comment': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 3. Save to the 'Ratings' collection
    try {
      await FirebaseFirestore.instance.collection('Ratings').add(ratingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating and feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally reset the form after submission
        _currentRating = 0.0;
        _commentController.clear();
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // --- Rating Display Widgets ---

  // Calculates and displays average rating and statistics
  Widget _buildRatingDisplay() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Ratings')
          .orderBy('timestamp', descending: true) // Order by latest ratings
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading ratings: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Be the first to leave a rating!'));
        }

        // Calculate Average Rating
        double totalRating = 0;
        for (var doc in docs) {
          // Safely cast rating field (Firestore stores numbers as num)
          totalRating += (doc['rating'] as num).toDouble();
        }
        final double averageRating = totalRating / docs.length;
        final int totalReviews = docs.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ Average Rating Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Average Rating',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${averageRating.toStringAsFixed(1)} / 5.0',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                      ),
                    ],
                  ),
                  Text(
                    '$totalReviews Reviews',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(top: 25, bottom: 10),
              child: Text(
                'Recent Reviews',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // ⭐ List of Individual Reviews
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final review = docs[index];
                final reviewData = review.data() as Map<String, dynamic>;
                final rating = (reviewData['rating'] as num).toDouble();
                final timestamp = reviewData['timestamp'] as Timestamp?;

                final formattedDate = timestamp != null
                    ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                    : 'Unknown Date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Reviewer Name/Email
                            Text(
                              reviewData['username'] ?? reviewData['email'] ?? 'Anonymous',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            // Date
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Star Rating
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < rating.floor() ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),

                        // Comment
                        if (reviewData['comment'] != null && reviewData['comment'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              reviewData['comment'],
                              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- Star Builder (Remains the same) ---
  Widget _buildStar(int index) {
    IconData icon;
    Color color;

    if (index + 1.0 <= _currentRating) {
      icon = Icons.star;
      color = Colors.amber;
    } else if (index < _currentRating) {
      icon = Icons.star_half;
      color = Colors.amber;
    } else {
      icon = Icons.star_border;
      color = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentRating = index + 1.0;
        });
      },
      child: Icon(
        icon,
        color: color,
        size: 40.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rate DrukFunding',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 47, 117, 223),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Submission Section ---
            Center(
              child: Column(
                children: [
                  const Text(
                    'How was your experience?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentUser == null ? 'Please log in to leave a review.' : 'Please select a rating and leave a comment below.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => _buildStar(index)),
                  ),
                  Text(
                    _currentRating > 0 ? 'Rating: $_currentRating / 5.0' : 'No Rating Selected',
                    style: TextStyle(
                      fontSize: 16,
                      color: _currentRating > 0 ? Colors.black87 : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Comment Input Field
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    enabled: currentUser != null && !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Your Comments (Optional)',
                      hintText: 'Tell us what you think...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: currentUser != null && _currentRating > 0.0 && !_isSubmitting
                          ? _submitRating
                          : null,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Rating',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentRating > 0.0 && currentUser != null ? Colors.blue[600] : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 60, thickness: 1.5),

            // --- Display Section ---
            _buildRatingDisplay(),
          ],
        ),
      ),
    );
  }
}