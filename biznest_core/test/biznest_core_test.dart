import 'package:flutter_test/flutter_test.dart';

import 'package:biznest_core/biznest_core.dart';

void main() {
  test('core exports are accessible', () {
    expect(AppColors.primary600.value, isNonZero);
  });
}
