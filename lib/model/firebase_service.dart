import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drukfunding/model/Project.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Project>> getFavoriteProjects() async {
    // 1. Get the current user ID
    final String? userId = _auth.currentUser?.uid;

    if (userId == null) {
      // Return empty list if the user is not logged in
      return [];
    }

    // --- Step 1: Retrieve the list of saved project IDs ---
    DocumentSnapshot favoriteDoc = await _db
        .collection('Favorites')
        .doc(userId) // Use the dynamic logged-in user ID
        .get();

    if (!favoriteDoc.exists) {
      return [];
    }

    final data = favoriteDoc.data() as Map<String, dynamic>?;
    final List<String> savedProjectIds =
        (data?['savedProjectIds'] as List<dynamic>?)
            ?.map((id) => id.toString())
            .toList() ?? [];

    if (savedProjectIds.isEmpty) {
      return [];
    }

    // --- Step 2: Retrieve the corresponding Project documents ---

    // Firestore 'whereIn' only allows up to 10 items. Handle larger lists if necessary.
    final List<String> queryIds = savedProjectIds.take(10).toList();

    // Query the 'Projects' collection using the list of IDs
    QuerySnapshot<Map<String, dynamic>> projectSnapshots = await _db
        .collection('Projects')
        .where(FieldPath.documentId, whereIn: queryIds)
        .get();

// Convert the documents to a list of Project objects
    return projectSnapshots.docs.map((doc) {
      // doc is now correctly typed as DocumentSnapshot<Map<String, dynamic>>
      return Project.fromFirestore(doc, null);
    }).toList();
  }
}