import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/layout/adaptive_page.dart';

class MarketingPage extends StatelessWidget {
  const MarketingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survivor Pool'),
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AdaptivePage(
            maxWidth: 820,
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
                      'Outplay Your Friends',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Survivor Pool is a weekly no-repeat pick’em for the TV show Survivor. Create or join pools, lock in a contestant you believe survives the episode, and watch standings shift as votes are revealed.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Why download?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Bullet(
                      text:
                          'Set up private pools in minutes and invite anyone.',
                    ),
                    _Bullet(
                      text:
                          'Track the live roster with tribe info and eliminations.',
                    ),
                    _Bullet(
                      text:
                          'Submit and edit picks before each deadline with no repeats.',
                    ),
                    _Bullet(
                      text:
                          'Follow leaderboards that update the moment someone is voted out.',
                    ),
                    _Bullet(
                      text:
                          'Review your pick history to see how far each choice made it.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Built for fans who want a clean, fast way to run Survivor pools on any device.',
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

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 18, color: Color(0xFF1B365D)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
