import 'dart:async';
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

class PoolOption {
  final String id;
  final String name;
  final String seasonId;
  final String? ownerId;
  final int? seasonNumber;
  final int currentWeek;

  const PoolOption({
    required this.id,
    required this.name,
    required this.seasonId,
    this.ownerId,
    this.seasonNumber,
    this.currentWeek = 1,
  });

  factory PoolOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final seasonId = json['season_id'] ?? json['seasonId'] ?? '';
    final ownerId = json['owner_id'] ?? json['ownerId'];
    final dynamicSeasonNumber = json['season_number'] ?? json['seasonNumber'];
    final dynamicCurrentWeek = json['current_week'] ?? json['currentWeek'];
    int? parsedSeasonNumber;
    if (dynamicSeasonNumber is int) {
      parsedSeasonNumber = dynamicSeasonNumber;
    } else if (dynamicSeasonNumber is num) {
      parsedSeasonNumber = dynamicSeasonNumber.toInt();
    } else if (dynamicSeasonNumber is String) {
      parsedSeasonNumber = int.tryParse(dynamicSeasonNumber);
    }
    var parsedCurrentWeek = 1;
    if (dynamicCurrentWeek is int) {
      parsedCurrentWeek = dynamicCurrentWeek;
    } else if (dynamicCurrentWeek is num) {
      parsedCurrentWeek = dynamicCurrentWeek.toInt();
    } else if (dynamicCurrentWeek is String) {
      parsedCurrentWeek = int.tryParse(dynamicCurrentWeek) ?? 1;
    }
    return PoolOption(
      id: (rawId as String?) ?? '',
      name: json['name'] as String? ?? 'Untitled Pool',
      seasonId: (seasonId as String?) ?? '',
      ownerId: ownerId is String ? ownerId : null,
      seasonNumber: parsedSeasonNumber,
      currentWeek: parsedCurrentWeek,
    );
  }

  PoolOption copyWith({
    String? id,
    String? name,
    String? seasonId,
    String? ownerId,
    int? seasonNumber,
    int? currentWeek,
  }) {
    return PoolOption(
      id: id ?? this.id,
      name: name ?? this.name,
      seasonId: seasonId ?? this.seasonId,
      ownerId: ownerId ?? this.ownerId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      currentWeek: currentWeek ?? this.currentWeek,
    );
  }
}

class AvailableContestant {
  final String id;
  final String name;
  final String? subtitle;

  const AvailableContestant({
    required this.id,
    required this.name,
    this.subtitle,
  });

  factory AvailableContestant.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final subtitle = json['subtitle'];
    return AvailableContestant(
      id: id,
      name: name.isEmpty ? id : name,
      subtitle: subtitle is String ? subtitle : null,
    );
  }
}

class CurrentPickSummary {
  final String id;
  final String contestantId;
  final String contestantName;
  final int week;
  final DateTime lockedAt;

  const CurrentPickSummary({
    required this.id,
    required this.contestantId,
    required this.contestantName,
    required this.week,
    required this.lockedAt,
  });

  factory CurrentPickSummary.fromJson(Map<String, dynamic> json) {
    final id = json['pick_id'] as String? ?? json['id'] as String? ?? '';
    final contestantId = json['contestant_id'] as String? ?? '';
    final contestantName = json['contestant_name'] as String? ?? contestantId;
    final rawWeek = json['week'];
    final rawLocked = json['locked_at'];
    var parsedWeek = 0;
    if (rawWeek is int) {
      parsedWeek = rawWeek;
    } else if (rawWeek is num) {
      parsedWeek = rawWeek.toInt();
    } else if (rawWeek is String) {
      parsedWeek = int.tryParse(rawWeek) ?? 0;
    }
    DateTime lockedAt;
    if (rawLocked is String) {
      lockedAt = DateTime.tryParse(rawLocked) ?? DateTime.now();
    } else if (rawLocked is int) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked);
    } else if (rawLocked is num) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked.toInt());
    } else if (rawLocked is DateTime) {
      lockedAt = rawLocked;
    } else {
      lockedAt = DateTime.now();
    }

    return CurrentPickSummary(
      id: id,
      contestantId: contestantId,
      contestantName: contestantName.isEmpty ? contestantId : contestantName,
      week: parsedWeek,
      lockedAt: lockedAt,
    );
  }
}

class ContestantDetail {
  final String id;
  final String name;
  final int? age;
  final String? occupation;
  final String? hometown;

