import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/player_status_bar.dart';
import '../widgets/relay_notice.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SocialPlayerModel> _searchResults = const [];
  bool _busy = false;
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialProvider);
    final clans = ref.watch(clanDirectoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOSYAL VE KLAN',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'PROJECT RELAY • v0.8.0',
              style: TextStyle(color: RelayColors.muted, fontSize: 10),
            ),
          ],
        ),
        actions: const [
          Center(child: PlayerStatusBar(compact: true)),
          SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            key: const ValueKey('social-scroll-view'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              social.when(
                data: (snapshot) => _socialContent(snapshot, clans),
                loading: () => const _MessageCard(
                  icon: Icons.groups_outlined,
                  title: 'Sosyal bilgiler yükleniyor',
                  message: 'Arkadaşlar ve klan durumu sunucudan alınıyor.',
                ),
                error: (error, _) => _MessageCard(
                  icon: Icons.error_outline,
                  title: 'Sosyal bilgiler alınamadı',
                  message: error.toString(),
                  actionLabel: 'TEKRAR DENE',
                  onAction: () => ref.invalidate(socialProvider),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                key: const ValueKey('social-menu-back'),
                onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('ANA MENÜYE DÖN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialContent(
    SocialSnapshotModel snapshot,
    AsyncValue<List<ClanModel>> clans,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _profileCard(snapshot.profile),
        const SizedBox(height: 14),
        if (snapshot.incomingRequests.isNotEmpty) ...[
          _sectionTitle(Icons.mark_email_unread_outlined, 'GELEN İSTEKLER'),
          const SizedBox(height: 8),
          Card(
            key: const ValueKey('social-incoming-requests'),
            child: Column(
              children: [
                for (final request in snapshot.incomingRequests)
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_add_alt_1),
                    ),
                    title: Text(
                      request.player.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(request.player.statusMessage),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          tooltip: 'Kabul et',
                          onPressed: _busy
                              ? null
                              : () => _respondRequest(
                                    request.requestId,
                                    accept: true,
                                  ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: RelayColors.mint,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Reddet',
                          onPressed: _busy
                              ? null
                              : () => _respondRequest(
                                    request.requestId,
                                    accept: false,
                                  ),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: RelayColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _sectionTitle(Icons.people_alt_outlined, 'ARKADAŞLAR'),
        const SizedBox(height: 8),
        Card(
          key: const ValueKey('social-friends-card'),
          child: snapshot.friends.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Henüz arkadaşın yok. Oyuncu arayarak istek gönderebilirsin.',
                    style: TextStyle(color: RelayColors.muted),
                  ),
                )
              : Column(
                  children: [
                    for (final friend in snapshot.friends)
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(
                          friend.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${friend.statusMessage} • Favori: ${friend.favoriteModule.displayName}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Arkadaşlıktan çıkar',
                          onPressed: _busy
                              ? null
                              : () => _removeFriend(friend.playerId),
                          icon: const Icon(Icons.person_remove_outlined),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _playerSearchCard(),
        const SizedBox(height: 14),
        _sectionTitle(Icons.hub_outlined, 'KLAN'),
        const SizedBox(height: 8),
        if (snapshot.clan != null)
          _currentClanCard(snapshot.clan!)
        else ...[
          _MessageCard(
            key: const ValueKey('social-no-clan-card'),
            icon: Icons.hub_outlined,
            title: 'Bir klana katıl veya kendi klanını kur',
            message:
                'Klanlar şimdilik sosyal kimlik ve üye listesi sağlar; savaş gücü vermez.',
            actionLabel: 'KLAN KUR',
            onAction: _busy ? null : _showCreateClanDialog,
          ),
          const SizedBox(height: 10),
          _clanDirectory(clans),
        ],
      ],
    );
  }

  Widget _profileCard(SocialProfileModel profile) {
    return Card(
      key: const ValueKey('social-profile-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0x2238E8FF),
              child: Icon(Icons.account_circle, color: RelayColors.cyan, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.statusMessage,
                    style: const TextStyle(color: RelayColors.muted),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${profile.friendCount} arkadaş • Favori modül: ${profile.favoriteModule.displayName}',
                    style: const TextStyle(
                      color: RelayColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('social-edit-profile'),
              tooltip: 'Profili düzenle',
              onPressed: _busy ? null : () => _showProfileDialog(profile),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerSearchCard() {
    return Card(
      key: const ValueKey('social-player-search'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(Icons.person_search_outlined, 'OYUNCU ARA'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    enabled: !_busy,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchPlayers(),
                    decoration: const InputDecoration(
                      labelText: 'Oyuncu adı',
                      hintText: 'En az 2 karakter',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _busy || _searching ? null : _searchPlayers,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final player in _searchResults)
                ListTile(
                  dense: true,
                  title: Text(
                    player.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${player.statusMessage} • ${player.favoriteModule.displayName}',
                  ),
                  trailing: _relationshipAction(player),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _relationshipAction(SocialPlayerModel player) {
    return switch (player.relationship) {
      'friend' => const Chip(label: Text('ARKADAŞ')),
      'outgoing' => const Chip(label: Text('İSTEK GİTTİ')),
      'incoming' => const Chip(label: Text('İSTEK GELDİ')),
      _ => FilledButton.tonal(
          onPressed: _busy ? null : () => _sendFriendRequest(player.playerId),
          child: const Text('EKLE'),
        ),
    };
  }

  Widget _currentClanCard(ClanModel clan) {
    return Card(
      key: const ValueKey('social-current-clan'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: RelayColors.amber.withValues(alpha: 0.16),
                  child: Text(
                    clan.tag,
                    style: const TextStyle(
                      color: RelayColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        clan.description,
                        style: const TextStyle(color: RelayColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${clan.memberCount}/20',
                  style: const TextStyle(
                    color: RelayColors.cyan,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            for (final member in clan.members)
              ListTile(
                dense: true,
                leading: Icon(
                  member.role == 'leader'
                      ? Icons.workspace_premium_outlined
                      : Icons.person_outline,
                  color: member.role == 'leader'
                      ? RelayColors.amber
                      : RelayColors.muted,
                ),
                title: Text(
                  member.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: member.isCurrentPlayer
                        ? RelayColors.cyan
                        : Colors.white,
                  ),
                ),
                trailing: Text(
                  member.role == 'leader' ? 'LİDER' : 'ÜYE',
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _leaveClan,
              icon: const Icon(Icons.logout),
              label: const Text('KLANDAN AYRIL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clanDirectory(AsyncValue<List<ClanModel>> clans) {
    return Card(
      key: const ValueKey('social-clan-directory'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: clans.when(
          data: (items) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(Icons.travel_explore_outlined, 'AÇIK KLANLAR'),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Text(
                  'Henüz açık klan yok. İlk klanı sen kurabilirsin.',
                  style: TextStyle(color: RelayColors.muted),
                )
              else
                for (final clan in items)
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        clan.tag,
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                    title: Text(
                      clan.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('${clan.description} • ${clan.memberCount}/20'),
                    trailing: FilledButton.tonal(
                      onPressed: _busy ? null : () => _joinClan(clan.clanId),
                      child: const Text('KATIL'),
                    ),
                  ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            error.toString(),
            style: const TextStyle(color: RelayColors.coral),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: RelayColors.cyan, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(socialProvider);
    ref.invalidate(clanDirectoryProvider);
    await Future.wait([
      ref.read(socialProvider.future),
      ref.read(clanDirectoryProvider.future),
    ]);
  }

  Future<void> _searchPlayers() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      RelayNotice.show(
        context,
        'Arama için en az 2 karakter yazın.',
        tone: RelayNoticeTone.warning,
      );
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(relayApiProvider).searchSocialPlayers(query);
      if (mounted) setState(() => _searchResults = results);
    } on RelayApiException catch (error) {
      if (mounted) {
        RelayNotice.show(context, error.message, tone: RelayNoticeTone.error);
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendFriendRequest(String playerId) async {
    await _runAction(
      () => ref.read(relayApiProvider).sendFriendRequest(playerId),
      'Arkadaşlık isteği gönderildi.',
    );
    await _searchPlayers();
  }

  Future<void> _respondRequest(String requestId, {required bool accept}) async {
    await _runAction(
      () => ref.read(relayApiProvider).respondFriendRequest(
            requestId: requestId,
            accept: accept,
          ),
      accept ? 'Arkadaşlık isteği kabul edildi.' : 'Arkadaşlık isteği reddedildi.',
    );
  }

  Future<void> _removeFriend(String playerId) async {
    await _runAction(
      () => ref.read(relayApiProvider).removeFriend(playerId),
      'Arkadaşlık kaldırıldı.',
    );
  }

  Future<void> _joinClan(String clanId) async {
    await _runAction(
      () => ref.read(relayApiProvider).joinClan(clanId),
      'Klana katıldın.',
      refreshClans: true,
    );
  }

  Future<void> _leaveClan() async {
    await _runAction(
      () => ref.read(relayApiProvider).leaveClan(),
      'Klan üyeliği sona erdi.',
      refreshClans: true,
    );
  }

  Future<void> _runAction(
    Future<SocialSnapshotModel> Function() action,
    String successMessage, {
    bool refreshClans = false,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(socialProvider);
      if (refreshClans) ref.invalidate(clanDirectoryProvider);
      if (!mounted) return;
      RelayNotice.show(
        context,
        successMessage,
        tone: RelayNoticeTone.success,
      );
    } on RelayApiException catch (error) {
      if (!mounted) return;
      RelayNotice.show(context, error.message, tone: RelayNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showProfileDialog(SocialProfileModel profile) async {
    final statusController = TextEditingController(text: profile.statusMessage);
    var favoriteModule = profile.favoriteModule;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('SOSYAL PROFİL'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: statusController,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Durum mesajı'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ModuleKind>(
                  initialValue: favoriteModule,
                  decoration: const InputDecoration(labelText: 'Favori modül'),
                  items: [
                    for (final kind in ModuleKind.values)
                      DropdownMenuItem(
                        value: kind,
                        child: Text(kind.displayName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => favoriteModule = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('İPTAL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('KAYDET'),
            ),
          ],
        ),
      ),
    );
    final statusMessage = statusController.text.trim();
    statusController.dispose();
    if (accepted != true) return;
    await _runAction(
      () => ref.read(relayApiProvider).updateSocialProfile(
            statusMessage: statusMessage,
            favoriteModule: favoriteModule,
          ),
      'Sosyal profil güncellendi.',
    );
  }

  Future<void> _showCreateClanDialog() async {
    final nameController = TextEditingController();
    final tagController = TextEditingController();
    final descriptionController = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('YENİ KLAN'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                maxLength: 48,
                decoration: const InputDecoration(labelText: 'Klan adı'),
              ),
              TextField(
                controller: tagController,
                maxLength: 8,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Kısa etiket'),
              ),
              TextField(
                controller: descriptionController,
                maxLength: 240,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('KLANI KUR'),
          ),
        ],
      ),
    );
    final name = nameController.text.trim();
    final tag = tagController.text.trim();
    final description = descriptionController.text.trim();
    nameController.dispose();
    tagController.dispose();
    descriptionController.dispose();
    if (accepted != true) return;
    await _runAction(
      () => ref.read(relayApiProvider).createClan(
            name: name,
            tag: tag,
            description: description,
          ),
      'Klan kuruldu.',
      refreshClans: true,
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: RelayColors.cyan, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(color: RelayColors.muted),
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
