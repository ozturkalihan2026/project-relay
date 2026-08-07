import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';

class PlayerStatusBar extends ConsumerWidget {
  const PlayerStatusBar({
    this.compact = false,
    this.onTap,
    this.showClaimBadge = false,
    super.key,
  });

  final bool compact;
  final VoidCallback? onTap;
  final bool showClaimBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(guestSessionProvider);
    final progression = ref.watch(progressionProvider);
    final collection = ref.watch(collectionProvider);
    final profileFrame = collection.when(
      data: (snapshot) => ProfileFrameVisualTheme.fromId(
        snapshot.equippedProfileFrameId,
      ),
      loading: () => const ProfileFrameVisualTheme.circuitBasic(),
      error: (error, stackTrace) =>
          const ProfileFrameVisualTheme.circuitBasic(),
    );
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dense = compact && screenWidth < 720;
    final width = dense
        ? math.min(142.0, math.max(112.0, screenWidth * 0.33))
        : compact
            ? 214.0
            : math.min(282.0, math.max(208.0, screenWidth - 32.0));
    final height = compact ? 50.0 : 58.0;

    final hasClaimable = showClaimBadge &&
        (progression.asData?.value.dailyMissions.any(
                  (mission) => mission.completed && !mission.claimed,
                ) ==
                true ||
            progression.asData?.value.achievements.any(
                  (achievement) =>
                      achievement.unlocked && !achievement.claimed,
                ) ==
                true);
    final content = session.when(
      data: (guest) => progression.when(
        data: (snapshot) => _PlayerStatusContent(
          displayName: guest.player.displayName,
          profile: snapshot.profile,
          compact: compact,
          dense: dense,
          frame: profileFrame,
        ),
        loading: () => _PlayerStatusLoading(
          displayName: guest.player.displayName,
          compact: compact,
          dense: dense,
          frame: profileFrame,
        ),
        error: (error, stackTrace) => _PlayerStatusError(
          displayName: guest.player.displayName,
          compact: compact,
          dense: dense,
          frame: profileFrame,
          onRetry: () => ref.invalidate(progressionProvider),
        ),
      ),
      loading: () => _PlayerStatusLoading(
        compact: compact,
        dense: dense,
        frame: profileFrame,
      ),
      error: (error, stackTrace) => _PlayerStatusError(
        compact: compact,
        dense: dense,
        frame: profileFrame,
        onRetry: () {
          ref.invalidate(guestSessionProvider);
          ref.invalidate(progressionProvider);
        },
      ),
    );

