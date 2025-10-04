// lib/logic/tictactoe.dart
import 'dart:math';

// Difficulty levels used by the AI player
enum Difficulty { easy, medium, hard }

// Game state representation
// - board: 9 cells, each '', 'X', or 'O'
// - current: whose turn it is ('X' or 'O')
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

// Board cells: '', 'X', 'O
  final List<String> board;

// Current player: 'X' or 'O'
  String current;

// Move history (for undo)
  final List<int> history;
  bool gameOver;

// Winner: 'X', 'O', or null for draw/no winner yet
  String? winner;
  String aiPlayer; // who is the AI ('X' or 'O')
  Difficulty difficulty;
  int aiTurnCount; // for Medium alternating strategy

// Create a copy of the game state
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

// ---------------Core rules---------------
// Check if move is valid: index in 0..8 and cell empty
bool isValidMove(List<String> b, int i) => i >= 0 && i < 9 && b[i].isEmpty;

// Check for a winner: return 'X', 'O', or null
// Returns the winner ('X' or 'O') or null if no winner yet
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

// Check for draw: board full and no winner
bool isDraw(List<String> b) =>
    checkWinner(b) == null && b.every((v) => v.isNotEmpty);

// Get list of empty cell indices
List<int> emptyCells(List<String> b) => [
      for (var i = 0; i < 9; i++)
        if (b[i].isEmpty) i
    ];

// Apply a move: update board, history, current player, gameOver, winner
// Does nothing if move invalid or game over
// Assumes move is valid
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

// Undo last move(s): reverts board, history, current player
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
// Returns a random empty cell index
int aiMoveEasy(List<String> b) {
  final cells = emptyCells(b);
  return cells[_rng.nextInt(cells.length)];
}

// Returns index to win/block or null
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

// Check if placing 'player' at 'move' creates two threats
bool _wouldCreateTwoThreats(List<String> b, String player, int move) {
  final copy = List.of(b);
  copy[move] = player;

// Count how many winning moves this creates
  int count = 0;
  for (final m in emptyCells(copy)) {
    final tmp = List.of(copy);
    tmp[m] = player;
    if (checkWinner(tmp) == player) count++;
    if (count >= 2) return true;
  }
  return false;
}

// hard: implement full strategy
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
// On even AI turns, play easy; on odd turns, play hard
int aiMoveMedium(List<String> b, String ai, int aiTurnCount) {
  if (aiTurnCount.isEven) {
    return aiMoveEasy(b);
  } else {
    return aiMoveHard(b, ai);
  }
}
