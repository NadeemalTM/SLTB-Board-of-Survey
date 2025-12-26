/// User roles in the system
enum UserRole {
  admin,
  fieldOfficer,
}

/// User model for local authentication
class UserModel {
  final String username;
  final String password;
  final UserRole role;
  final String displayName;

  const UserModel({
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isFieldOfficer => role == UserRole.fieldOfficer;
}

/// Hardcoded user accounts for local authentication
class AppUsers {
  // Admin account
  static const UserModel admin = UserModel(
    username: 'admin',
    password: 'admin123',
    role: UserRole.admin,
    displayName: 'System Administrator',
  );

  // Field Officer accounts
  static const List<UserModel> fieldOfficers = [
    UserModel(
      username: 'officer01',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 01',
    ),
    UserModel(
      username: 'officer02',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 02',
    ),
    UserModel(
      username: 'officer03',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 03',
    ),
    UserModel(
      username: 'officer04',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 04',
    ),
    UserModel(
      username: 'officer05',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 05',
    ),
    UserModel(
      username: 'officer06',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 06',
    ),
    UserModel(
      username: 'officer07',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 07',
    ),
    UserModel(
      username: 'officer08',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 08',
    ),
    UserModel(
      username: 'officer09',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 09',
    ),
    UserModel(
      username: 'officer10',
      password: 'field123',
      role: UserRole.fieldOfficer,
      displayName: 'Field Officer 10',
    ),
  ];

  /// Get all users (admin + field officers)
  static List<UserModel> get allUsers => [admin, ...fieldOfficers];

  /// Authenticate user
  static UserModel? authenticate(String username, String password) {
    try {
      return allUsers.firstWhere(
        (user) => user.username == username && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}
