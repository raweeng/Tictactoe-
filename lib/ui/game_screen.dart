import 'dart:async';
import 'package:flutter/material.dart';
import '../logic/tictactoe.dart';
import '../services/stats_store.dart';
import '../main.dart';

// Main game screen with board, stats, and controls
// Uses GameState from tictactoe.dart and StatsStore for persistent stats
// Handles user input, AI moves, and displays results
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

// State for GameScreen
class _GameScreenState extends State<GameScreen> {
  late GameState s;
  final statsStore = StatsStore();
  Stats stats = Stats();
  bool inputLocked = false;

  @override
  void initState() {
    super.initState();
    s = GameState();
    _loadStats();
  }

// Load stats from persistent storage
  Future<void> _loadStats() async {
    stats = await statsStore.load();
    if (mounted) setState(() {});
  }

  void _startNew(Difficulty d) {
    setState(() {
      s = GameState(difficulty: d, aiPlayer: 'O'); // Human is X
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    _startNew((arg as Difficulty?) ?? Difficulty.easy);
  }

// Current status string for bottom center
  String _status() {
    if (s.gameOver) {
      if (s.winner == null) return 'Draw';
      return '${s.winner} wins!';
    }
    return "${s.current}'s turn • ${s.difficulty.name}";
  }

// If it's the AI's turn, make its move after a short delay
  Future<void> _maybeAI() async {
    if (s.gameOver || s.current != s.aiPlayer) return;
    inputLocked = true;
    await Future.delayed(const Duration(milliseconds: 250));
    final move = switch (s.difficulty) {
      Difficulty.easy => aiMoveEasy(s.board),
      Difficulty.hard => aiMoveHard(s.board, s.aiPlayer),
      Difficulty.medium => aiMoveMedium(s.board, s.aiPlayer, s.aiTurnCount),
    };
    setState(() {
      applyMove(s, move);
      if (s.difficulty == Difficulty.medium) s.aiTurnCount++;
      inputLocked = false;
      _maybeFinalizeStats();
    });
  }

  void _tapCell(int i) {
    if (inputLocked ||
        s.gameOver ||
        !isValidMove(s.board, i) ||
        s.current == s.aiPlayer) {
      return;
    }
    setState(() {
      applyMove(s, i);
      _maybeFinalizeStats();
    });
    _maybeAI();
  }

  // Show a centered dialog with the result message
  // Has "Play again" and "Close" buttons
  Future<void> _showCenteredResult(String msg) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // No const-use: msg varies
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      _resetMatch(); // new round
                    },
                    child: const Text('Play again'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _maybeFinalizeStats() async {
    if (!s.gameOver) return;

    if (s.winner == null) {
      stats.draws++;
    } else if (s.winner == 'X') {
      stats.wins++;
    } else {
      stats.losses++;
    }
    await statsStore.save(stats);
    setState(() {});

    if (mounted) {
      final msg = s.winner == null ? 'Draw' : '${s.winner} wins!';
      _showCenteredResult(msg); // centered popup
    }
  }

  // Reset just the board for a new match; keep stats
  void _resetMatch() {
    setState(() {
      s = GameState(difficulty: s.difficulty, aiPlayer: s.aiPlayer);
    });
  }

  // Reset everything: board and stats
  Future<void> _resetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all'),
        content: const Text(
            'This will reset the current board and set Wins/Losses/Draws to 0.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;

    final cleared = await statsStore.clear();
    setState(() {
      stats = cleared;
      s = GameState(difficulty: s.difficulty, aiPlayer: s.aiPlayer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Stats header (highlighted) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatBox(label: 'Wins', value: stats.wins.toString()),
                  _StatBox(label: 'Losses', value: stats.losses.toString()),
                  _StatBox(label: 'Draws', value: stats.draws.toString()),
                ],
              ),
              const SizedBox(height: 16),

              // Player / AI labels
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Role(label: 'Player', symbol: 'X', icon: Icons.person),
                  _Role(label: 'AI', symbol: 'O', icon: Icons.public),
                ],
              ),
              const SizedBox(height: 12),

              // --- FLEX grid: never overflows; always square ---
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: 9,
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => _tapCell(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.board,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                s.board[i],
                                style: const TextStyle(
                                  fontSize: 120,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                  child: Text(_status(),
                      style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 12),

              // --- Controls ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Back')),
                  FilledButton.tonal(
                    onPressed: s.history.isEmpty
                        ? null
                        : () => setState(() => undo(s, vsAI: true)),
                    child: const Text('Undo'),
                  ),
                  FilledButton(
                      onPressed: _resetAll, child: const Text('Reset')),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/', (_) => false),
                    child: const Text('Exit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Center(child: Text('@powered by RaweenG')),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white70, width: 1),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Role extends StatelessWidget {
  const _Role({required this.label, required this.symbol, required this.icon});
  final String label;
  final String symbol;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              symbol,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
