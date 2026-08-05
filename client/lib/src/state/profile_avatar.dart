import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileAvatarProvider =
    NotifierProvider<ProfileAvatarController, IconData>(
  ProfileAvatarController.new,
);

class ProfileAvatarController extends Notifier<IconData> {
  @override
  IconData build() => Icons.account_circle;

  void select(IconData icon) {
    if (selectableProfileIcons.contains(icon)) {
      state = icon;
    }
  }
}

const selectableProfileIcons = <IconData>[
  Icons.account_circle,
  Icons.bolt,
  Icons.memory,
  Icons.shield_outlined,
  Icons.auto_awesome,
  Icons.radar,
  Icons.hub_outlined,
  Icons.smart_toy_outlined,
];
