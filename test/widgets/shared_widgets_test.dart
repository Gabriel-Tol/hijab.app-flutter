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

  testWidgets(
    'ProductCard does not overflow on mobile grids with 2-line title across screen sizes',
    (tester) async {
      final product = sampleProduct().copyWith(
        name: 'Pashmina Ring Scarf Mocca Silk Premium',
      );

      for (final width in [320.0, 360.0, 392.0, 412.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: GridView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.50,
                ),
                children: [
                  ProductCard(product: product, onTap: () {}),
                ],
              ),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed on screen width $width',
        );
        expect(find.text(product.name), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

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