    return SizedBox(
      key: const ValueKey('player-status-bar'),
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: onTap == null
                ? content
                : Semantics(
                    button: true,
                    label: 'Profili aç',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('player-status-profile-action'),
                        borderRadius: BorderRadius.circular(compact ? 13 : 15),
                        onTap: onTap,
                        child: content,
                      ),
                    ),
                  ),
          ),
          if (hasClaimable)
            const Positioned(
              key: ValueKey('player-status-claim-badge'),
              right: -2,
              top: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: RelayColors.coral,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: RelayColors.surface, width: 2),
                  ),
                ),
                child: SizedBox(width: 12, height: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class CircuitCreditButton extends ConsumerWidget {
  const CircuitCreditButton({
    required this.onTap,
    this.compact = true,
    super.key,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progression = ref.watch(progressionProvider);
    final credits = progression.asData?.value.profile.credits;
    return Semantics(
      button: true,
      label: 'Devre Kredisi ile mağazayı aç',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('global-credit-action'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: BoxConstraints(
              minWidth: compact ? 82 : 94,
              minHeight: compact ? 46 : 52,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 11,
              vertical: compact ? 6 : 7,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    RelayColors.amber.withValues(alpha: 0.14),
                    RelayColors.surface,
                  ),
                  Color.alphaBlend(
                    RelayColors.coral.withValues(alpha: 0.06),
                    RelayColors.surfaceSoft,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: RelayColors.amber.withValues(alpha: 0.48),
              ),
              boxShadow: [
                BoxShadow(
                  color: RelayColors.amber.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.toll_outlined,
                      color: RelayColors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      credits == null ? '—' : '$credits',
                      key: const ValueKey('player-status-credits'),
                      style: const TextStyle(
                        color: RelayColors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'DEVRE KREDİSİ',
                  style: TextStyle(
                    color: RelayColors.muted,
                    fontSize: 6.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerStatusContent extends StatelessWidget {
  const _PlayerStatusContent({
    required this.displayName,
    required this.profile,
    required this.compact,
    required this.dense,
    required this.frame,
  });

  final String displayName;
  final PlayerProgression profile;
  final bool compact;
  final bool dense;
  final ProfileFrameVisualTheme frame;

  @override
  Widget build(BuildContext context) {
    return _StatusShell(
      compact: compact,
      frame: frame,
      child: Row(
        children: [
          if (!dense) ...[
            _PlayerAvatar(compact: compact, frame: frame),
            SizedBox(width: compact ? 7 : 9),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  displayName,
                  key: const ValueKey('player-status-name'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 8.5 : compact ? 10 : 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: compact ? 4 : 5),
                Row(
                  children: [
                    Text(
                      'SV. ${profile.level}',
                      key: const ValueKey('player-status-level'),
                      style: const TextStyle(
                        color: RelayColors.cyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          key: const ValueKey('player-status-progress'),
                          value: profile.levelProgress,
                          minHeight: compact ? 5 : 6,
                          backgroundColor: const Color(0xFF234450),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerStatusLoading extends StatelessWidget {
  const _PlayerStatusLoading({
    required this.compact,
    required this.dense,
    required this.frame,
    this.displayName,
  });

  final bool compact;
  final bool dense;
  final ProfileFrameVisualTheme frame;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return _StatusShell(
      compact: compact,
      frame: frame,
      child: Row(
        children: [
          if (!dense) ...[
            _PlayerAvatar(compact: compact, frame: frame),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              dense
                  ? 'YÜKLENİYOR…'
                  : displayName == null
                      ? 'OYUNCU HAZIRLANIYOR…'
                      : '$displayName • İLERLEME YÜKLENİYOR…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RelayColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _PlayerStatusError extends StatelessWidget {
  const _PlayerStatusError({
    required this.compact,
    required this.dense,
    required this.frame,
    required this.onRetry,
    this.displayName,
  });

  final bool compact;
  final bool dense;
  final ProfileFrameVisualTheme frame;
  final VoidCallback onRetry;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return _StatusShell(
      compact: compact,
      frame: frame,
      error: true,
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: RelayColors.coral,
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              dense
                  ? 'BAĞLANTI YOK'
                  : displayName == null
                      ? 'OYUNCU BİLGİSİ ALINAMADI'
                      : '$displayName • İLERLEME ALINAMADI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RelayColors.coral,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('player-status-retry'),
            tooltip: 'Oyuncu bilgisini yeniden yükle',
            visualDensity: VisualDensity.compact,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
          ),
        ],
      ),
    );
  }
}

class _StatusShell extends StatelessWidget {
  const _StatusShell({
    required this.compact,
    required this.child,
    required this.frame,
    this.error = false,
  });

  final bool compact;
  final Widget child;
  final ProfileFrameVisualTheme frame;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final borderColor = error
        ? RelayColors.coral.withValues(alpha: 0.55)
        : frame.accent.withValues(alpha: 0.62);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(frame.accent.withValues(alpha: 0.10), RelayColors.surface),
            Color.alphaBlend(frame.accent.withValues(alpha: 0.05), RelayColors.surfaceSoft),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 13 : 15),
        border: Border.all(color: borderColor),
        boxShadow: [
          const BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: frame.glow,
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 7,
        ),
        child: child,
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.compact,
    required this.frame,
  });

  final bool compact;
  final ProfileFrameVisualTheme frame;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: frame.glow,
        shape: BoxShape.circle,
        border: Border.all(color: frame.accent.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 7 : 8),
        child: Icon(
          frame.icon,
          color: frame.accent,
          size: compact ? 17 : 19,
        ),
      ),
    );
  }
}
