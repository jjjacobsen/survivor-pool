import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/network/auth_client.dart';

class PoolUpdatesPage extends StatefulWidget {
  final PoolOption pool;
  final String userId;
  final bool isOwner;

  const PoolUpdatesPage({
    super.key,
    required this.pool,
    required this.userId,
    required this.isOwner,
  });

  @override
  State<PoolUpdatesPage> createState() => _PoolUpdatesPageState();
}

class _PoolUpdatesPageState extends State<PoolUpdatesPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String _message = '';
  DateTime? _updatedAt;
  String? _error;

  Uri _apiUri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AuthHttpClient.get(
        _apiUri(
          '/pools/${widget.pool.id}/announcement?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message'] as String? ?? '';
          final updatedAtRaw = decoded['updated_at'] as String?;
          setState(() {
            _message = message;
            _messageController.text = message;
            _updatedAt = updatedAtRaw == null
                ? null
                : DateTime.tryParse(updatedAtRaw);
          });
          return;
        }
      }

      setState(() {
        _error = _parseError(response.body, 'Unable to load message board.');
      });
    } catch (error) {
      setState(() {
        _error = 'Network error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveMessage() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final response = await AuthHttpClient.patch(
        _apiUri('/pools/${widget.pool.id}/announcement'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_id': widget.userId,
          'message': _messageController.text,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message'] as String? ?? '';
          final updatedAtRaw = decoded['updated_at'] as String?;
          setState(() {
            _message = message;
            _messageController.text = message;
            _updatedAt = updatedAtRaw == null
                ? null
                : DateTime.tryParse(updatedAtRaw);
            _isEditing = false;
          });
          return;
        }
      }

      setState(() {
        _error = _parseError(response.body, 'Unable to save message.');
      });
    } catch (error) {
      setState(() {
        _error = 'Network error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _parseError(String body, String fallback) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Ignore parsing failures.
    }
    return fallback;
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final year = local.year;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollView = SingleChildScrollView(
      physics: widget.isOwner
          ? const ClampingScrollPhysics()
          : const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
      child: AdaptivePage(
        maxWidth: 760,
        compactPadding: const EdgeInsets.all(24),
        widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _isLoading
                ? const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message board',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_updatedAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Updated ${_formatTimestamp(_updatedAt!)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_isEditing)
                        TextField(
                          controller: _messageController,
                          maxLines: 12,
                          minLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Message',
                            alignLabelWithHint: true,
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SelectableText(
                            _message.trim().isEmpty
                                ? 'No message posted yet.'
                                : _message,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _message.trim().isEmpty
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      if (widget.isOwner) ...[
                        const SizedBox(height: 20),
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = false;
                                            _messageController.text = _message;
                                          });
                                        },
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _saveMessage,
                                  child: Text(
                                    _isSaving ? 'Saving...' : 'Save message',
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                  _messageController.text = _message;
                                });
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit message'),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Message board — ${widget.pool.name}'),
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: SafeArea(
        child: widget.isOwner
            ? scrollView
            : RefreshIndicator(onRefresh: _loadMessage, child: scrollView),
      ),
    );
  }
}
