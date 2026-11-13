import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SuperUserScreen extends StatefulWidget {
  final String? userEmail;

  const SuperUserScreen({super.key, this.userEmail});

  @override
  State<SuperUserScreen> createState() => _SuperUserScreenState();
}

class _SuperUserScreenState extends State<SuperUserScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<ManagedUser> _users = [];
  final Set<String> _updatingUserIds = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'todos'; // todos, pacientes, psicologos, activos, inactivos

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _authService.getRegisteredUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar los usuarios: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUser({
    required ManagedUser user,
    required bool isPsychologist,
    required bool isActive,
  }) async {
    if (_updatingUserIds.contains(user.id)) return;

    setState(() {
      _updatingUserIds.add(user.id);
    });

    try {
      final updatedUser = await _authService.updateUserRoleAndStatus(
        userId: user.id,
        isPsychologist: isPsychologist,
        isActive: isActive,
      );

      if (!mounted) return;

      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = updatedUser;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usuario actualizado: ${updatedUser.userTypeLabel} • ${updatedUser.isActive ? "Activo" : "Inactivo"}',
          ),
          backgroundColor: MentalGoTheme.primaryTeal,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el usuario: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingUserIds.remove(user.id);
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  List<ManagedUser> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesFilter = switch (_selectedFilter) {
        'pacientes' => !user.isPsychologist,
        'psicologos' => user.isPsychologist,
        'activos' => user.isActive,
        'inactivos' => !user.isActive,
        _ => true,
      };

      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.cedula.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query);
    }).toList();
  }

  void _openUserDetailModal(ManagedUser user) {
    bool selectedIsPsychologist = user.isPsychologist;
    bool selectedIsActive = user.isActive;
    bool isSavingModal = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MentalGoTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: MentalGoTheme.softMint,
                          child: Icon(
                            selectedIsPsychologist
                                ? Icons.psychology_rounded
                                : Icons.person_rounded,
                            color: MentalGoTheme.primaryTeal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName
                                    : 'Usuario sin nombre',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: MentalGoTheme.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Configuración de permisos y estado',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: MentalGoTheme.subtitleGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Correo electrónico (Bloqueado / No editable)
                    TextFormField(
                      initialValue: user.email,
                      enabled: false,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico (No modificable)',
                        prefixIcon: Icon(Icons.email_outlined),
                        suffixIcon: Icon(Icons.lock_outline_rounded),
                        helperText:
                            'El correo electrónico no se puede modificar desde la app',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cédula (Bloqueada / No editable)
                    TextFormField(
                      initialValue: user.cedula.isNotEmpty
                          ? user.cedula
                          : 'Sin registrar',
                      enabled: false,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Cédula (No modificable)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        suffixIcon: Icon(Icons.lock_outline_rounded),
                        helperText:
                            'La cédula tampoco se puede cambiar desde la app',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selector de Tipo de Usuario (Psicólogo - Paciente)
                    const Text(
                      'Tipo de usuario',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MentalGoTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleOptionCard(
                            label: 'Paciente',
                            icon: Icons.favorite_outline_rounded,
                            isSelected: !selectedIsPsychologist,
                            onTap: () {
                              setModalState(() {
                                selectedIsPsychologist = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleOptionCard(
                            label: 'Psicólogo',
                            icon: Icons.psychology_outlined,
                            isSelected: selectedIsPsychologist,
                            onTap: () {
                              setModalState(() {
                                selectedIsPsychologist = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Estado Activo / Inactivo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FBFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD0EAE4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedIsActive
                                ? Icons.check_circle_outline_rounded
                                : Icons.block_rounded,
                            color: selectedIsActive
                                ? MentalGoTheme.primaryTeal
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estado de la cuenta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: MentalGoTheme.darkNavy,
                                  ),
                                ),
                                Text(
                                  selectedIsActive
                                      ? 'Usuario Activo (puede ingresar a la app)'
                                      : 'Usuario Inactivo (acceso suspendido)',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: MentalGoTheme.subtitleGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: selectedIsActive,
                            activeThumbColor: MentalGoTheme.primaryTeal,
                            onChanged: (value) {
                              setModalState(() {
                                selectedIsActive = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: isSavingModal
                            ? null
                            : () async {
                                setModalState(() => isSavingModal = true);
                                await _updateUser(
                                  user: user,
                                  isPsychologist: selectedIsPsychologist,
                                  isActive: selectedIsActive,
                                );
                                if (modalContext.mounted) {
                                  Navigator.of(modalContext).pop();
                                }
                              },
                        icon: isSavingModal
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _users.length;
    final psychologistsCount = _users.where((u) => u.isPsychologist).length;
    final patientsCount = _users.where((u) => !u.isPsychologist).length;
    final activeCount = _users.where((u) => u.isActive).length;
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: MentalGoTheme.pureWhite,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            children: [
              TextSpan(
                text: 'Mental ',
                style: TextStyle(color: MentalGoTheme.darkNavy),
              ),
              TextSpan(
                text: 'Go ',
                style: TextStyle(color: MentalGoTheme.primaryTeal),
              ),
              TextSpan(
                text: '• Super Usuario',
                style: TextStyle(
                  color: MentalGoTheme.subtitleGray,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            icon: const Icon(
              Icons.refresh_rounded,
              color: MentalGoTheme.darkNavy,
            ),
            onPressed: _isLoading ? null : _loadUsers,
          ),
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(
              Icons.logout_rounded,
              color: MentalGoTheme.darkNavy,
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera de Super Usuario y Estadísticas
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: MentalGoTheme.darkNavy,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: MentalGoTheme.darkNavy.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: MentalGoTheme.primaryTeal.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: MentalGoTheme.primaryTeal,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gestión de Usuarios Registrados',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.userEmail != null &&
                                    widget.userEmail!.isNotEmpty)
                                  Text(
                                    'Sesión: ${widget.userEmail}',
                                    style: const TextStyle(
                                      color: MentalGoTheme.softMint,
                                      fontSize: 12.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SummaryCounter(
                            label: 'Registrados',
                            value: '$totalUsers',
                          ),
                          const SizedBox(width: 8),
                          _SummaryCounter(
                            label: 'Pacientes',
                            value: '$patientsCount',
                          ),
                          const SizedBox(width: 8),
                          _SummaryCounter(
                            label: 'Psicólogos',
                            value: '$psychologistsCount',
                          ),
                          const SizedBox(width: 8),
                          _SummaryCounter(
                            label: 'Activos',
                            value: '$activeCount',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Buscador y Filtros
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, correo o cédula...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChipItem(
                              label: 'Todos',
                              isSelected: _selectedFilter == 'todos',
                              onSelected: () =>
                                  setState(() => _selectedFilter = 'todos'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChipItem(
                              label: 'Pacientes',
                              isSelected: _selectedFilter == 'pacientes',
                              onSelected: () =>
                                  setState(() => _selectedFilter = 'pacientes'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChipItem(
                              label: 'Psicólogos',
                              isSelected: _selectedFilter == 'psicologos',
                              onSelected: () => setState(
                                () => _selectedFilter = 'psicologos',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChipItem(
                              label: 'Activos',
                              isSelected: _selectedFilter == 'activos',
                              onSelected: () =>
                                  setState(() => _selectedFilter = 'activos'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChipItem(
                              label: 'Inactivos',
                              isSelected: _selectedFilter == 'inactivos',
                              onSelected: () =>
                                  setState(() => _selectedFilter = 'inactivos'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de Usuarios
                Expanded(
                  child: _buildUsersContent(filtered),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersContent(List<ManagedUser> users) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: MentalGoTheme.primaryTeal,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MentalGoTheme.darkNavy),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: MentalGoTheme.subtitleGray.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              const Text(
                'No se encontraron usuarios para mostrar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MentalGoTheme.darkNavy,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: MentalGoTheme.primaryTeal,
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index];
          final isUpdating = _updatingUserIds.contains(user.id);

          return _UserManagementCard(
            user: user,
            isUpdating: isUpdating,
            onToggleRole: (isPsychologist) {
              if (user.isPsychologist == isPsychologist) return;
              _updateUser(
                user: user,
                isPsychologist: isPsychologist,
                isActive: user.isActive,
              );
            },
            onToggleActive: (isActive) {
              _updateUser(
                user: user,
                isPsychologist: user.isPsychologist,
                isActive: isActive,
              );
            },
            onOpenDetail: () => _openUserDetailModal(user),
          );
        },
      ),
    );
  }
}

class _SummaryCounter extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCounter({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MentalGoTheme.softMint,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: MentalGoTheme.primaryTeal,
      backgroundColor: MentalGoTheme.pureWhite,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : MentalGoTheme.darkNavy,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? MentalGoTheme.primaryTeal
            : const Color(0xFFD0EAE4),
      ),
    );
  }
}

class _UserManagementCard extends StatelessWidget {
  final ManagedUser user;
  final bool isUpdating;
  final ValueChanged<bool> onToggleRole;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onOpenDetail;

  const _UserManagementCard({
    required this.user,
    required this.isUpdating,
    required this.onToggleRole,
    required this.onToggleActive,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MentalGoTheme.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: user.isActive
              ? const Color(0xFFD0EAE4)
              : Colors.redAccent.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: MentalGoTheme.darkNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado del usuario + botón editar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: user.isActive
                      ? MentalGoTheme.softMint
                      : Colors.grey.shade200,
                  child: Icon(
                    user.isPsychologist
                        ? Icons.psychology_rounded
                        : Icons.person_rounded,
                    color: user.isActive
                        ? MentalGoTheme.primaryTeal
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isNotEmpty
                            ? user.fullName
                            : 'Usuario sin nombre',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: MentalGoTheme.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusBadge(
                            text: user.userTypeLabel,
                            backgroundColor: user.isPsychologist
                                ? const Color(0xFFE0F2FE)
                                : MentalGoTheme.softMint,
                            textColor: user.isPsychologist
                                ? const Color(0xFF0369A1)
                                : MentalGoTheme.primaryTeal,
                          ),
                          _StatusBadge(
                            text: user.isActive ? 'Activo' : 'Inactivo',
                            backgroundColor: user.isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            textColor: user.isActive
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB91C1C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUpdating)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: MentalGoTheme.primaryTeal,
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Ver detalle del usuario',
                    onPressed: onOpenDetail,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: MentalGoTheme.primaryTeal,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Campos bloqueados (Correo y Cédula)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2F1EE)),
              ),
              child: Column(
                children: [
                  _LockedFieldRow(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: user.email,
                  ),
                  const Divider(height: 14, color: Color(0xFFE2F1EE)),
                  _LockedFieldRow(
                    icon: Icons.badge_outlined,
                    label: 'Cédula',
                    value: user.cedula.isNotEmpty
                        ? user.cedula
                        : 'Sin registrar',
                  ),
                  if (user.phone.isNotEmpty) ...[
                    const Divider(height: 14, color: Color(0xFFE2F1EE)),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: MentalGoTheme.subtitleGray,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Teléfono: ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: MentalGoTheme.subtitleGray,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            user.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: MentalGoTheme.darkNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Controles de Tipo de Usuario (Psicólogo - Paciente) y Estado Activo
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de usuario',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MentalGoTheme.subtitleGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _CompactRoleButton(
                              label: 'Paciente',
                              isSelected: !user.isPsychologist,
                              onTap: isUpdating
                                  ? null
                                  : () => onToggleRole(false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactRoleButton(
                              label: 'Psicólogo',
                              isSelected: user.isPsychologist,
                              onTap: isUpdating
                                  ? null
                                  : () => onToggleRole(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user.isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: user.isActive
                            ? MentalGoTheme.primaryTeal
                            : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Switch(
                      value: user.isActive,
                      activeThumbColor: MentalGoTheme.primaryTeal,
                      onChanged: isUpdating ? null : onToggleActive,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedFieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LockedFieldRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MentalGoTheme.subtitleGray),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: MentalGoTheme.subtitleGray,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: MentalGoTheme.darkNavy,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Campo protegido: no se puede modificar desde la app',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 3),
                Text(
                  'Fijo',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _StatusBadge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _CompactRoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CompactRoleButton({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? MentalGoTheme.primaryTeal
              : const Color(0xFFF7FBFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? MentalGoTheme.primaryTeal
                : const Color(0xFFD0EAE4),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : MentalGoTheme.darkNavy,
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? MentalGoTheme.softMint : const Color(0xFFF7FBFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? MentalGoTheme.primaryTeal
                : const Color(0xFFD0EAE4),
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? MentalGoTheme.primaryTeal
                  : MentalGoTheme.subtitleGray,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? MentalGoTheme.darkNavy
                    : MentalGoTheme.subtitleGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
