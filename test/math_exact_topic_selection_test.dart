import 'package:flutter_test/flutter_test.dart';

import 'support/math_exact_topic_selection_contract.dart';

void main() {
  test('all allowed cumulative math topics preserve exact selection', () {
    final report = verifyMathExactTopicSelection();
    final failures = report['failures']! as List;
    expect(
      failures,
      isEmpty,
      reason: failures.take(8).join('\n'),
    );
  });
}