  const ContestantDetail({
    required this.id,
    required this.name,
    this.age,
    this.occupation,
    this.hometown,
  });

  factory ContestantDetail.fromJson(Map<String, dynamic> json) {
    final rawAge = json['age'];
    int? parsedAge;
    if (rawAge is int) {
      parsedAge = rawAge;
    } else if (rawAge is num) {
      parsedAge = rawAge.toInt();
    } else if (rawAge is String) {
      parsedAge = int.tryParse(rawAge);
    }

    return ContestantDetail(
      id: json['id'] as String? ?? '',
      name: (json['name'] is String && (json['name'] as String).isNotEmpty)
          ? json['name'] as String
          : (json['id'] as String? ?? ''),
      age: parsedAge,
      occupation: json['occupation'] as String?,
      hometown: json['hometown'] as String?,
    );
  }
}

class ContestantDetailResponse {
  final ContestantDetail contestant;
  final bool isAvailable;
  final int? eliminatedWeek;
  final int? alreadyPickedWeek;
  final CurrentPickSummary? currentPick;

  const ContestantDetailResponse({
    required this.contestant,
    required this.isAvailable,
    this.eliminatedWeek,
    this.alreadyPickedWeek,
    this.currentPick,
  });

  factory ContestantDetailResponse.fromJson(Map<String, dynamic> json) {
    final contestantJson = json['contestant'] as Map<String, dynamic>?;
    final currentPickJson = json['current_pick'] as Map<String, dynamic>?;
    return ContestantDetailResponse(
      contestant: contestantJson != null
          ? ContestantDetail.fromJson(contestantJson)
          : const ContestantDetail(id: '', name: ''),
      isAvailable: json['is_available'] as bool? ?? false,
      eliminatedWeek: json['eliminated_week'] is int
          ? json['eliminated_week'] as int
          : int.tryParse('${json['eliminated_week']}'),
      alreadyPickedWeek: json['already_picked_week'] is int
          ? json['already_picked_week'] as int
          : int.tryParse('${json['already_picked_week']}'),
      currentPick: currentPickJson != null
          ? CurrentPickSummary.fromJson(currentPickJson)
          : null,
    );
  }
}

class PickResponse {
  final String id;
  final String contestantId;
  final int week;
  final DateTime lockedAt;

  const PickResponse({
    required this.id,
    required this.contestantId,
    required this.week,
    required this.lockedAt,
  });

