// lib/logic/tictactoe.dart
import 'dart:math';

enum Difficulty { easy, medium, hard }

class GameState {
  GameState({
    List<String>? board,
    this.current = 'X',
    List<int>? history,
    this.gameOver = false,
    this.winner,
    this.aiPlayer = 'O',
    this.difficulty = Difficulty.easy,
    this.aiTurnCount = 0,
  })  : board = board ?? List.filled(9, ''),
        history = history ?? <int>[];

  final List<String> board; // '', 'X', 'O'
  String current; // 'X' or 'O'
  final List<int> history; // indices played
  bool gameOver;
  String? winner; // 'X'/'O'/null
  String aiPlayer; // who AI controls
  Difficulty difficulty;
  int aiTurnCount; // for Medium alternating

  GameState copy() => GameState(
        board: List.of(board),
        current: current,
        history: List.of(history),
        gameOver: gameOver,
        winner: winner,
        aiPlayer: aiPlayer,
        difficulty: difficulty,
        aiTurnCount: aiTurnCount,
      );
}

// ---------- Core rules ----------
bool isValidMove(List<String> b, int i) => i >= 0 && i < 9 && b[i].isEmpty;

String? checkWinner(List<String> b) {
  const lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];
  for (final L in lines) {
    final a = b[L[0]], c = b[L[1]], d = b[L[2]];
    if (a.isNotEmpty && a == c && c == d) return a;
  }
  return null;
}

bool isDraw(List<String> b) =>
    checkWinner(b) == null && b.every((v) => v.isNotEmpty);

List<int> emptyCells(List<String> b) => [
      for (var i = 0; i < 9; i++)
        if (b[i].isEmpty) i
    ];

void applyMove(GameState s, int i) {
  if (s.gameOver || !isValidMove(s.board, i)) return;
  s.board[i] = s.current;
  s.history.add(i);
  final w = checkWinner(s.board);
  if (w != null) {
    s.gameOver = true;
    s.winner = w;
    return;
  }
  if (isDraw(s.board)) {
    s.gameOver = true;
    s.winner = null;
    return;
  }
  s.current = (s.current == 'X') ? 'O' : 'X';
}

// Undo: in Human vs AI, undo a FULL turn (AI + human)
void undo(GameState s, {bool vsAI = true}) {
  if (s.history.isEmpty ||
      s.gameOver && (s.winner != null || isDraw(s.board))) {
    // Allow undo even after game over
  }
  int pops = 1;
  if (vsAI && s.history.length >= 2) pops = 2;
  for (var k = 0; k < pops && s.history.isNotEmpty; k++) {
    final idx = s.history.removeLast();
    s.board[idx] = '';
    s.current = (s.current == 'X') ? 'O' : 'X';
  }
  s.gameOver = false;
  s.winner = null;
}

// ---------- AI ----------
final _rng = Random();

// Easy: random legal move
int aiMoveEasy(List<String> b) {
  final cells = emptyCells(b);
  return cells[_rng.nextInt(cells.length)];
}

// Try a winning/blocking move helper
int? _findLineFinish(List<String> b, String player) {
  const lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];
  for (final L in lines) {
    final vals = [b[L[0]], b[L[1]], b[L[2]]];
    final empties = [0, 1, 2].where((i) => vals[i].isEmpty).toList();
    if (empties.length == 1) {
      final i = empties.first;
      final others = [0, 1, 2]..remove(i);
      if (vals[others[0]] == player && vals[others[1]] == player) {
        return L[i];
      }
    }
  }
  return null;
}

bool _wouldCreateTwoThreats(List<String> b, String player, int move) {
  final copy = List.of(b);
  copy[move] = player;
  // Count immediate winning moves on next turn
  int count = 0;
  for (final m in emptyCells(copy)) {
    final tmp = List.of(copy);
    tmp[m] = player;
    if (checkWinner(tmp) == player) count++;
    if (count >= 2) return true;
  }
  return false;
}

// Hard: finish -> block -> fork -> center -> opposite corner -> corner -> side
int aiMoveHard(List<String> b, String ai) {
  final human = (ai == 'X') ? 'O' : 'X';

  // 1) Win if possible
  final winPos = _findLineFinish(b, ai);
  if (winPos != null) return winPos;

  // 2) Block opponent
  final blockPos = _findLineFinish(b, human);
  if (blockPos != null) return blockPos;

  // 3) Create fork (two threats)
  for (final m in emptyCells(b)) {
    if (_wouldCreateTwoThreats(b, ai, m)) return m;
  }

  // 4) Block opponent fork
  for (final m in emptyCells(b)) {
    if (_wouldCreateTwoThreats(b, human, m)) return m;
  }

  // 5) Center
  if (b[4].isEmpty) return 4;

  // 6) Opposite corner
  const corners = [0, 2, 6, 8];
  const opposite = {0: 8, 2: 6, 6: 2, 8: 0};
  for (final c in corners) {
    if (b[c] == human && b[opposite[c]!] == '') return opposite[c]!;
  }

  // 7) Any corner
  final freeCorners = corners.where((c) => b[c].isEmpty).toList();
  if (freeCorners.isNotEmpty) return freeCorners.first;

  // 8) Any side
  const sides = [1, 3, 5, 7];
  final freeSides = sides.where((s) => b[s].isEmpty).toList();
  if (freeSides.isNotEmpty) return freeSides.first;

  // Fallback
  return aiMoveEasy(b);
}

// Medium: alternate random vs hard
int aiMoveMedium(List<String> b, String ai, int aiTurnCount) {
  if (aiTurnCount.isEven) {
    return aiMoveEasy(b);
  } else {
    return aiMoveHard(b, ai);
  }
}
