import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';

class ChatDockState {
  const ChatDockState({this.open = false, this.requestedIdentity});
  final bool open;
  final String? requestedIdentity;

  ChatDockState copyWith({bool? open, String? requestedIdentity, bool clearRequest = false}) {
    return ChatDockState(
      open: open ?? this.open,
      requestedIdentity: clearRequest ? null : requestedIdentity ?? this.requestedIdentity,
    );
  }
}

class ChatDockController extends Notifier<ChatDockState> {
  @override
  ChatDockState build() => const ChatDockState();

  void toggle() => state = state.copyWith(open: !state.open);
  void openChannel(String identity) => state = ChatDockState(open: true, requestedIdentity: identity);
  void close() => state = state.copyWith(open: false);
  void clearRequest() => state = state.copyWith(clearRequest: true);
}

final chatDockProvider = NotifierProvider<ChatDockController, ChatDockState>(ChatDockController.new);

String directChatIdentity(String leftPlayerId, String rightPlayerId) {
  final ids = [leftPlayerId, rightPlayerId]..sort();
  return 'direct:${ids.join(":")}';
}

class ChatDock extends ConsumerStatefulWidget {
  const ChatDock({super.key});

  @override
  ConsumerState<ChatDock> createState() => _ChatDockState();
}

class _ChatDockState extends ConsumerState<ChatDock> {
  final _messageController = TextEditingController();
  Timer? _pollTimer;
  ChatChannelModel? _selected;
  List<ChatMessageModel> _messages = const [];
  bool _loadingMessages = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && ref.read(chatDockProvider).open) {
        unawaited(_loadMessages(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dock = ref.watch(chatDockProvider);
    final channels = ref.watch(chatChannelsProvider);
    ref.listen(chatDockProvider, (previous, next) {
      if (next.open && next.requestedIdentity != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _applyRequestedChannel());
      }
    });

    if (!dock.open) {
      return Positioned(
        left: 14,
        bottom: 14,
        child: _CollapsedChatButton(
          onTap: () => ref.read(chatDockProvider.notifier).toggle(),
        ),
      );
    }

    return Positioned(
      left: 12,
      bottom: 12,
      top: 92,
      width: 430,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: RelayDecorations.panel(accent: RelayColors.violet),
          child: Column(
            children: [
              _header(),
              const Divider(height: 1),
              channels.when(
                data: (items) => _channelStrip(items),
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error.toString(), style: const TextStyle(color: RelayColors.coral)),
                ),
              ),
              Expanded(child: _messageArea()),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, color: RelayColors.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SOHBET', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                Text(_selected?.title ?? 'Kanal seç', style: const TextStyle(color: RelayColors.muted, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Grup oluştur',
            onPressed: _showCreateGroup,
            icon: const Icon(Icons.group_add_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Sohbeti kapat',
            onPressed: () => ref.read(chatDockProvider.notifier).close(),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }

  Widget _channelStrip(List<ChatChannelModel> channels) {
    if (_selected == null && channels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selected == null) _selectChannel(channels.first);
      });
    }
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final selected = _selected?.identity == channel.identity;
          return ChoiceChip(
            selected: selected,
            label: Text(channel.title, overflow: TextOverflow.ellipsis),
            avatar: Icon(_channelIcon(channel.type), size: 16),
            onSelected: (_) => _selectChannel(channel),
          );
        },
      ),
    );
  }

  Widget _messageArea() {
    if (_selected == null) {
      return const Center(child: Text('Sohbet kanalı seç.', style: TextStyle(color: RelayColors.muted)));
    }
    if (_loadingMessages && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return const Center(child: Text('Henüz mesaj yok. İlk sinyali sen gönder.', style: TextStyle(color: RelayColors.muted)));
    }
    final currentId = ref.watch(guestSessionProvider).asData?.value.player.id;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      itemCount: _messages.length,
      itemBuilder: (context, reverseIndex) {
        final message = _messages[_messages.length - 1 - reverseIndex];
        final mine = message.senderPlayerId == currentId;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
            decoration: BoxDecoration(
              color: mine
                  ? RelayColors.cyan.withValues(alpha: 0.15)
                  : RelayColors.surfaceHigh.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: mine
                    ? RelayColors.cyan.withValues(alpha: 0.34)
                    : RelayColors.violet.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderDisplayName,
                  style: TextStyle(
                    color: mine ? RelayColors.cyan : RelayColors.violet,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message.message),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _selected != null && !_sending,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Mesaj yaz...',
                isDense: true,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Gönder',
            onPressed: _selected == null || _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _applyRequestedChannel() async {
    final state = ref.read(chatDockProvider);
    final identity = state.requestedIdentity;
    if (identity == null) return;
    try {
      final channels = await ref.read(chatChannelsProvider.future);
      final match = channels.where((item) => item.identity == identity).firstOrNull;
      if (match != null) await _selectChannel(match);
    } finally {
      ref.read(chatDockProvider.notifier).clearRequest();
    }
  }

  Future<void> _selectChannel(ChatChannelModel channel) async {
    if (!mounted) return;
    setState(() => _selected = channel);
    await _loadMessages();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final channel = _selected;
    if (channel == null || (!silent && _loadingMessages)) return;
    if (!silent && mounted) setState(() => _loadingMessages = true);
    try {
      final next = await ref.read(relayApiProvider).fetchChatMessages(channel);
      if (mounted) setState(() => _messages = next);
    } catch (_) {
      // Sohbet oyunun ana akışını kesmemeli; sonraki polling tekrar dener.
    } finally {
      if (!silent && mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _send() async {
    final channel = _selected;
    final text = _messageController.text.trim();
    if (channel == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(relayApiProvider).sendChatMessage(channel: channel, message: text);
      _messageController.clear();
      await _loadMessages(silent: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showCreateGroup() async {
    final social = await ref.read(socialProvider.future);
    if (!mounted) return;
    final nameController = TextEditingController();
    final selected = <String>{};
    final created = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.64),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('YENİ SOHBET GRUBU'),
          content: SizedBox(
            width: 390,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, maxLength: 40, decoration: const InputDecoration(labelText: 'Grup adı')),
                const SizedBox(height: 8),
                for (final friend in social.friends)
                  CheckboxListTile(
                    dense: true,
                    value: selected.contains(friend.playerId),
                    title: Text(friend.displayName),
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selected.add(friend.playerId);
                      } else {
                        selected.remove(friend.playerId);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('VAZGEÇ')),
            FilledButton(onPressed: selected.isEmpty ? null : () => Navigator.pop(dialogContext, true), child: const Text('GRUBU KUR')),
          ],
        ),
      ),
    );
    final name = nameController.text.trim();
    nameController.dispose();
    if (created != true || name.isEmpty) return;
    final channel = await ref.read(relayApiProvider).createChatGroup(name: name, memberPlayerIds: selected.toList());
    ref.invalidate(chatChannelsProvider);
    await _selectChannel(channel);
  }

  IconData _channelIcon(String type) => switch (type) {
        'clan' => Icons.hub_outlined,
        'direct' => Icons.person_outline,
        'group' => Icons.groups_2_outlined,
        _ => Icons.public,
      };
}

class _CollapsedChatButton extends StatelessWidget {
  const _CollapsedChatButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: RelayDecorations.panel(accent: RelayColors.violet, soft: true),
          child: const Row(
            children: [
              Icon(Icons.forum_outlined, color: RelayColors.cyan, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('SOHBET • Açmak için tıkla', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
              Icon(Icons.chevron_right, color: RelayColors.violet),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
