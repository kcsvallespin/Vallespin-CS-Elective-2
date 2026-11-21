enum AppRole { admin, customer }

/// A row in the Supabase `profiles` table, with the role name joined in.
class Profile {
  final String id;
  final String? email;
  final String? firstname;
  final String? lastname;
  final AppRole role;

  const Profile({
    required this.id,
    this.email,
    this.firstname,
    this.lastname,
    required this.role,
  });

  bool get isAdmin => role == AppRole.admin;

  String get displayName {
    final name = [firstname, lastname]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    return name.isNotEmpty ? name : (email ?? 'Customer');
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final roleName =
        (json['roles'] as Map<String, dynamic>?)?['role'] as String?;
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      // Anything other than an explicit admin role is treated as a customer.
      role: roleName == 'admin' ? AppRole.admin : AppRole.customer,
    );
  }
}
