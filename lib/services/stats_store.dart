import 'package:shared_preferences/shared_preferences.dart';

class Stats {
  int wins, losses, draws;
  Stats({this.wins = 0, this.losses = 0, this.draws = 0});
}

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

  Future<void> save(Stats s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kWins, s.wins);
    await p.setInt(_kLosses, s.losses);
    await p.setInt(_kDraws, s.draws);
  }

  /// Reset all tallies to zero and persist.
  Future<Stats> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kWins, 0);
    await p.setInt(_kLosses, 0);
    await p.setInt(_kDraws, 0);
    return Stats(); // 0/0/0
  }
}
