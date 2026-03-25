import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. THE USER MODEL
class AppUser {
  final String id;
  final String username;
  final String role; // 'Admin', 'Field Officer', 'Region Officer'
  final String mainRegion;
  final String subRegion;

  AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.mainRegion,
    required this.subRegion,
  });

  // --- HELPERS FOR DASHBOARD COMPATIBILITY ---
  bool get isAdmin => role == 'Admin';

  // FIXED: Added displayName (it just returns the username)
  String get displayName => username;
}

// 2. THE AUTH STATE
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.user, this.isLoading = false, this.errorMessage});

  // Helpers
  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.role == 'Admin';
  bool get isRegionOfficer =>
      user?.role == 'Region Officer' || user?.role == 'Officer';
  bool get isFieldOfficer => user?.role == 'Field Officer';

  // FIXED: Alias for compatibility
  AppUser? get currentUser => user;
}

// 3. THE PROVIDER
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> login(String username, String password) async {
    state = AuthState(isLoading: true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        state = AuthState(
            isLoading: false, errorMessage: "Invalid Username or Password");
        return false;
      }

      final data = snapshot.docs.first.data();

      final user = AppUser(
        id: snapshot.docs.first.id,
        username: data['username'] ?? '',
        role: data['role'] ?? 'Officer',
        mainRegion: data['mainRegion'] ?? '',
        subRegion: data['subRegion'] ?? '',
      );

      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}
