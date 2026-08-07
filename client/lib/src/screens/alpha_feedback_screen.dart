import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../navigation/navigation_actions.dart';
import '../theme/relay_theme.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/relay_notice.dart';

class AlphaFeedbackScreen extends ConsumerStatefulWidget {
  const AlphaFeedbackScreen({super.key});

  @override
  ConsumerState<AlphaFeedbackScreen> createState() => _AlphaFeedbackScreenState();
}

class _AlphaFeedbackScreenState extends ConsumerState<AlphaFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String _feedbackCategory = 'denge';
  bool _busy = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ALFA GERİ BİLDİRİMİ',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
            ),
            Text('PROJECT RELAY • v0.8.17', style: TextStyle(color: RelayColors.muted, fontSize: 10)),
          ],
        ),
        actions: const [AppHeaderActions(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('alpha-feedback-scroll-view'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            Card(
              key: const ValueKey('alpha-feedback-card'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle(Icons.forum_outlined, 'ALFA GERİ BİLDİRİMİ'),
                    const SizedBox(height: 8),
                    const Text(
                      'Denge, hata ve arayüz gözlemlerini doğrudan sunucuya kaydet. Kişisel bilgi yazma.',
                      style: TextStyle(color: RelayColors.muted),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('alpha-feedback-category'),
                      initialValue: _feedbackCategory,
                      items: const [
                        DropdownMenuItem(value: 'denge', child: Text('Denge')),
                        DropdownMenuItem(value: 'hata', child: Text('Hata')),
                        DropdownMenuItem(value: 'arayuz', child: Text('Arayüz')),
                        DropdownMenuItem(value: 'diger', child: Text('Diğer')),
                      ],
                      onChanged: _busy ? null : (value) { if (value != null) setState(() => _feedbackCategory = value); },
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('alpha-feedback-message'),
                      controller: _feedbackController,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 1200,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Geri bildirim',
                        hintText: 'Ne oldu, hangi ekranda oldu ve beklediğin davranış neydi?',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const ValueKey('alpha-feedback-submit'),
                      onPressed: _busy ? null : _submitFeedback,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('GERİ BİLDİRİMİ GÖNDER'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const ValueKey('alpha-feedback-back'),
              onPressed: _busy ? null : () => returnToMainMenu(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('ANA MENÜYE DÖN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: RelayColors.cyan, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.7)),
        ],
      );

  Future<void> _submitFeedback() async {
    final message = _feedbackController.text.trim();
    if (message.length < 8) {
      RelayNotice.show(context, 'Lütfen daha açıklayıcı bir geri bildirim yaz.', tone: RelayNoticeTone.warning);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(relayApiProvider).submitAlphaFeedback(category: _feedbackCategory, message: message);
      _feedbackController.clear();
      if (!mounted) return;
      RelayNotice.show(context, 'Alfa geri bildirimi gönderildi.', tone: RelayNoticeTone.success);
    } on RelayApiException catch (error) {
      if (!mounted) return;
      RelayNotice.show(context, error.message, tone: RelayNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
