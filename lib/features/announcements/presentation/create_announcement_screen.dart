import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/hudle_button.dart';
import '../data/announcements_repository.dart';
import '../domain/announcement_model.dart';
import '../domain/announcements_provider.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({required this.groupId, super.key});
  final String groupId;

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _content = TextEditingController();
  final _pollQuestion = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _addPoll = false;
  bool _saving = false;

  @override
  void dispose() {
    _content.dispose();
    _pollQuestion.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_options.length <= 2) return;
    setState(() {
      _options.removeAt(i).dispose();
    });
  }

  Future<void> _submit() async {
    final hasContent = _content.text.trim().isNotEmpty;
    final hasPollData = _addPoll &&
        _pollQuestion.text.trim().isNotEmpty &&
        _options.where((c) => c.text.trim().isNotEmpty).length >= 2;

    if (!hasContent && !hasPollData) return;
    
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(announcementsRepositoryProvider).createAnnouncement(
            CreateAnnouncementInput(
              groupId: widget.groupId,
              content: _content.text.trim(),
              pollQuestion:
                  _addPoll ? _pollQuestion.text.trim() : null,
              pollOptions: _addPoll
                  ? _options.map((c) => c.text).toList()
                  : const [],
            ),
          );
      ref.invalidate(groupAnnouncementsProvider(widget.groupId));
      ref.invalidate(pendingAnnouncementsProvider(widget.groupId));
      if (nav.canPop()) nav.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New announcement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _content,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Announcement',
              hintText: 'Share an update with the group…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.poll_outlined,
                      color: AppColors.amberGold),
                  title: const Text('Add a poll'),
                  subtitle: Text(
                    'Let members vote on options',
                    style: GoogleFonts.dmSans(
                        color: AppColors.mutedText(context), fontSize: 12),
                  ),
                  value: _addPoll,
                  onChanged: (v) => setState(() => _addPoll = v),
                ),
                if (_addPoll) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _pollQuestion,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Question',
                            hintText: 'What should we vote on?',
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _options.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _options[i],
                                    decoration: InputDecoration(
                                      labelText: 'Option ${i + 1}',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline_rounded),
                                  onPressed: _options.length > 2
                                      ? () => _removeOption(i)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add option'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: UI.space32),
          HudleButton(
            label: _content.text.trim().isEmpty && _addPoll
                ? 'Post poll'
                : 'Post announcement',
            isLoading: _saving,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Text(
            'Non-admins: your post will wait for admin approval.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }
}
