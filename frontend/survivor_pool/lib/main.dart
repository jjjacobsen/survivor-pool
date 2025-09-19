import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SurvivorPoolApp());
}

class AppUser {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? defaultPoolId;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.defaultPoolId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    final displayName = json['display_name'] as String?;
    return AppUser(
      id: json['id'] as String? ?? '',
      username: username,
      email: json['email'] as String? ?? '',
      displayName: (displayName != null && displayName.isNotEmpty)
          ? displayName
          : username,
      defaultPoolId: json['default_pool'] as String?,
    );
  }
}

class SeasonOption {
  final String id;
  final String name;
  final int? number;

  const SeasonOption({required this.id, required this.name, this.number});

  factory SeasonOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final name = json['season_name'] as String? ?? '';
    final dynamicNumber = json['season_number'];
    int? parsedNumber;
    if (dynamicNumber is int) {
      parsedNumber = dynamicNumber;
    } else if (dynamicNumber is num) {
      parsedNumber = dynamicNumber.toInt();
    } else if (dynamicNumber is String) {
      parsedNumber = int.tryParse(dynamicNumber);
    }

    return SeasonOption(
      id: (rawId as String?) ?? '',
      name: name,
      number: parsedNumber,
    );
  }

  String get label {
    if (number != null && number! > 0) {
      return 'Season $number - $name';
    }
    return name.isNotEmpty ? name : 'Unknown season';
  }
}

class SurvivorPoolApp extends StatelessWidget {
  const SurvivorPoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survivor Pool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B365D),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoginMode = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = _isLoginMode ? '/users/login' : '/users';
      final body = _isLoginMode
          ? {
              'email': _emailController.text,
              'password': _passwordController.text,
            }
          : {
              'username': _usernameController.text,
              'email': _emailController.text,
              'password': _passwordController.text,
              'display_name': _displayNameController.text.isNotEmpty
                  ? _displayNameController.text
                  : _usernameController.text,
            };

      final response = await http.post(
        Uri.parse('http://localhost:8000$url'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final user = AppUser.fromJson(data);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage(user: user)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isLoginMode
                    ? 'Login failed. Please check your credentials.'
                    : 'Account creation failed. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0077BE),
                  Color(0xFF00B4D8),
                  Color(0xFF90E0EF),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.waves,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Survivor Pool',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Outlast, Outplay, Outwin',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 32),
                            if (!_isLoginMode) ...[
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name (optional)',
                                  prefixIcon: Icon(Icons.badge),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (!_isLoginMode && value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (!_isLoginMode) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(_isLoginMode ? 'Login' : 'Sign Up'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLoginMode = !_isLoginMode;
                                  _formKey.currentState?.reset();
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  _usernameController.clear();
                                  _displayNameController.clear();
                                });
                              },
                              child: Text(
                                _isLoginMode
                                    ? "Don't have an account? Sign up"
                                    : "Already have an account? Login",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppUser user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<SeasonOption> _seasons = [];
  bool _isLoadingSeasons = false;

  @override
  void initState() {
    super.initState();
    _fetchSeasons();
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action coming soon.')));
  }

  String _parseErrorMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Ignore JSON parsing issues and fall through to default message.
    }
    return 'Failed to create pool. Please try again.';
  }

  Future<bool> _fetchSeasons() async {
    if (_isLoadingSeasons) {
      return _seasons.isNotEmpty;
    }

    if (mounted) {
      setState(() {
        _isLoadingSeasons = true;
      });
    }

    var parsed = _seasons;
    var shouldApply = false;
    var success = _seasons.isNotEmpty;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/seasons'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final list = data
              .whereType<Map<String, dynamic>>()
              .map(SeasonOption.fromJson)
              .where((season) => season.id.isNotEmpty)
              .toList();

          list.sort((a, b) => (b.number ?? 0).compareTo(a.number ?? 0));

          parsed = list;
          shouldApply = true;
          success = parsed.isNotEmpty;
        }
      }
    } catch (_) {
      success = _seasons.isNotEmpty;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSeasons = false;
          if (shouldApply) {
            _seasons = parsed;
          }
        });
      }
    }

    return success;
  }

  Future<bool> _ensureSeasonsLoaded() async {
    if (_seasons.isNotEmpty) {
      return true;
    }

    final loaded = await _fetchSeasons();
    if (!loaded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load seasons. Please try again.'),
        ),
      );
    }
    return loaded;
  }

  Future<void> _showCreatePoolDialog() async {
    final ready = await _ensureSeasonsLoaded();
    if (!mounted || !ready) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreatePoolDialog(
        seasons: List<SeasonOption>.from(_seasons),
        ownerId: widget.user.id,
        messenger: messenger,
        parseErrorMessage: _parseErrorMessage,
      ),
    );

    if (created == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pool created successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;
    final hasDefaultPool =
        user.defaultPoolId != null && user.defaultPoolId!.isNotEmpty;
    final greetingName = user.displayName.isNotEmpty
        ? user.displayName
        : user.username;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Welcome, $greetingName'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: hasDefaultPool
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Pool',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.flag_circle,
                          color: theme.primaryColor,
                          size: 36,
                        ),
                        title: const Text(
                          'You are set to this pool by default',
                        ),
                        subtitle: Text(
                          user.defaultPoolId!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pool details will appear here once the experience is ready.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_add_outlined,
                          size: 80,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No pools yet',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join an existing pool or create a new one to get started.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showComingSoon('Join pool'),
                            child: const Text('Join a Pool'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoadingSeasons
                                ? null
                                : _showCreatePoolDialog,
                            child: _isLoadingSeasons
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Create Pool Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CreatePoolDialog extends StatefulWidget {
  final List<SeasonOption> seasons;
  final String ownerId;
  final ScaffoldMessengerState messenger;
  final String Function(String body) parseErrorMessage;

  const _CreatePoolDialog({
    required this.seasons,
    required this.ownerId,
    required this.messenger,
    required this.parseErrorMessage,
  });

  @override
  State<_CreatePoolDialog> createState() => _CreatePoolDialogState();
}

class _CreatePoolDialogState extends State<_CreatePoolDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _poolNameController;
  String? _selectedSeasonId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _poolNameController = TextEditingController();
    if (widget.seasons.isNotEmpty) {
      _selectedSeasonId = widget.seasons.first.id;
    }
  }

  @override
  void dispose() {
    _poolNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    var shouldReset = true;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/pools'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _poolNameController.text.trim(),
          'season_id': _selectedSeasonId,
          'owner_id': widget.ownerId,
          'invite_user_ids': const <String>[],
        }),
      );

      if (response.statusCode == 201) {
        shouldReset = false;
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      widget.messenger.showSnackBar(
        SnackBar(content: Text(widget.parseErrorMessage(response.body))),
      );
    } catch (error) {
      widget.messenger.showSnackBar(
        SnackBar(content: Text('Network error: $error')),
      );
    } finally {
      if (shouldReset && mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Pool'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _poolNameController,
              decoration: const InputDecoration(labelText: 'Pool name'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pool name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSeasonId,
              decoration: const InputDecoration(labelText: 'Season'),
              items: widget.seasons
                  .map(
                    (season) => DropdownMenuItem<String>(
                      value: season.id,
                      child: Text(season.label),
                    ),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedSeasonId = value;
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a season';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
