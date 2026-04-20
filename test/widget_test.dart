import 'package:flutter_test/flutter_test.dart';

import 'package:sakunaflow/main.dart' as entrypoint;

void main() {
  testWidgets('main.dart exports the SakunaFlow entry point', (tester) async {
    expect(entrypoint.main, isA<Function>());
  });
}
