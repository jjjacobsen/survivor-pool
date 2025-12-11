import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/layout/adaptive_page.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
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
                      'Privacy Policy',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This app does not collect, store, use, process, or share any personal data from users. We do not use analytics, tracking tools, third-party SDKs, or advertising technologies. No information is transmitted off the device.',
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
