import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../logic/tictactoe.dart';
import '../services/stats_store.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const _GradientTitle('Select difficulty level'),
      ),
      body: const _DifficultyBody(),
    );
  }
}

class _DifficultyBody extends StatefulWidget {
  const _DifficultyBody();

  @override
  State<_DifficultyBody> createState() => _DifficultyBodyState();
}

class _DifficultyBodyState extends State<_DifficultyBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgAnim =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat();

  final _store = StatsStore();
  Stats _stats = Stats(); // wins/losses/draws

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _store.load();
    if (mounted) setState(() => _stats = s);
  }

  /// Navigate to Game, then refresh stats when returning
  Future<void> _startGame(BuildContext context, Difficulty d) async {
    await Navigator.pushNamed(context, '/game', arguments: d);
    final s = await _store.load();
    if (mounted) setState(() => _stats = s);
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        final maxW = constraints.maxWidth > 640 ? 640.0 : constraints.maxWidth;

        return Stack(
          children: [
            // ✨ Subtle animated XO background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgAnim,
                builder: (_, __) => CustomPaint(
                  painter: _XOPainter(progress: _bgAnim.value),
                ),
              ),
            ),
            // Gentle blur so content pops
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const SizedBox.expand(),
              ),
            ),

            // Foreground content
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: maxW),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // ---- Stats row (top of screen) ----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatBox(label: 'Wins', value: _stats.wins),
                          _StatBox(label: 'Losses', value: _stats.losses),
                          _StatBox(label: 'Draws', value: _stats.draws),
                        ],
                      ),

                      const Spacer(),

                      // Big difficulty buttons -> use _startGame (await + refresh)
                      _BigChoiceButton(
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        label: 'Easy',
                        subtitle: 'Random moves each turn',
                        onPressed: () => _startGame(context, Difficulty.easy),
                      ),
                      _BigChoiceButton(
                        icon: Icons.speed_rounded,
                        label: 'Medium',
                        subtitle: 'Alternates random & strategy',
                        onPressed: () => _startGame(context, Difficulty.medium),
                      ),
                      _BigChoiceButton(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Hard',
                        subtitle: 'Strategy every single turn',
                        onPressed: () => _startGame(context, Difficulty.hard),
                      ),

                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('@powered by RaweenG'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Big pill button with subtle hover/press scale animation
class _BigChoiceButton extends StatefulWidget {
  const _BigChoiceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  State<_BigChoiceButton> createState() => _BigChoiceButtonState();
}

class _BigChoiceButtonState extends State<_BigChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 140));
  late final Animation<double> _scale =
      Tween(begin: 1.0, end: 0.98).animate(_ctl);

  void _down(_) => _ctl.forward();
  void _up(_) => _ctl.reverse();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctl.reverse(),
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: () => _ctl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: 420, minWidth: 280, minHeight: 76),
              child: DecoratedBox(
                decoration: const ShapeDecoration(
                  color: Colors.black87,
                  shape: StadiumBorder(),
                  shadows: [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.onPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 28),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.label,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(widget.subtitle,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient headline used in the AppBar (const-friendly)
class _GradientTitle extends StatelessWidget {
  const _GradientTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Colors.white, Color(0xFFE3E3E3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

/// Compact stat card used at the top of the screen
class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final int value;

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
            '$value',
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

/// Painter for the subtle animated XO background (no assets)
class _XOPainter extends CustomPainter {
  _XOPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const cols = 6;
    const rows = 10;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // gentle drift
    final dx = sin(progress * 2 * pi) * 4;
    final dy = cos(progress * 2 * pi) * 4;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * cellW + cellW / 2 + dx;
        final cy = r * cellH + cellH / 2 + dy;
        final radius = min(cellW, cellH) * 0.22;

        if ((r + c).isEven) {
          // O
          canvas.drawCircle(Offset(cx, cy), radius, p);
        } else {
          // X
          final len = radius * 1.3;
          canvas.drawLine(
            Offset(cx - len, cy - len),
            Offset(cx + len, cy + len),
            p,
          );
          canvas.drawLine(
            Offset(cx + len, cy - len),
            Offset(cx - len, cy + len),
            p,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _XOPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
