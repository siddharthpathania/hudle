import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/hudle_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _username = TextEditingController();
  final _bio = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {/* TODO: image_picker */},
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.inkElevated,
                    child: const Icon(Icons.add_a_photo_outlined,
                        size: 32, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bio,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              HudleButton(
                label: "Let's go →",
                onPressed: () => context.go('/dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
