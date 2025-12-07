import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Parent/Teacher Sign Up
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      await user.updateDisplayName(displayName);

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());

      return userModel;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Parent/Teacher Sign In
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (currentUser != null) {
        // Update last login
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Student Sign In (using student ID lookup)
  Future<UserModel?> signInAsStudent(String studentId) async {
    try {
      // Check if student exists
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) {
        throw Exception('Student ID not found');
      }

      final studentData = studentDoc.data()!;
      
      // Check if student has a userId (already created an auth account)
      String? userId = studentData['userId'];
      
      if (userId == null) {
        // Create anonymous auth session for this student
        final credential = await _auth.signInAnonymously();
        userId = credential.user!.uid;
        
        // Link this auth user to the student
        await _firestore.collection('students').doc(studentId).update({
          'userId': userId,
        });

        // Create user document
        final userModel = UserModel(
          uid: userId,
          email: '$studentId@student.internal',
          displayName: studentData['fullName'] ?? 'Student',
          role: UserRole.student,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(userId).set(userModel.toFirestore());
        
        return userModel;
      } else {
        // Student has an existing auth session - we can't sign in with anonymous again
        // For simplicity, we'll create a new anonymous session each time
        final credential = await _auth.signInAnonymously();
        final newUserId = credential.user!.uid;
        
        // Update student with new userId
        await _firestore.collection('students').doc(studentId).update({
          'userId': newUserId,
        });

        final userModel = UserModel(
          uid: newUserId,
          email: '$studentId@student.internal',
          displayName: studentData['fullName'] ?? 'Student',
          role: UserRole.student,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(newUserId).set(userModel.toFirestore());
        
        return userModel;
      }
    } catch (e) {
      print('Student sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
