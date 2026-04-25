import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calc_result.dart';

class CalcHistoryNotifier extends StateNotifier<List<CalculationResult>> {
  CalcHistoryNotifier() : super([]);

  void add(CalculationResult result) {
    // Keep newest first, max 50 entries
    state = [result, ...state.take(49)];
  }

  void clear() => state = [];
}

final calcHistoryProvider =
    StateNotifierProvider<CalcHistoryNotifier, List<CalculationResult>>(
  (ref) => CalcHistoryNotifier(),
);
