import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iaprende/presentation/widgets/upper_text.dart';

void main() {
  testWidgets('UPPER TEXT MUESTRA CONTENIDO EN MAYÚSCULAS', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UpperText('hola mundo'))),
    );

    expect(find.text('HOLA MUNDO'), findsOneWidget);
  });
}
