/// 로그인한 포털 사용자(매장 등).
class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String roleLabel;
  final int? storeId;
  final String? storeName;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleLabel,
    required this.storeId,
    required this.storeName,
  });

  bool get isStore => role == 'store' && storeId != null;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? '',
        roleLabel: j['role_label'] as String? ?? '',
        storeId: j['store_id'] as int?,
        storeName: j['store_name'] as String?,
      );
}
