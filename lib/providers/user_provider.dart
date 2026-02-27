import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. The User Model
class AppUser {
  final String username;
  final String role; // 'Admin', 'Officer', 'Auditor'
  final String mainRegion;
  final String subRegion;

  AppUser({
    required this.username, 
    required this.role, 
    required this.mainRegion, 
    required this.subRegion
  });

  bool get isAdmin => role == 'Admin';
}

// 2. The Provider (State Management)
final userProvider = StateNotifierProvider<UserNotifier, AppUser?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<AppUser?> {
  UserNotifier() : super(null); // Initially no one is logged in

  // --- LOGIN FUNCTION ---
  Future<String?> login(String username, String password) async {
    try {
      // Query Firestore for the username
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password) // Simple check
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return "Invalid Username or Password";
      }

      final data = snapshot.docs.first.data();
      
      // Save User to State
      state = AppUser(
        username: data['username'],
        role: data['role'] ?? 'Officer',
        mainRegion: data['mainRegion'] ?? '',
        subRegion: data['subRegion'] ?? '',
      );
      
      return null; // Null means success (no error)
    } catch (e) {
      return "Login Error: $e";
    }
  }

  // --- LOGOUT ---
  void logout() {
    state = null;
  }
}