  factory PickResponse.fromJson(Map<String, dynamic> json) {
    final rawLocked = json['locked_at'];
    DateTime lockedAt;
    if (rawLocked is String) {
      lockedAt = DateTime.tryParse(rawLocked) ?? DateTime.now();
    } else if (rawLocked is int) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked);
    } else if (rawLocked is num) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked.toInt());
    } else if (rawLocked is DateTime) {
      lockedAt = rawLocked;
    } else {
      lockedAt = DateTime.now();
    }

    final rawWeek = json['week'];
    var parsedWeek = 0;
    if (rawWeek is int) {
      parsedWeek = rawWeek;
    } else if (rawWeek is num) {
      parsedWeek = rawWeek.toInt();
    } else if (rawWeek is String) {
      parsedWeek = int.tryParse(rawWeek) ?? 0;
    }

    final id = json['pick_id'] as String? ?? json['id'] as String? ?? '';

    return PickResponse(
      id: id,
      contestantId: json['contestant_id'] as String? ?? '',
      week: parsedWeek,
      lockedAt: lockedAt,
    );
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
              'identifier': _emailController.text,
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
                  Colors.black.withAlpha(51),
                  Colors.black.withAlpha(102),
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
                              decoration: InputDecoration(
                                labelText: _isLoginMode
                                    ? 'Email or Username'
                                    : 'Email',
                                prefixIcon: const Icon(Icons.email),
                              ),
                              keyboardType: _isLoginMode
                                  ? TextInputType.text
                                  : TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return _isLoginMode
                                      ? 'Please enter your email or username'
                                      : 'Please enter your email';
                                }
                                if (!_isLoginMode && !value.contains('@')) {
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
  List<PoolOption> _pools = [];
  bool _isLoadingPools = false;
  String? _defaultPoolId;
  bool _isUpdatingDefault = false;
  List<AvailableContestant> _availableContestants = const [];
  bool _isLoadingContestants = false;
  String? _contestantsForPoolId;
  CurrentPickSummary? _currentPick;
  List<PoolOption> _applySeasonNumbers(
    List<PoolOption> pools, {
    List<SeasonOption>? seasons,
  }) {
    final catalog = seasons ?? _seasons;
    if (catalog.isEmpty) {
      return pools;
    }

    final byId = {for (final season in catalog) season.id: season};

    return pools.map((pool) {
      final match = byId[pool.seasonId];
      if (match == null) {
        return pool;
      }
      final number = match.number;
      if (number == null || number == pool.seasonNumber) {
        return pool;
      }
      return pool.copyWith(seasonNumber: number);
    }).toList();
  }

  Future<void> _loadAvailableContestants(String? poolId) async {
    if (!mounted) {
      return;
    }

    if (poolId == null || poolId.isEmpty) {
      setState(() {
        _availableContestants = const [];
        _contestantsForPoolId = null;
        _isLoadingContestants = false;
        _currentPick = null;
      });
      return;
    }

    setState(() {
      _isLoadingContestants = true;
      if (_contestantsForPoolId != poolId) {
        _availableContestants = const [];
        _currentPick = null;
      }
      _contestantsForPoolId = poolId;
    });

    List<AvailableContestant> parsed = const <AvailableContestant>[];
    CurrentPickSummary? parsedCurrentPick;
    var updated = false;

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/pools/$poolId/available_contestants?user_id=${widget.user.id}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final items = decoded['contestants'];
          if (items is List) {
            parsed = items
                .whereType<Map<String, dynamic>>()
                .map(AvailableContestant.fromJson)
                .where((contestant) => contestant.id.isNotEmpty)
                .toList();
            updated = true;
          }
          final pickData = decoded['current_pick'];
          if (pickData is Map<String, dynamic>) {
            parsedCurrentPick = CurrentPickSummary.fromJson(pickData);
          }
        }
      }
    } catch (_) {
      updated = false;
    } finally {
      if (mounted && _contestantsForPoolId == poolId) {
        setState(() {
          _isLoadingContestants = false;
          if (updated) {
            _availableContestants = parsed;
          }
          _currentPick = parsedCurrentPick;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _defaultPoolId = widget.user.defaultPoolId;
    _fetchSeasons();
    _loadPools();
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

    var success = _seasons.isNotEmpty;
    List<SeasonOption>? fetched;

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

          fetched = list;
          success = list.isNotEmpty;
        }
      }
    } catch (_) {
      success = _seasons.isNotEmpty;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSeasons = false;
          final seasons = fetched;
          if (seasons != null) {
            _seasons = seasons;
            _pools = _applySeasonNumbers(_pools, seasons: seasons);
          }
        });
      }
    }

    return success;
  }

  Future<void> _loadPools() async {
    if (_isLoadingPools) {
      return;
    }

    setState(() {
      _isLoadingPools = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/users/${widget.user.id}/pools'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final mapped = data
              .whereType<Map<String, dynamic>>()
              .map(PoolOption.fromJson)
              .where((pool) => pool.id.isNotEmpty)
              .toList();
          mapped.sort((a, b) => a.name.compareTo(b.name));
          final decorated = _applySeasonNumbers(mapped);

          if (mounted) {
            setState(() {
              _pools = decorated;
              if (_defaultPoolId != null &&
                  !decorated.any((pool) => pool.id == _defaultPoolId)) {
                _defaultPoolId = null;
              }
            });
            unawaited(_loadAvailableContestants(_defaultPoolId));
          }
        }
      }
    } catch (_) {
      // Ignore errors; the selector UI will remain unchanged.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPools = false;
        });
      }
    }
  }

  Future<bool> _ensureSeasonsLoaded() async {
    if (_seasons.isNotEmpty) {
      return true;
    }

    final messenger = ScaffoldMessenger.of(context);
    final loaded = await _fetchSeasons();
    if (!loaded && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to load seasons. Please try again.'),
        ),
      );
    }
    return loaded;
  }

  Future<ContestantDetailResponse?> _fetchContestantDetail(
    String poolId,
    String contestantId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/pools/$poolId/contestants/$contestantId?user_id=${widget.user.id}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ContestantDetailResponse.fromJson(decoded);
        }
      } else {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Unable to load contestant. (${response.statusCode})',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Network error: $error')),
        );
      }
    }
    return null;
  }

  Future<PickResponse?> _lockPick(String poolId, String contestantId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/pools/$poolId/picks'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.user.id,
          'contestant_id': contestantId,
        }),
      );

      if (response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return PickResponse.fromJson(decoded);
        }
      } else {
        String message = 'Unable to lock pick. (${response.statusCode})';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            final detail = decoded['detail'];
            if (detail is String && detail.isNotEmpty) {
              message = detail;
            }
          }
        } catch (_) {}
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Network error: $error')),
        );
      }
    }
    return null;
  }

  Future<void> _handleContestantSelected(
    PoolOption pool,
    AvailableContestant contestant,
  ) async {
    final detail = await _fetchContestantDetail(pool.id, contestant.id);
    if (!mounted || detail == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContestantDetailPage(
          pool: pool,
          detail: detail,
          onLockPick: () => _handleLockPick(pool, detail.contestant),
        ),
      ),
    );
  }

  Future<bool> _handleLockPick(
    PoolOption pool,
    ContestantDetail contestant,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final pick = await _lockPick(pool.id, contestant.id);
    if (pick == null) {
      return false;
    }

    if (!mounted) {
      return true;
    }

    final summary = CurrentPickSummary(
      id: pick.id,
      contestantId: pick.contestantId,
      contestantName: contestant.name.isNotEmpty
          ? contestant.name
          : pick.contestantId,
      week: pick.week,
      lockedAt: pick.lockedAt,
    );

    setState(() {
      _currentPick = summary;
    });

    messenger.showSnackBar(
      SnackBar(content: Text('Pick locked for ${summary.contestantName}.')),
    );

    await _loadAvailableContestants(pool.id);
    return true;
  }

  Future<void> _showCreatePoolDialog() async {
    final ready = await _ensureSeasonsLoaded();
    if (!mounted || !ready) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreatePoolDialog(
        seasons: List<SeasonOption>.from(_seasons),
        ownerId: widget.user.id,
        messenger: messenger,
        parseErrorMessage: _parseErrorMessage,
      ),
    );

    if (created != null) {
      final newPool = PoolOption.fromJson(created);
      if (newPool.id.isNotEmpty) {
        setState(() {
          _pools = [..._pools.where((pool) => pool.id != newPool.id), newPool]
            ..sort((a, b) => a.name.compareTo(b.name));
          _defaultPoolId = newPool.id;
          _availableContestants = const [];
          _contestantsForPoolId = null;
          _isLoadingContestants = true;
        });
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Pool "${newPool.name}" created.')),
      );

      unawaited(_loadPools());
    }
  }

  Future<void> _updateDefaultPool(String? poolId) async {
    if (_isUpdatingDefault || _defaultPoolId == poolId) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final previous = _defaultPoolId;

    setState(() {
      _isUpdatingDefault = true;
      _defaultPoolId = poolId;
    });
    unawaited(_loadAvailableContestants(poolId));

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:8000/users/${widget.user.id}/default_pool'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'default_pool': poolId}),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _defaultPoolId = previous;
          });
        }
        unawaited(_loadAvailableContestants(previous));
        messenger.showSnackBar(
          SnackBar(content: Text(_parseErrorMessage(response.body))),
        );
      } else {
        final decoded = json.decode(response.body);
        final serverDefault = decoded is Map<String, dynamic>
            ? decoded['default_pool'] as String?
            : null;
        if (mounted) {
          setState(() {
            _defaultPoolId = serverDefault;
          });
        }
        if (serverDefault != poolId) {
          unawaited(_loadAvailableContestants(serverDefault));
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _defaultPoolId = previous;
        });
      }
      unawaited(_loadAvailableContestants(previous));
      messenger.showSnackBar(SnackBar(content: Text('Network error: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingDefault = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeDefaultPoolId =
        (_defaultPoolId != null &&
            _pools.any((pool) => pool.id == _defaultPoolId))
        ? _defaultPoolId
        : null;

    final selectedPool = safeDefaultPoolId == null
        ? null
        : _pools.firstWhere(
            (pool) => pool.id == safeDefaultPoolId,
            orElse: () => PoolOption(
              id: safeDefaultPoolId,
              name: 'Unknown Pool',
              seasonId: '',
              ownerId: null,
              seasonNumber: null,
              currentWeek: 1,
            ),
          );

    final isOwnerView =
        selectedPool != null &&
        (selectedPool.ownerId == null ||
            selectedPool.ownerId == widget.user.id);
    List<AvailableContestant> availableContestants;
    var isLoadingContestants = false;
    if (selectedPool == null) {
      availableContestants = const <AvailableContestant>[];
    } else if (_contestantsForPoolId == selectedPool.id) {
      availableContestants = _availableContestants;
      isLoadingContestants = _isLoadingContestants;
    } else {
      availableContestants = const <AvailableContestant>[];
      isLoadingContestants = true;
    }

    final currentPick = (_contestantsForPoolId == selectedPool?.id)
        ? _currentPick
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        titleSpacing: 12,
        title: _buildDefaultPoolSelector(theme, safeDefaultPoolId),
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
          child: _isLoadingPools && _pools.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _defaultPoolId != null && selectedPool != null
              ? isOwnerView
                    ? PoolOwnerDashboard(
                        pool: selectedPool,
                        availableContestants: availableContestants,
                        isLoadingContestants: isLoadingContestants,
                        currentPick: currentPick,
                        onManageMembers: () {},
                        onManageSettings: () {},
                        onAdvanceWeek: () {},
                        onContestantSelected: (contestant) {
                          _handleContestantSelected(selectedPool, contestant);
                        },
                      )
                    : PoolPlaceholder(pool: selectedPool)
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
                          _pools.isEmpty ? 'No pools yet' : 'Select a pool',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _pools.isEmpty
                              ? 'Create a new pool or use an invite to get started.'
                              : 'Choose a default pool from the dropdown above to view its details.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
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

  Widget _buildDefaultPoolSelector(ThemeData theme, String? selectedPoolId) {
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    final allPools = <({String? id, String label})>[
      (id: null, label: 'Home'),
      ..._pools.map((pool) => (id: pool.id, label: pool.name)),
    ];

    final items = allPools
        .map(
          (entry) => _buildPoolMenuItem(
            entry.id,
            entry.label,
            theme,
            isSelected: selectedPoolId == entry.id,
          ),
        )
        .toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(61),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(89), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedPoolId,
                      isExpanded: true,
                      items: items,
                      onChanged: _isUpdatingDefault
                          ? null
                          : (value) => _updateDefaultPool(value),
                      style: textStyle,
                      dropdownColor: theme.colorScheme.surface,
                      iconEnabledColor: Colors.white,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(12),
                      selectedItemBuilder: (context) => allPools
                          .map(
                            (entry) => Row(
                              children: [
                                Icon(
                                  entry.id == null
                                      ? Icons.home_outlined
                                      : Icons.flag_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: textStyle,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                      hint: Text('Select pool', style: textStyle),
                    ),
                  ),
                ),
                if (_isUpdatingDefault || _isLoadingPools) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String?> _buildPoolMenuItem(
    String? id,
    String label,
    ThemeData theme, {
    bool isSelected = false,
  }) {
    return DropdownMenuItem<String?>(
      value: id,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(31)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              id == null ? Icons.home_outlined : Icons.flag_outlined,
              size: 18,
              color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PoolOwnerDashboard extends StatelessWidget {
  final PoolOption pool;
  final List<AvailableContestant> availableContestants;
  final bool isLoadingContestants;
  final CurrentPickSummary? currentPick;
  final VoidCallback? onManageMembers;
  final VoidCallback? onManageSettings;
  final VoidCallback? onAdvanceWeek;
  final void Function(AvailableContestant contestant)? onContestantSelected;

  const PoolOwnerDashboard({
    super.key,
    required this.pool,
    this.availableContestants = const [],
    this.isLoadingContestants = false,
    this.currentPick,
    this.onManageMembers,
    this.onManageSettings,
    this.onAdvanceWeek,
    this.onContestantSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final estimatedHeight = availableContestants.length * 76.0;
        final listHeight = availableContestants.isEmpty
            ? 160.0
            : estimatedHeight < 220.0
            ? 220.0
            : estimatedHeight > 420.0
            ? 420.0
            : estimatedHeight;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(theme),
              const SizedBox(height: 24),
              _buildWeeklyPickCard(theme, listHeight, currentPick),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final membersHandler = onManageMembers ?? () {};
    final settingsHandler = onManageSettings ?? () {};
    final advanceHandler = onAdvanceWeek ?? () {};
    final seasonDescription = pool.seasonNumber != null
        ? 'Season: ${pool.seasonNumber}'
        : pool.seasonId.isEmpty
        ? 'Season details coming soon'
        : 'Season: ${pool.seasonId}';

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      pool.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: settingsHandler,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Pool settings'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                seasonDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: membersHandler,
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('Manage members'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: advanceHandler,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Advance to next week'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPickCard(
    ThemeData theme,
    double listHeight,
    CurrentPickSummary? currentPick,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This Week's Pick",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Week ${pool.currentWeek}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              currentPick != null
                  ? 'Pick locked in for this week.'
                  : 'Choose a contestant below to review their details before locking your pick.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (currentPick != null)
              _buildLockedPickSummary(theme, currentPick)
            else
              SizedBox(height: listHeight, child: _buildContestantList(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildContestantList(ThemeData theme) {
    if (isLoadingContestants) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableContestants.isEmpty) {
      return Center(
        child: Text(
          'No available contestants yet. Check back after the next elimination.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scrollbar(
      child: ListView.separated(
        itemCount: availableContestants.length,
        itemBuilder: (context, index) {
          final contestant = availableContestants[index];
          return FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              final handler = onContestantSelected;
              if (handler != null) {
                handler(contestant);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contestant.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (contestant.subtitle != null &&
                          contestant.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contestant.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(height: 12),
      ),
    );
  }

  Widget _buildLockedPickSummary(ThemeData theme, CurrentPickSummary summary) {
    final handler = onContestantSelected;
    final lockedAt = summary.lockedAt.toLocal();
    final timestamp = _formatTimestamp(lockedAt);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.contestantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Locked at $timestamp',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: handler == null
                ? null
                : () {
                    handler(
                      AvailableContestant(
                        id: summary.contestantId,
                        name: summary.contestantName,
                      ),
                    );
                  },
            icon: const Icon(Icons.info_outline),
            label: const Text('View contestant details'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final year = value.year;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day/$year $hour:$minute';
  }
}

class PoolPlaceholder extends StatelessWidget {
  final PoolOption pool;

  const PoolPlaceholder({super.key, required this.pool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pool.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.primaryColor.withAlpha(51)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pool dashboard coming soon for ${pool.name}.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  pool.seasonNumber != null
                      ? 'Season: ${pool.seasonNumber}'
                      : "Season: ${pool.seasonId.isEmpty ? 'TBD' : pool.seasonId}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
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

class ContestantDetailPage extends StatefulWidget {
  final PoolOption pool;
  final ContestantDetailResponse detail;
  final Future<bool> Function() onLockPick;

  const ContestantDetailPage({
    super.key,
    required this.pool,
    required this.detail,
    required this.onLockPick,
  });

  @override
  State<ContestantDetailPage> createState() => _ContestantDetailPageState();
}

class _ContestantDetailPageState extends State<ContestantDetailPage> {
  bool _isSubmitting = false;

  Future<void> _handleLock() async {
    if (_isSubmitting || !widget.detail.isAvailable) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.onLockPick();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = widget.detail.contestant;
    final chips = <Widget>[];

    if (detail.age != null) {
      chips.add(_buildInfoChip('Age', detail.age.toString(), theme));
    }
    if (detail.occupation != null && detail.occupation!.isNotEmpty) {
      chips.add(_buildInfoChip('Occupation', detail.occupation!, theme));
    }
    if (detail.hometown != null && detail.hometown!.isNotEmpty) {
      chips.add(_buildInfoChip('Hometown', detail.hometown!, theme));
    }

    final statusNotes = <Widget>[];
    if (widget.detail.currentPick != null &&
        widget.detail.currentPick!.contestantId != detail.id) {
      final pick = widget.detail.currentPick!;
      statusNotes.add(
        _buildStatusNote(
          theme,
          'You already locked ${pick.contestantName} for week ${pick.week}.',
        ),
      );
    }

    final alreadyPickedWeek = widget.detail.alreadyPickedWeek;
    final currentPickId = widget.detail.currentPick?.contestantId;
    if (alreadyPickedWeek != null && currentPickId != detail.id) {
      statusNotes.add(
        _buildStatusNote(
          theme,
          'You previously picked ${detail.name} in week $alreadyPickedWeek.',
        ),
      );
    }

    if (widget.detail.eliminatedWeek != null) {
      statusNotes.add(
        _buildStatusNote(
          theme,
          '${detail.name} was eliminated in week ${widget.detail.eliminatedWeek}.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.name.isEmpty ? 'Contestant' : detail.name),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Week ${widget.pool.currentWeek} · ${widget.pool.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (chips.isNotEmpty)
                      Wrap(spacing: 12, runSpacing: 12, children: chips),
                    if (statusNotes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ...statusNotes,
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.detail.isAvailable && !_isSubmitting
                      ? _handleLock
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    widget.detail.isAvailable ? 'Lock Pick' : 'Unavailable',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStatusNote(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(46),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
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
        final decoded = json.decode(response.body);
        if (mounted) {
          Navigator.of(
            context,
          ).pop(decoded is Map<String, dynamic> ? decoded : null);
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
