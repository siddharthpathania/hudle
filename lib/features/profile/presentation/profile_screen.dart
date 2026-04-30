import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/hudle_button.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';
import '../domain/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load profile: $e',
                style: const TextStyle(color: AppColors.hudleRose)),
          ),
        ),
        data: (profile) => _ProfileForm(profile: profile),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  String? _avatarUrl;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _username = TextEditingController(text: widget.profile.username);
    _bio = TextEditingController(text: widget.profile.bio ?? '');
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(File(picked.path));
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(avatarUrl: url);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _uploading = false);
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _save() async {
    final name = _displayName.text.trim();
    final user = _username.text.trim();
    if (name.isEmpty || user.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name and username are required')),
      );
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            displayName: name,
            username: user,
            bio: _bio.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.subtleSurface(context),
                backgroundImage:
                    _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? Text(
                        widget.profile.displayName.isEmpty
                            ? '?'
                            : widget.profile.displayName.characters.first
                                .toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: AppColors.emberOrange,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploading ? null : _pickAvatar,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded,
                              size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_rounded,
                  color: AppColors.hudleTeal),
              title: const Text('Email'),
              subtitle: Text(
                widget.profile.email,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.mutedText(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _displayName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display name',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _username,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bio,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Bio (optional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: UI.space32),
        HudleButton(
          label: 'Save changes',
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
