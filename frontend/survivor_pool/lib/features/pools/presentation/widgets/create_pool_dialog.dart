import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/models/season.dart';
import 'package:survivor_pool/core/network/auth_client.dart';

class CreatePoolDialog extends StatefulWidget {
  final List<SeasonOption> seasons;
  final String ownerId;
  final String Function(String body) parseErrorMessage;

  const CreatePoolDialog({
    super.key,
    required this.seasons,
    required this.ownerId,
    required this.parseErrorMessage,
  });

  @override
  State<CreatePoolDialog> createState() => _CreatePoolDialogState();
}

class _CreatePoolDialogState extends State<CreatePoolDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _poolNameController;
  String? _selectedSeasonId;
  int _startWeek = 1;
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
      final response = await AuthHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/pools'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _poolNameController.text.trim(),
          'season_id': _selectedSeasonId,
          'owner_id': widget.ownerId,
          'start_week': _startWeek,
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
      } else {
        widget.parseErrorMessage(response.body);
      }
    } catch (_) {
      // Ignored to keep UI quiet without snackbars.
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
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _startWeek,
              decoration: const InputDecoration(labelText: 'Start week'),
              items: List.generate(6, (index) => index + 1)
                  .map(
                    (week) => DropdownMenuItem<int>(
                      value: week,
                      child: Text('Week $week'),
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
                        _startWeek = value;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Please select a start week';
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
