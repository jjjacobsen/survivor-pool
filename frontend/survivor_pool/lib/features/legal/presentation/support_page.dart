import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/layout/adaptive_page.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AdaptivePage(
            maxWidth: 720,
            compactPadding: const EdgeInsets.all(24),
            widePadding: const EdgeInsets.symmetric(
              horizontal: 64,
              vertical: 48,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Survivor Pool Support',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you need help with Survivor Pool, email jjacobsen115@gmail.com.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
