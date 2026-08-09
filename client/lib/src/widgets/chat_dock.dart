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
  final Map<String, DateTime> _lastObservedByChannel = <String, DateTime>{};
  final Map<String, int> _unreadByChannel = <String, int>{};
  bool _pollingActivity = false;
  ChatChannelModel? _selected;
  List<ChatMessageModel> _messages = const [];
  bool _loadingMessages = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_pollChatActivity(initial: true));
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) unawaited(_pollChatActivity());
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
          unreadCount: _unreadTotal,
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
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final selected = _selected?.identity == channel.identity;
          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 138),
                  child: Text(channel.title, overflow: TextOverflow.ellipsis),
                ),
                if ((_unreadByChannel[channel.identity] ?? 0) > 0) ...[
                  const SizedBox(width: 5),
                  _UnreadPill(count: _unreadByChannel[channel.identity]!),
                ],
              ],
            ),
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
    setState(() {
      _selected = channel;
      _unreadByChannel[channel.identity] = 0;
    });
    await _loadMessages();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final channel = _selected;
    if (channel == null || (!silent && _loadingMessages)) return;
    if (!silent && mounted) setState(() => _loadingMessages = true);
    try {
      final next = await ref.read(relayApiProvider).fetchChatMessages(channel);
      if (mounted) {
        setState(() {
          _messages = next;
          _rememberLatest(channel.identity, next);
          if (ref.read(chatDockProvider).open) {
            _unreadByChannel[channel.identity] = 0;
          }
        });
      }
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

  int get _unreadTotal => _unreadByChannel.values.fold<int>(0, (sum, value) => sum + value);

  Future<void> _pollChatActivity({bool initial = false}) async {
    if (_pollingActivity || !mounted) return;
    _pollingActivity = true;
    try {
      final channels = await ref.read(chatChannelsProvider.future);
      final currentId = ref.read(guestSessionProvider).asData?.value.player.id;
      final dock = ref.read(chatDockProvider);
      for (final channel in channels) {
        if (!mounted) return;
        try {
          final messages = await ref.read(relayApiProvider).fetchChatMessages(channel);
          final previous = _lastObservedByChannel[channel.identity];
          final latest = _latestCreatedAt(messages);

          if (!initial && previous != null) {
            final incoming = messages.where((message) {
              return message.createdAt.isAfter(previous) &&
                  message.senderPlayerId != currentId;
            }).length;
            final selectedAndVisible = dock.open && _selected?.identity == channel.identity;
            if (incoming > 0 && !selectedAndVisible && mounted) {
              setState(() {
                _unreadByChannel[channel.identity] =
                    (_unreadByChannel[channel.identity] ?? 0) + incoming;
              });
            }
          }

          if (latest != null) {
            _lastObservedByChannel[channel.identity] = latest;
          }

          if (dock.open && _selected?.identity == channel.identity && mounted) {
            setState(() {
              _messages = messages;
              _unreadByChannel[channel.identity] = 0;
            });
          }
        } catch (_) {
          // Bir kanalın erişim/polling hatası sohbet dock'unu veya oyunu durdurmamalı.
        }
      }
    } catch (_) {
      // Oturum veya ağ henüz hazır değilse bir sonraki polling turu tekrar dener.
    } finally {
      _pollingActivity = false;
    }
  }

  void _rememberLatest(String identity, List<ChatMessageModel> messages) {
    final latest = _latestCreatedAt(messages);
    if (latest != null) _lastObservedByChannel[identity] = latest;
  }

  DateTime? _latestCreatedAt(List<ChatMessageModel> messages) {
    DateTime? latest;
    for (final message in messages) {
      if (latest == null || message.createdAt.isAfter(latest)) {
        latest = message.createdAt;
      }
    }
    return latest;
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
  const _CollapsedChatButton({required this.onTap, required this.unreadCount});
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          key: const ValueKey('chat-collapsed-button'),
          duration: const Duration(milliseconds: 220),
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: RelayDecorations.panel(
            accent: hasUnread ? RelayColors.amber : RelayColors.violet,
            soft: true,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    hasUnread ? Icons.mark_chat_unread_outlined : Icons.forum_outlined,
                    color: hasUnread ? RelayColors.amber : RelayColors.cyan,
                    size: 20,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: RelayColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  hasUnread
                      ? 'SOHBET • $unreadCount yeni mesaj'
                      : 'SOHBET • Açmak için tıkla',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: hasUnread ? RelayColors.white : null,
                  ),
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 7),
                _UnreadPill(count: unreadCount),
              ] else
                const Icon(Icons.chevron_right, color: RelayColors.violet),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: RelayColors.coral,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RelayColors.white.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: RelayColors.coral.withValues(alpha: 0.34),
            blurRadius: 10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: RelayColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
