import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/network/auth_client.dart';
import 'package:survivor_pool/core/models/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

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
    final existing = AppSession.currentUser.value;
    final token = AppSession.token;
    if (existing != null && token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.goNamed(AppRouteNames.home, extra: existing);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
            };

      final response = await AuthHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$url'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final user = AppUser.fromJson(data);
        final token = data['token'] as String? ?? '';
        if (token.isEmpty) {
          return;
        }
        await AppSession.setSession(user, token);
        if (mounted) {
          setState(() => _errorMessage = null);
          context.goNamed(AppRouteNames.home, extra: user);
        }
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = _extractErrorMessage(response.body);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to reach the server. Try again shortly.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Ignore parse failures and fall back to generic message.
    }
    return 'Unable to sign in with the provided credentials.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.medium;
        final gradient = _buildGradientLayer();
        final overlay = _buildOverlayLayer();
        final authCard = _buildAuthCard(theme, isWide: isWide);

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [gradient, overlay, _buildWideBranding(theme)],
                  ),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: theme.colorScheme.surface),
                    child: authCard,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [gradient, overlay, authCard],
          ),
        );
      },
    );
  }

  Widget _buildGradientLayer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077BE), Color(0xFF00B4D8), Color(0xFF90E0EF)],
        ),
      ),
    );
  }

  Widget _buildOverlayLayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(51), Colors.black.withAlpha(102)],
        ),
      ),
    );
  }

  Widget _buildWideBranding(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.waves, size: 64, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 16),
              Text(
                'Survivor Pool',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Host pools, lock picks, and track standings every week.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBrandChip(theme, Icons.group, 'Run private pools'),
              _buildBrandChip(theme, Icons.timeline, 'See live standings'),
              _buildBrandChip(
                theme,
                Icons.emoji_events_outlined,
                'Celebrate winners',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandChip(ThemeData theme, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, color: theme.colorScheme.primary),
      label: Text(label),
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
    );
  }

  Widget _buildAuthCard(ThemeData theme, {required bool isWide}) {
    final card = Card(
      elevation: isWide ? 6 : 20,
      child: Padding(
        padding: EdgeInsets.all(isWide ? 40 : 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.waves, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Survivor Pool',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Outlast, Outplay, Outwin',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
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
              ],
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: _isLoginMode ? 'Email or Username' : 'Email',
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
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLoginMode ? 'Login' : 'Sign Up'),
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
                    _errorMessage = null;
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
    );

    final horizontalPadding = isWide ? 80.0 : 24.0;
    final verticalPadding = isWide ? 72.0 : 24.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            var minHeight = constraints.maxHeight - (verticalPadding * 2);
            if (minHeight < 0) minHeight = 0;

            final constrainedCard = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: card,
            );

            final content = isWide
                ? Align(alignment: Alignment.topCenter, child: constrainedCard)
                : ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Center(child: constrainedCard),
                  );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: content,
            );
          },
        ),
      ),
    );
  }
}
