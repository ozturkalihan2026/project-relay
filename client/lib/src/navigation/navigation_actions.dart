import 'package:flutter/material.dart';

void returnToMainMenu(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

void returnToPreviousMenu(BuildContext context) {
  Navigator.of(context).maybePop();
}
