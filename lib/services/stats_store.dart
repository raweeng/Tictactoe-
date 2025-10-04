import 'package:shared_preferences/shared_preferences.dart';

// Simple stats model and persistence using SharedPreferences
// Tracks number of wins, losses, and draws
class Stats {
  int wins, losses, draws;
  Stats({this.wins = 0, this.losses = 0, this.draws = 0});
}

// Service to load/save stats from persistent storage
// Uses SharedPreferences for simplicity
class StatsStore {
  static const _kWins = 'wins', _kLosses = 'losses', _kDraws = 'draws';

  Future<Stats> load() async {
    final p = await SharedPreferences.getInstance();
    return Stats(
      wins: p.getInt(_kWins) ?? 0,
      losses: p.getInt(_kLosses) ?? 0,
      draws: p.getInt(_kDraws) ?? 0,
    );
  }

// Save the given stats to persistent storage
// Overwrites any existing values.
  Future<void> save(Stats s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kWins, s.wins);
    await p.setInt(_kLosses, s.losses);
    await p.setInt(_kDraws, s.draws);
  }

// Clear all stats (set to 0) in persistent storage
  Future<Stats> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kWins, 0);
    await p.setInt(_kLosses, 0);
    await p.setInt(_kDraws, 0);
    return Stats(); // return cleared stats
  }
}
