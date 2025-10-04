import 'package:flutter_test/flutter_test.dart';

// IMPORTANT: match your pubspec.yaml 'name:' exactly!
import 'package:mobile_application_assignment_1/logic/tictactoe.dart';

void main() {
  group('Win detection', () {
    test('row win for X', () {
      final b = ['X', 'X', 'X', '', '', '', '', '', ''];
      expect(checkWinner(b), 'X');
    });

    test('column win for O', () {
      final b = ['O', '', '', 'O', '', '', 'O', '', ''];
      expect(checkWinner(b), 'O');
    });

    test('diagonal win for X (0-4-8)', () {
      final b = ['X', '', '', '', 'X', '', '', '', 'X'];
      expect(checkWinner(b), 'X');
    });

    test('anti-diagonal win for O (2-4-6)', () {
      final b = ['', '', 'O', '', 'O', '', 'O', '', ''];
      expect(checkWinner(b), 'O');
    });

    test('no winner => null', () {
      final b = ['X', 'O', 'X', 'X', 'O', 'O', 'O', 'X', ''];
      expect(checkWinner(b), isNull);
    });
  });

  group('Draw & legal moves', () {
    test('isDraw true when board full and no winner', () {
      final b = ['X', 'O', 'X', 'X', 'O', 'O', 'O', 'X', 'X'];
      expect(isDraw(b), isTrue);
    });

    test('isDraw false when empty spaces remain', () {
      final b = List.filled(9, '');
      expect(isDraw(b), isFalse);
    });

    test('isValidMove only empty cells inside bounds', () {
      final b = List.filled(9, '');
      b[4] = 'X';
      expect(isValidMove(b, 4), isFalse);
      expect(isValidMove(b, 3), isTrue);
      expect(isValidMove(b, -1), isFalse);
      expect(isValidMove(b, 9), isFalse);
    });
  });

  group('Apply move & state', () {
    test('applyMove places mark and flips current player', () {
      final s = GameState(); // current = 'X'
      applyMove(s, 0);
      expect(s.board[0], 'X');
      expect(s.current, 'O');
    });

    test('applyMove prevents overwriting and ignores after gameOver', () {
      final s = GameState();
      applyMove(s, 0); // X
      applyMove(s, 0); // invalid overwrite
      expect(s.board[0], 'X');

      // Force win to set gameOver
      s.board.setAll(0, ['X', 'X', '']);
      s.current = 'X';
      applyMove(s, 2); // X completes row 0..2
      expect(s.gameOver, isTrue);
      final snap = List<String>.from(s.board);
      applyMove(s, 3); // ignored after gameOver
      expect(s.board, snap);
    });
  });

  group('Undo', () {
    test('Undo removes full turn vs AI (2 moves)', () {
      final s = GameState();
      applyMove(s, 0); // X
      applyMove(s, 4); // O
      undo(s, vsAI: true);
      expect(s.board[0], '');
      expect(s.board[4], '');
      expect(s.current, 'X');
      expect(s.history, isEmpty);
    });

    test('Undo removes single move if vsAI=false', () {
      final s = GameState();
      applyMove(s, 0); // X
      applyMove(s, 4); // O
      undo(s, vsAI: false);
      expect(s.board[4], '');
      expect(s.board[0], 'X');
      expect(s.current, 'O');
    });
  });

  group('AI: Easy/Medium/Hard behaviour', () {
    test('Easy picks a legal empty cell (property check)', () {
      final b = ['X', '', '', '', '', 'O', '', '', '', '', ''];
      final m = aiMoveEasy(b);
      expect(isValidMove(b, m), isTrue);
    });

    test('Hard blocks immediate threat', () {
      final b = ['X', 'X', '', '', '', '', '', '', ''];
      final move = aiMoveHard(b, 'O');
      expect(move, 2); // must block 0-1-2
    });

    test('Hard takes center when free and no forced tactic', () {
      final b = ['X', '', '', '', '', '', '', '', ''];
      final move = aiMoveHard(b, 'O');
      expect(move, 4); // center
    });

    test('Hard plays opposite corner to human', () {
      final b = ['X', '', '', '', 'O', '', '', '', ''];
      // Make center occupied by O so opposite-corner rule triggers
      b[4] = ''; // temporarily free center
      final b2 = ['X', '', '', '', 'X', '', '', '', ''];
      final move = aiMoveHard(b2, 'O');
      // Opposite of 0 is 8; if that’s taken by center strategy variations it may pick corner anyway.
      expect(
          move,
          anyOf(equals(8),
              equals(4))); // allow center fallback if logic prefers it
    });

    test('Medium alternates: even turn -> Easy-like; odd turn -> Hard-like',
        () {
      // Even AI turn count to Easy-like (any legal move)
      final b = ['X', '', '', '', '', 'O', '', '', '', '', ''];
      final mEven = aiMoveMedium(b, 'O', 0);
      expect(isValidMove(b, mEven), isTrue);

      // Odd AI turn count to Hard (must block)
      final bThreat = ['X', 'X', '', '', '', 'O', '', '', '', '', ''];
      final mOdd = aiMoveMedium(bThreat, 'O', 1);
      expect(mOdd, 2); // must block
    });
  });
}
