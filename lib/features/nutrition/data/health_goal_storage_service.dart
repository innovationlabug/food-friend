import 'package:shared_preferences/shared_preferences.dart';
import '../domain/health_goal.dart';

/// Local persistence service for the user's selected [HealthGoal]s.
/// Uses [SharedPreferences] so goals persist across Web and Android without user accounts.
class HealthGoalStorageService {
  HealthGoalStorageService({this._preferences});

  SharedPreferences? _preferences;

  static const String storageKey = 'food_friend_health_goals';

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Loads the currently selected health goals in canonical [HealthGoal.values] order.
  Future<Set<HealthGoal>> getSelectedGoals() async {
    final prefs = await _prefs;
    final storedKeys = prefs.getStringList(storageKey);
    if (storedKeys == null || storedKeys.isEmpty) {
      return <HealthGoal>{};
    }

    final parsed = <HealthGoal>{};
    for (final rawKey in storedKeys) {
      final goal = HealthGoal.fromStorageKey(rawKey);
      if (goal != null) {
        parsed.add(goal);
      }
    }

    return _orderedSet(parsed);
  }

  /// Persists the supplied [goals] locally and returns the ordered saved set.
  Future<Set<HealthGoal>> saveSelectedGoals(Set<HealthGoal> goals) async {
    final ordered = _orderedSet(goals);
    final prefs = await _prefs;
    await prefs.setStringList(
      storageKey,
      ordered.map((g) => g.storageKey).toList(),
    );
    return ordered;
  }

  /// Toggles [goal] on or off, persists the updated set, and returns it.
  Future<Set<HealthGoal>> toggleGoal(HealthGoal goal) async {
    final current = await getSelectedGoals();
    final updated = Set<HealthGoal>.from(current);
    if (!updated.add(goal)) {
      updated.remove(goal);
    }
    return saveSelectedGoals(updated);
  }

  /// Removes all persisted health goals.
  Future<void> clearGoals() async {
    final prefs = await _prefs;
    await prefs.remove(storageKey);
  }

  Set<HealthGoal> _orderedSet(Set<HealthGoal> goals) {
    return <HealthGoal>{
      for (final goal in HealthGoal.values)
        if (goals.contains(goal)) goal,
    };
  }
}
