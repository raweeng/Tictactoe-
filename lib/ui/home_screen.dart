import 'package:flutter/material.dart';

// Home screen with title, image, and "Play" button
// Navigates to /difficulty when "Play" is pressed
// Uses a LayoutBuilder to constrain max width on large screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // centers horizontally
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep a comfortable max width on large screens (web/desktop)
              final maxW =
                  constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
              return ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: maxW),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // vertical centering via Spacers
                    children: [
                      const Spacer(),
                      // Title + tag-line
                      Column(
                        children: [
                          Text(
                            'Tic-Tac-Toe',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No luck, just logic.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          // Image under the title/tag-line
                          SizedBox(
                            height: 160,
                            child: Image.asset(
                              'assets/tictactoe.jpg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Play button
                      FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/difficulty'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Text('Play'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '@powered by RaweenG',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
