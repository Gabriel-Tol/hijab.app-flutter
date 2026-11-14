import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/core/app_theme.dart';
import 'package:rnz_store/widgets/product_card.dart';
import 'package:rnz_store/widgets/quantity_stepper.dart';

import '../fixtures.dart';

void main() {
  testWidgets('ProductCard shows price and out-of-stock badge', (tester) async {
    final product = sampleProduct(sageStock: 0, mStock: 0);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: ProductCard(product: product, onTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Rp 85.000'), findsOneWidget);
    expect(find.text('Stok Habis'), findsOneWidget);
    expect(find.text(product.name), findsOneWidget);
  });

  testWidgets('QuantityStepper respects min and max', (tester) async {
    var value = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return QuantityStepper(
                value: value,
                min: 1,
                max: 3,
                onChanged: (next) => setState(() => value = next),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 3);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 3);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
    }
    expect(value, 1);
    expect(find.text('1'), findsOneWidget);
  });
}
