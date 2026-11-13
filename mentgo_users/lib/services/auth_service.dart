import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool isAuthenticated;
  final bool isSuperUser;
  final String email;
  final String role;

  const AuthResult({
    required this.isAuthenticated,
    required this.isSuperUser,
    required this.email,
    required this.role,
  });
}

class ManagedUser {
  final String id;
  final String email;
  final String fullName;
  final String cedula;
  final String phone;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const ManagedUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.cedula,
    required this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  bool get isPsychologist => role == 'specialist' || role == 'psicologo';

  bool get isAdmin =>
      role == 'admin' ||
      email.trim().toLowerCase() == AuthService.superUserEmail;

  String get userTypeLabel => isPsychologist ? 'Psicólogo' : 'Paciente';

  factory ManagedUser.fromMap(Map<String, dynamic> map) {
    return ManagedUser(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      cedula: (map['cedula'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  ManagedUser copyWith({
    String? role,
    bool? isActive,
  }) {
    return ManagedUser(
      id: id,
      email: email,
      fullName: fullName,
      cedula: cedula,
      phone: phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

class AuthService {
  static const String superUserEmail = 'mentalgo2026@gmail.com';

  /// Valores en base de datos para los tipos de usuario manejados por el Super Usuario.
  static const String rolePaciente = 'user';
  static const String rolePsicologo = 'specialist';

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Inicia sesión con correo electrónico y contraseña en Supabase y consulta su rol y estado en `public.users`.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final AuthResponse response = await _supabase.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('No se pudo iniciar sesión. Verifica tus credenciales.');
    }

    String role = rolePaciente;
    bool isActive = true;
    try {
      final profile = await _supabase
          .from('users')
          .select('role, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        if (profile['role'] != null) {
          role = profile['role'] as String;
        }
        if (profile['is_active'] != null) {
          isActive = profile['is_active'] as bool;
        }
      }
    } catch (_) {
      // Si ocurre algún problema consultando el perfil, se mantienen los valores por defecto
    }

    final isSuper = role == 'admin' || normalizedEmail == superUserEmail;

    if (!isSuper && !isActive) {
      await _supabase.auth.signOut();
      throw Exception(
        'Tu cuenta se encuentra inactiva. Contacta al administrador.',
      );
    }

    return AuthResult(
      isAuthenticated: true,
      isSuperUser: isSuper,
      email: normalizedEmail,
      role: isSuper ? 'admin' : role,
    );
  }

  /// Registra un nuevo usuario directamente en Supabase Auth y sincroniza con `public.users`.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userMetadata,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final AuthResponse response = await _supabase.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: userMetadata,
    );

    if (response.user == null) {
      throw Exception('No fue posible completar el registro en Supabase.');
    }

    // Garantiza que los datos iniciales queden registrados en public.users.
    // Nota: El correo y la cédula se asignan únicamente al crear la cuenta y no pueden modificarse después.
    if (userMetadata != null) {
      try {
        await _supabase.from('users').upsert({
          'id': response.user!.id,
          'email': normalizedEmail,
          'full_name': userMetadata['full_name'],
          'cedula': userMetadata['cedula'],
          'phone': userMetadata['phone'],
        });
      } catch (_) {}
    }

    return true;
  }

  /// Obtiene la lista de usuarios registrados en `public.users` (excluyendo al super usuario).
  Future<List<ManagedUser>> getRegisteredUsers() async {
    final response = await _supabase
        .from('users')
        .select('id, email, full_name, cedula, phone, role, is_active, created_at')
        .order('created_at', ascending: false);

    final users = (response as List<dynamic>)
        .map((row) => ManagedUser.fromMap(row as Map<String, dynamic>))
        .where((u) => !u.isAdmin)
        .toList();

    return users;
  }

  /// Actualiza únicamente el tipo de usuario (Psicólogo / Paciente) y el estado activo.
  /// El correo y la cédula nunca se envían ni pueden modificarse desde la app.
  Future<ManagedUser> updateUserRoleAndStatus({
    required String userId,
    required bool isPsychologist,
    required bool isActive,
  }) async {
    final newRole = isPsychologist ? rolePsicologo : rolePaciente;

    final updated = await _supabase
        .from('users')
        .update({
          'role': newRole,
          'is_active': isActive,
        })
        .eq('id', userId)
        .select('id, email, full_name, cedula, phone, role, is_active, created_at')
        .single();

    return ManagedUser.fromMap(updated);
  }

  /// Cierra la sesión activa en Supabase.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
  }
}
