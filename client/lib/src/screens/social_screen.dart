import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/navigation_actions.dart';
import '../api/relay_api.dart';
import '../state/profile_avatar.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/relay_notice.dart';
import '../widgets/relay_dialog.dart';
import '../widgets/chat_dock.dart';

enum _ClanSection { summary, members, activity, settings }

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({
    this.embeddedProfileOnly = false,
    this.embeddedFriendsOnly = false,
    super.key,
  });

  final bool embeddedProfileOnly;
  final bool embeddedFriendsOnly;

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SocialPlayerModel> _searchResults = const [];
  _ClanSection _selectedClanSection = _ClanSection.summary;
  bool _busy = false;
  bool _searching = false;
  bool _searchAttempted = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialProvider);
    final clans = ref.watch(clanDirectoryProvider);

    if (widget.embeddedProfileOnly) {
      return social.when(
        data: (snapshot) => _profileSection(snapshot),
        loading: () => const _MessageCard(
          icon: Icons.account_circle_outlined,
          title: 'Profil yükleniyor',
          message: 'Sosyal profil bilgileri sunucudan alınıyor.',
        ),
        error: (error, _) => _MessageCard(
          icon: Icons.error_outline,
          title: 'Profil alınamadı',
          message: error.toString(),
          actionLabel: 'TEKRAR DENE',
          onAction: () => ref.invalidate(socialProvider),
        ),
      );
    }

    if (widget.embeddedFriendsOnly) {
      return social.when(
        data: _friendsSection,
        loading: () => const _MessageCard(
          icon: Icons.people_alt_outlined,
          title: 'Arkadaşlar yükleniyor',
          message: 'Arkadaşlık bilgileri sunucudan alınıyor.',
        ),
        error: (error, _) => _MessageCard(
          icon: Icons.error_outline,
          title: 'Arkadaşlar alınamadı',
          message: error.toString(),
          actionLabel: 'TEKRAR DENE',
          onAction: () => ref.invalidate(socialProvider),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        centerTitle: true,
        title: const AppHeaderTitle(pageTitle: 'KLAN'),
        actions: const [
          AppHeaderActions(),
          SizedBox(width: 8),
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
                data: (snapshot) => _clanSection(snapshot, clans),
                loading: () => const _MessageCard(
                  icon: Icons.hub_outlined,
                  title: 'Klan bilgileri yükleniyor',
                  message: 'Klan durumu sunucudan alınıyor.',
                ),
                error: (error, _) => _MessageCard(
                  icon: Icons.error_outline,
                  title: 'Klan bilgileri alınamadı',
                  message: error.toString(),
                  actionLabel: 'TEKRAR DENE',
                  onAction: () => ref.invalidate(socialProvider),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                key: const ValueKey('social-menu-back'),
                onPressed: _busy ? null : () => returnToMainMenu(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('ANA MENÜYE DÖN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileSection(SocialSnapshotModel snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _profileCard(snapshot.profile),
      ],
    );
  }

  Widget _friendsSection(SocialSnapshotModel snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.incomingRequests.isNotEmpty) ...[
          _sectionTitle(Icons.mark_email_unread_outlined, 'GELEN İSTEKLER'),
          const SizedBox(height: 8),
          Card(
            key: const ValueKey('social-incoming-requests'),
            child: Column(
              children: [
                for (final request in snapshot.incomingRequests)
                  ListTile(
                    onTap: () => _showPlayerProfile(request.player),
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_add_alt_1),
                    ),
                    title: Text(
                      request.player.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${request.player.statusMessage}\n${_formatDate(request.createdAt)} tarihinde gönderildi',
                    ),
                    isThreeLine: true,
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
        if (snapshot.outgoingRequests.isNotEmpty) ...[
          _sectionTitle(Icons.send_outlined, 'GÖNDERİLEN İSTEKLER'),
          const SizedBox(height: 8),
          Card(
            key: const ValueKey('social-outgoing-requests'),
            child: Column(
              children: [
                for (final request in snapshot.outgoingRequests)
                  ListTile(
                    onTap: () => _showPlayerProfile(request.player),
                    leading: const CircleAvatar(
                      child: Icon(Icons.schedule_outlined),
                    ),
                    title: Text(
                      request.player.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${_formatDate(request.createdAt)} • Oyuncunun yanıtı bekleniyor',
                    ),
                    trailing: const Chip(label: Text('BEKLİYOR')),
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
                        onTap: () => _showPlayerProfile(friend),
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
                          onPressed: _busy ? null : () => _removeFriend(friend),
                          icon: const Icon(Icons.person_remove_outlined),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _playerSearchCard(),
      ],
    );
  }

  Widget _clanSection(
    SocialSnapshotModel snapshot,
    AsyncValue<List<ClanModel>> clans,
  ) {
    final clan = snapshot.clan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(Icons.hub_outlined, 'KLAN'),
        const SizedBox(height: 8),
        if (clan == null) ...[
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
        ] else ...[
          _clanSectionSelector(),
          const SizedBox(height: 12),
          switch (_selectedClanSection) {
            _ClanSection.summary => _clanSummaryCard(clan),
            _ClanSection.members => _clanMembersCard(clan),
            _ClanSection.activity => _clanActivityCard(clan),
            _ClanSection.settings => _clanSettingsCard(
                clan,
                snapshot.profile,
              ),
          },
        ],
      ],
    );
  }

  Widget _clanSectionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_ClanSection>(
        key: const ValueKey('clan-section-selector'),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _ClanSection.summary,
            icon: Icon(Icons.dashboard_outlined),
            label: Text('KLAN ÖZETİ'),
          ),
          ButtonSegment(
            value: _ClanSection.members,
            icon: Icon(Icons.group_outlined),
            label: Text('ÜYELER'),
          ),
          ButtonSegment(
            value: _ClanSection.activity,
            icon: Icon(Icons.timeline_outlined),
            label: Text('KLAN ETKİNLİĞİ'),
          ),
          ButtonSegment(
            value: _ClanSection.settings,
            icon: Icon(Icons.settings_outlined),
            label: Text('AYARLAR'),
          ),
        ],
        selected: {_selectedClanSection},
        onSelectionChanged: _busy
            ? null
            : (selection) {
                setState(() => _selectedClanSection = selection.first);
              },
      ),
    );
  }

  Widget _profileCard(SocialProfileModel profile) {
    final progression = ref.watch(progressionProvider).asData?.value.profile;
    final avatarIcon = ref.watch(profileAvatarProvider);
    return Card(
      key: const ValueKey('profile-general-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0x2238E8FF),
                  child: Icon(
                    avatarIcon,
                    color: RelayColors.cyan,
                    size: 34,
                  ),
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
                      if (progression != null) ...[
                        LinearProgressIndicator(
                          value: progression.levelProgress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: RelayColors.surface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SV ${progression.level} • ${progression.xpIntoLevel}/${progression.xpForNextLevel} XP',
                          style: const TextStyle(
                            color: RelayColors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ] else
                        const Text(
                          'Seviye ilerlemesi yükleniyor',
                          style: TextStyle(
                            color: RelayColors.muted,
                            fontSize: 10,
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
            const Divider(height: 24),
            Text(
              profile.statusMessage,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.memory, size: 17),
                  label: Text('Favori: ${profile.favoriteModule.displayName}'),
                ),
                Chip(
                  avatar: const Icon(Icons.people_alt_outlined, size: 17),
                  label: Text('${profile.friendCount} arkadaş'),
                ),
              ],
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
            const SizedBox(height: 5),
            const Text(
              'Görünen oyuncu adında en az iki karakter ara.',
              style: TextStyle(color: RelayColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('social-player-search-input'),
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
                  key: const ValueKey('social-player-search-submit'),
                  tooltip: 'Oyuncu ara',
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
            if (_searchAttempted &&
                !_searching &&
                _searchResults.isEmpty) ...[
              const SizedBox(height: 12),
              const _InlineState(
                icon: Icons.person_off_outlined,
                message: 'Bu adla eşleşen başka bir oyuncu bulunamadı.',
              ),
            ],
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(),
              for (final player in _searchResults)
                ListTile(
                  onTap: () => _showPlayerProfile(player),
                  dense: true,
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_circle_outlined),
                  ),
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

  Widget _clanSummaryCard(ClanModel clan) {
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
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: clan.memberCount / 20,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.lock_open_outlined, size: 17),
                  label: Text(clan.isOpen ? 'Açık klan' : 'Kapalı klan'),
                ),
                Chip(
                  avatar: const Icon(Icons.group_outlined, size: 17),
                  label: Text('${clan.memberCount} üye'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(chatDockProvider.notifier)
                  .openChannel('clan:${clan.clanId}'),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('KLAN SOHBETİ • TÜM ÜYELERE MESAJ'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Klan savaş gücü vermez. Klan savaşı, ortak kasa ve klan '
              'bonusları kapalı alfa sonrasında değerlendirilecek.',
              style: TextStyle(
                color: RelayColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clanMembersCard(ClanModel clan) {
    return Card(
      key: const ValueKey('clan-members-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(Icons.group_outlined, 'ÜYELER'),
            const SizedBox(height: 8),
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
                subtitle: Text(
                  '${_formatDate(member.joinedAt)} tarihinde katıldı',
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
          ],
        ),
      ),
    );
  }

  Widget _clanActivityCard(ClanModel clan) {
    final members = List<ClanMemberModel>.from(clan.members)
      ..sort((left, right) => right.joinedAt.compareTo(left.joinedAt));
    return Card(
      key: const ValueKey('clan-activity-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(Icons.timeline_outlined, 'KLAN ETKİNLİĞİ'),
            const SizedBox(height: 8),
            const Text(
              'Bu sürümde sunucuda ayrı bir klan etkinlik günlüğü yoktur. '
              'Aşağıdaki akış mevcut üye katılım tarihlerinden oluşturulur.',
              style: TextStyle(
                color: RelayColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const Divider(height: 24),
            if (members.isEmpty)
              const _InlineState(
                icon: Icons.hourglass_empty,
                message: 'Henüz gösterilecek klan etkinliği yok.',
              )
            else
              for (final member in members)
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.person_add_alt_1,
                    color: RelayColors.cyan,
                  ),
                  title: Text('${member.displayName} klana katıldı'),
                  subtitle: Text(_formatDate(member.joinedAt)),
                ),
          ],
        ),
      ),
    );
  }

  Widget _clanSettingsCard(
    ClanModel clan,
    SocialProfileModel profile,
  ) {
    final isLeader = clan.leaderPlayerId == profile.playerId;
    final canLeave = !isLeader || clan.memberCount == 1;
    return Card(
      key: const ValueKey('clan-settings-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(Icons.settings_outlined, 'KLAN AYARLARI'),
            const SizedBox(height: 10),
            Text(
              isLeader
                  ? 'Bu klanın liderisin.'
                  : 'Bu klanın üyesisin.',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (!canLeave)
              const Text(
                'Lider, başka üyeler varken klandan ayrılamaz. Liderlik devri '
                'henüz bu alfa sürümünde bulunmuyor.',
                style: TextStyle(
                  color: RelayColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const Text(
                'Ayrılma işlemi geri alınamaz. Yeniden katılmak için klanın '
                'açık olması gerekir.',
                style: TextStyle(color: RelayColors.muted, fontSize: 11),
              ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const ValueKey('social-leave-clan'),
              onPressed: _busy || !canLeave ? null : () => _leaveClan(clan),
              icon: const Icon(Icons.logout),
              label: Text(
                isLeader && clan.memberCount == 1
                    ? 'KLANI KAPAT VE AYRIL'
                    : 'KLANDAN AYRIL',
              ),
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
              const SizedBox(height: 5),
              const Text(
                'Katılmadan önce klan açıklamasını ve üye sayısını kontrol et.',
                style: TextStyle(color: RelayColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const _InlineState(
                  icon: Icons.hub_outlined,
                  message: 'Henüz açık klan yok. İlk klanı sen kurabilirsin.',
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
                      onPressed: _busy ? null : () => _joinClan(clan),
                      child: const Text('KATIL'),
                    ),
                  ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                error.toString(),
                style: const TextStyle(color: RelayColors.coral),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(clanDirectoryProvider),
                child: const Text('TEKRAR DENE'),
              ),
            ],
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
    setState(() {
      _searching = true;
      _searchAttempted = true;
      _searchResults = const [];
    });
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

  Future<void> _removeFriend(SocialPlayerModel friend) async {
    final confirmed = await _confirmAction(
      title: 'Arkadaşlığı kaldır',
      message:
          '${friend.displayName} arkadaş listesinden çıkarılsın mı? Daha sonra yeniden istek gönderebilirsin.',
      confirmLabel: 'ARKADAŞLIĞI KALDIR',
      destructive: true,
    );
    if (!confirmed) return;
    await _runAction(
      () => ref.read(relayApiProvider).removeFriend(friend.playerId),
      'Arkadaşlık kaldırıldı.',
    );
  }

  Future<void> _joinClan(ClanModel clan) async {
    final confirmed = await _confirmAction(
      title: '${clan.tag} klanına katıl',
      message:
          '${clan.name} klanına katılmak istediğine emin misin? Aynı anda yalnız bir klana üye olabilirsin.',
      confirmLabel: 'KLANA KATIL',
    );
    if (!confirmed) return;
    await _runAction(
      () => ref.read(relayApiProvider).joinClan(clan.clanId),
      '${clan.name} klanına katıldın.',
      refreshClans: true,
    );
  }

  Future<void> _leaveClan(ClanModel clan) async {
    final closesClan = clan.memberCount == 1;
    final confirmed = await _confirmAction(
      title: closesClan ? 'Klanı kapat' : 'Klandan ayrıl',
      message: closesClan
          ? '${clan.name} klanının tek üyesisin. Ayrılırsan klan kalıcı olarak kapatılır.'
          : '${clan.name} klanından ayrılmak istediğine emin misin?',
      confirmLabel: closesClan ? 'KLANI KAPAT' : 'KLANDAN AYRIL',
      destructive: true,
    );
    if (!confirmed) return;
    await _runAction(
      () => ref.read(relayApiProvider).leaveClan(),
      closesClan ? 'Klan kapatıldı.' : 'Klan üyeliği sona erdi.',
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
    var selectedAvatar = ref.read(profileAvatarProvider);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('SOSYAL PROFİL'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PublicTextWarning(),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('social-status-message-input'),
                    controller: statusController,
                    maxLength: 160,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Durum mesajı'),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profil simgesi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final icon in selectableProfileIcons)
                        ChoiceChip(
                          label: Icon(icon, color: RelayColors.cyan),
                          selected: selectedAvatar == icon,
                          onSelected: (_) {
                            setDialogState(() => selectedAvatar = icon);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ModuleKind>(
                    key: const ValueKey('social-favorite-module-input'),
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
    if (statusMessage.isEmpty) {
      _showValidation('Durum mesajı boş bırakılamaz.');
      return;
    }
    if (_containsPrivateContact(statusMessage)) {
      _showValidation(
        'Durum mesajında kişisel iletişim bilgisi veya bağlantı paylaşma.',
      );
      return;
    }
    ref.read(profileAvatarProvider.notifier).select(selectedAvatar);
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PublicTextWarning(
                  message:
                      'Klan adı, etiketi ve açıklaması herkese açıktır. Kişisel bilgi veya iletişim adresi yazma.',
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('social-clan-name-input'),
                  controller: nameController,
                  maxLength: 48,
                  decoration: const InputDecoration(labelText: 'Klan adı'),
                ),
                TextField(
                  key: const ValueKey('social-clan-tag-input'),
                  controller: tagController,
                  maxLength: 8,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kısa etiket',
                    helperText: '2-8 harf, rakam veya alt çizgi',
                  ),
                ),
                TextField(
                  key: const ValueKey('social-clan-description-input'),
                  controller: descriptionController,
                  maxLength: 240,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
              ],
            ),
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
    final tag = tagController.text.trim().toUpperCase();
    final description = descriptionController.text.trim();
    nameController.dispose();
    tagController.dispose();
    descriptionController.dispose();
    if (accepted != true) return;
    if (name.length < 3) {
      _showValidation('Klan adı en az 3 karakter olmalıdır.');
      return;
    }
    if (!RegExp(r'^[A-Z0-9_]{2,8}$').hasMatch(tag)) {
      _showValidation('Klan etiketi 2-8 harf, rakam veya alt çizgi olmalıdır.');
      return;
    }
    if (description.length < 3) {
      _showValidation('Klan açıklaması en az 3 karakter olmalıdır.');
      return;
    }
    if (_containsPrivateContact('$name $description')) {
      _showValidation(
        'Klan adı veya açıklamasında kişisel iletişim bilgisi paylaşma.',
      );
      return;
    }
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

  Future<void> _showPlayerProfile(SocialPlayerModel player) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(20),
              decoration: RelayDecorations.panel(accent: RelayColors.violet),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: RelayDecorations.accentHalo(RelayColors.cyan),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.account_circle_outlined, color: RelayColors.cyan, size: 34),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.displayName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text(
                              _relationshipLabel(player.relationship),
                              style: const TextStyle(color: RelayColors.cyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8),
                            ),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: RelayColors.surfaceHigh.withValues(alpha: .62),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: RelayColors.violet.withValues(alpha: .25)),
                    ),
                    child: Text(player.statusMessage),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    avatar: const Icon(Icons.memory, size: 17),
                    label: Text('Favori modül: ${player.favoriteModule.displayName}'),
                  ),
                  const SizedBox(height: 14),
                  if (player.relationship == 'friend')
                    FilledButton.icon(
                      onPressed: () async {
                        final session = await ref.read(guestSessionProvider.future);
                        if (!mounted || !sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        ref.read(chatDockProvider.notifier).openChannel(
                              directChatIdentity(session.player.id, player.playerId),
                            );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('MESAJ GÖNDER'),
                    ),
                  if (player.relationship != 'friend')
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              _sendFriendRequest(player.playerId);
                            },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('ARKADAŞLIK İSTEĞİ GÖNDER'),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sosyal profil savaş gücü veya eşleştirme avantajı vermez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RelayColors.muted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.62),
          builder: (dialogContext) => RelayConfirmDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            destructive: destructive,
          ),
        ) ??
        false;
  }

  void _showValidation(String message) {
    RelayNotice.show(
      context,
      message,
      tone: RelayNoticeTone.warning,
    );
  }

  bool _containsPrivateContact(String value) {
    final email = RegExp(r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b');
    final link = RegExp(r'\b(?:https?://|www\.)\S+', caseSensitive: false);
    final longPhone = RegExp(r'(?:\+?\d[\s().-]*){9,}');
    return email.hasMatch(value) || link.hasMatch(value) || longPhone.hasMatch(value);
  }

  String _relationshipLabel(String relationship) {
    return switch (relationship) {
      'friend' => 'ARKADAŞ',
      'outgoing' => 'ARKADAŞLIK İSTEĞİ GÖNDERİLDİ',
      'incoming' => 'ARKADAŞLIK İSTEĞİ BEKLİYOR',
      _ => 'OYUNCU',
    };
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: RelayColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: RelayColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicTextWarning extends StatelessWidget {
  const _PublicTextWarning({
    this.message =
        'Bu alan diğer oyunculara açıktır. Kişisel bilgi, iletişim adresi veya bağlantı paylaşma.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RelayColors.amber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RelayColors.amber.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_outlined,
            color: RelayColors.amber,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: RelayColors.amber,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
