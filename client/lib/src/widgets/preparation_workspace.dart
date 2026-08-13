import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Çevrimiçi ve kariyer hazırlığının ortak sahne iskeleti.
///
/// Büyük ekranda devre kartını merkezde, bağlamsal bilgiyi sağda ve modül
/// rafını sabit biçimde altta tutar. Dar ekranda içerik kayar, raf erişilebilir
/// kalmaya devam eder.
class PreparationWorkspace extends StatelessWidget {
  const PreparationWorkspace({
    required this.boardStage,
    required this.sidePanel,
    required this.moduleShelf,
    super.key,
  });

  final Widget boardStage;
  final Widget sidePanel;
  final Widget moduleShelf;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        if (wide) {
          final sideWidth = math.min(370.0, constraints.maxWidth * 0.30);
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: boardStage),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: sideWidth,
                        child: SingleChildScrollView(
                          key: const ValueKey('preparation-side-scroll'),
                          child: sidePanel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                moduleShelf,
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('preparation-main-scroll'),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: math.min(560, constraints.maxWidth + 76),
                      child: boardStage,
                    ),
                    const SizedBox(height: 12),
                    sidePanel,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: moduleShelf,
            ),
          ],
        );
      },
    );
  }
}
