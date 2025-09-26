import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/models/user.dart';

class ManagePoolMembersPage extends StatefulWidget {
  final PoolOption pool;
  final String ownerId;

  const ManagePoolMembersPage({
    super.key,
    required this.pool,
    required this.ownerId,
  });

  @override
  State<ManagePoolMembersPage> createState() => _ManagePoolMembersPageState();
}

class _ManagePoolMembersPageState extends State<ManagePoolMembersPage> {
  late final SearchController _searchController;
  Timer? _debounce;
  bool _isLoading = true;
  bool _searchBusy = false;
  bool _isInviting = false;
  List<PoolMemberSummary> _members = const [];
  List<UserSearchResult> _searchResults = const [];

  Uri _apiUri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null) {
      return base;
    }
    return base.replace(queryParameters: query);
  }

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    _searchController.addListener(_handleSearchChanged);
    _loadMembers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    if (query.length < 2) {
      if (_searchResults.isNotEmpty || _searchBusy) {
        setState(() {
          _searchBusy = false;
          _searchResults = const [];
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 240), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searchBusy = true;
    });
    try {
      final response = await http.get(
        _apiUri('/users/search', {'q': query, 'pool_id': widget.pool.id}),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final results = decoded
              .whereType<Map<String, dynamic>>()
              .map(UserSearchResult.fromJson)
              .where((user) => user.id.isNotEmpty)
              .toList();
          if (mounted) {
            setState(() {
              _searchResults = results;
            });
          }
        }
      }
    } catch (_) {
      // Network issues silently ignored to keep UI calm.
    } finally {
      if (mounted) {
        setState(() {
          _searchBusy = false;
        });
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        _apiUri('/pools/${widget.pool.id}/memberships', {
          'owner_id': widget.ownerId,
        }),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final list = PoolMembershipList.fromJson(decoded);
          if (mounted) {
            setState(() {
              _members = list.members;
            });
          }
        }
      }
    } catch (_) {
      // Leaving members unchanged on failure.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _inviteUser(UserSearchResult user) async {
    if (_isInviting || user.id.isEmpty) {
      return;
    }
    if (user.membershipStatus == 'active') {
      return;
    }
    setState(() {
      _isInviting = true;
    });
    try {
      final response = await http.post(
        _apiUri('/pools/${widget.pool.id}/invites'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_id': widget.ownerId,
          'invited_user_id': user.id,
        }),
      );
      if (response.statusCode == 200) {
        await _loadMembers();
        if (mounted) {
          setState(() {
            _searchResults = const [];
          });
        }
      }
    } catch (_) {
      // Ignore failures and let owner retry.
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeMembers = _members
        .where((member) => member.status == 'active')
        .toList(growable: false);
    final pendingMembers = _members
        .where((member) => member.status == 'invited')
        .toList(growable: false);
    final otherMembers = _members
        .where(
          (member) => member.status != 'active' && member.status != 'invited',
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text('Manage members — ${widget.pool.name}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SearchAnchor.bar(
                searchController: _searchController,
                barHintText: 'Search by email or display name',
                suggestionsBuilder: (context, controller) {
                  if (_searchBusy) {
                    return [
                      const ListTile(
                        leading: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Searching…'),
                      ),
                    ];
                  }
                  if (_searchResults.isEmpty) {
                    return [
                      const ListTile(
                        leading: Icon(Icons.search_off_outlined),
                        title: Text('No matches yet'),
                      ),
                    ];
                  }
                  return _searchResults.map((result) {
                    final status = result.membershipStatus;
                    final isMember = status == 'active';
                    final isInvited = status == 'invited';
                    Widget? trailing;
                    if (isMember) {
                      trailing = const Chip(label: Text('Member'));
                    } else if (isInvited) {
                      trailing = const Chip(label: Text('Invited'));
                    } else {
                      trailing = ElevatedButton(
                        onPressed: _isInviting
                            ? null
                            : () {
                                controller.closeView(result.displayName);
                                _searchController.text = '';
                                _inviteUser(result);
                              },
                        child: const Text('Invite'),
                      );
                    }
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        result.displayName.isNotEmpty
                            ? result.displayName
                            : result.email,
                      ),
                      subtitle: _buildSearchSubtitle(result),
                      trailing: trailing,
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildSection(
                              theme,
                              title: 'Active members',
                              members: activeMembers,
                              emptyText: 'No active members yet.',
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              theme,
                              title: 'Pending invites',
                              members: pendingMembers,
                              emptyText: 'No pending invites.',
                              badgeLabel: 'Invited',
                            ),
                            if (otherMembers.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSection(
                                theme,
                                title: 'Other members',
                                members: otherMembers,
                                emptyText: '',
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required List<PoolMemberSummary> members,
    required String emptyText,
    String? badgeLabel,
  }) {
    final entries = members;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                emptyText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...entries.map(
                (member) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayName.isNotEmpty
                                  ? member.displayName
                                  : member.email,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (member.email.isNotEmpty)
                              Text(
                                member.email,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusChip(theme, member, badgeLabel),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSubtitle(UserSearchResult result) {
    final lines = <String>[];
    if (result.email.isNotEmpty) {
      lines.add(result.email);
    }
    if (result.username.isNotEmpty) {
      lines.add('@${result.username}');
    }
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(lines.join(' • '));
  }

  Widget _buildStatusChip(
    ThemeData theme,
    PoolMemberSummary member,
    String? pendingLabel,
  ) {
    final label = pendingLabel != null && member.status == 'invited'
        ? pendingLabel
        : member.status == 'active'
        ? (member.role == 'owner' ? 'Owner' : 'Active')
        : member.status == 'declined'
        ? 'Declined'
        : member.status == 'eliminated'
        ? 'Eliminated'
        : member.status;
    return Chip(label: Text(label));
  }
}
