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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _isLoading = true;
  bool _searchBusy = false;
  bool _isInviting = false;
  int _searchRequestId = 0;
  String _latestDeliveredQuery = '';
  String _currentNormalizedQuery = '';
  String? _invitingUserId;
  List<PoolMemberSummary> _members = const [];
  List<UserSearchResult> _searchResults = const [];
  final Map<String, List<UserSearchResult>> _searchCache = {};

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
    _loadMembers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _normalizeQuery(String value) => value.trim().toLowerCase();

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _currentNormalizedQuery = '';
      _latestDeliveredQuery = '';
      _searchBusy = false;
      _searchResults = const [];
    });
    _searchFocusNode.requestFocus();
  }

  void _onQueryChanged(String value) {
    final normalized = _normalizeQuery(value);
    _debounce?.cancel();
    final cached = _searchCache[normalized];
    setState(() {
      _currentNormalizedQuery = normalized;
      if (normalized.length < 2) {
        _searchBusy = false;
        _searchResults = const [];
        return;
      }
      if (cached != null) {
        _searchResults = cached;
        _latestDeliveredQuery = normalized;
      }
    });
    if (normalized.length < 2) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String rawQuery) async {
    final normalized = _normalizeQuery(rawQuery);
    if (normalized.length < 2) {
      return;
    }
    final requestId = ++_searchRequestId;
    setState(() {
      _searchBusy = true;
    });
    try {
      final response = await http.get(
        _apiUri('/users/search', {
          'q': rawQuery.trim(),
          'pool_id': widget.pool.id,
          'limit': '15',
        }),
      );
      if (!mounted || requestId != _searchRequestId) {
        return;
      }
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final results = decoded
              .whereType<Map<String, dynamic>>()
              .map(UserSearchResult.fromJson)
              .where((user) => user.id.isNotEmpty)
              .toList(growable: false);
          setState(() {
            _searchCache[normalized] = results;
            _searchResults = results;
            _latestDeliveredQuery = normalized;
          });
        }
      }
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) {
        return;
      }
      setState(() {
        _searchCache.remove(normalized);
      });
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() {
          _searchBusy = false;
        });
      }
    }
  }

  void _updateSearchStatusForUser(String userId, String status) {
    final query = _latestDeliveredQuery;
    if (query.isEmpty) {
      return;
    }
    final cached = _searchCache[query];
    if (cached == null) {
      return;
    }
    final blocked = {'active', 'invited', 'eliminated'};
    final updated = blocked.contains(status)
        ? cached.where((result) => result.id != userId).toList(growable: false)
        : cached
              .map(
                (result) => result.id == userId
                    ? UserSearchResult(
                        id: result.id,
                        displayName: result.displayName,
                        email: result.email,
                        username: result.username,
                        membershipStatus: status,
                      )
                    : result,
              )
              .toList(growable: false);
    setState(() {
      _searchCache[query] = updated;
      if (_currentNormalizedQuery == query) {
        _searchResults = updated;
      }
    });
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
    if (user.membershipStatus == 'active' ||
        user.membershipStatus == 'invited') {
      return;
    }
    setState(() {
      _isInviting = true;
      _invitingUserId = user.id;
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
        _updateSearchStatusForUser(user.id, 'invited');
      }
    } catch (_) {
      // Ignore failures and let owner retry.
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
          _invitingUserId = null;
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
              _buildSearchCard(theme),
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

  Widget _buildSearchCard(ThemeData theme) {
    final normalized = _currentNormalizedQuery;
    final hasQuery = normalized.length >= 2;
    final latestMatches = _latestDeliveredQuery == normalized;
    final cached = _searchCache[normalized];
    final results = !hasQuery
        ? const <UserSearchResult>[]
        : (latestMatches
              ? _searchResults
              : (cached ?? const <UserSearchResult>[]));
    final showSpinner =
        _searchBusy && hasQuery && (!latestMatches || results.isEmpty);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite members',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                _runSearch(value);
              },
              decoration: InputDecoration(
                hintText: 'Search members',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            _buildSearchResultsArea(theme, hasQuery, results, showSpinner),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsArea(
    ThemeData theme,
    bool hasQuery,
    List<UserSearchResult> results,
    bool showSpinner,
  ) {
    if (!hasQuery) {
      return const SizedBox.shrink();
    }
    if (showSpinner && results.isEmpty) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (results.isEmpty) {
      return _buildSearchMessage(
        theme,
        Icons.search_off_outlined,
        'No matching users yet.',
      );
    }

    final resultsList = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (context, _) => const Divider(height: 18),
        itemBuilder: (context, index) =>
            _buildSearchResultTile(theme, results[index]),
      ),
    );
    if (!showSpinner) {
      return resultsList;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        const SizedBox(height: 12),
        resultsList,
      ],
    );
  }

  Widget _buildSearchMessage(ThemeData theme, IconData icon, String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(ThemeData theme, UserSearchResult result) {
    final status = result.membershipStatus;
    final isMember = status == 'active';
    final isInvited = status == 'invited';
    Widget trailing;
    if (isMember) {
      trailing = const Chip(label: Text('Member'));
    } else if (isInvited) {
      trailing = const Chip(label: Text('Invited'));
    } else if (_isInviting && _invitingUserId == result.id) {
      trailing = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      trailing = ElevatedButton(
        onPressed: _isInviting ? null : () => _inviteUser(result),
        child: const Text('Invite'),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.person_outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.displayName.isNotEmpty
                    ? result.displayName
                    : result.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (result.email.isNotEmpty || result.username.isNotEmpty)
                _buildSearchSubtitle(result),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
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
