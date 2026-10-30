import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which group of the Tasks tab each state the backend sends lands in.
void main() {
  TaskGroup g(String type, String state) =>
      LearnerTask.fromJson({'type': type, 'state': state}).group;

  test('quizzes', () {
    expect(g('quiz', 'not_started'), TaskGroup.todo);
    expect(g('quiz', 'in_progress'), TaskGroup.todo);
    expect(g('quiz', 'expired'), TaskGroup.todo);
    expect(g('quiz', 'submitted'), TaskGroup.awaiting);
    expect(g('quiz', 'passed'), TaskGroup.graded);
    expect(g('quiz', 'failed'), TaskGroup.graded);
  });

  test('assignments', () {
    expect(g('assignment', 'not_started'), TaskGroup.todo);
    expect(g('assignment', 'overdue'), TaskGroup.todo);
    expect(g('assignment', 'draft'), TaskGroup.todo);
    // An upload that did not finish still has to be submitted.
    expect(g('assignment', 'failed'), TaskGroup.todo);
    expect(g('assignment', 'submitting'), TaskGroup.awaiting);
    expect(g('assignment', 'submitted'), TaskGroup.awaiting);
    expect(g('assignment', 'graded'), TaskGroup.graded);
  });
}
