import 'package:flutter/material.dart';

import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';

class VoiceSelectorPopup extends StatefulWidget {
  const VoiceSelectorPopup({super.key, this.current});

  /// The voice already on the profile, so the sheet opens on the user's own choice.
  ///
  /// Without it the sheet always opened with "Female" ticked, whatever the account
  /// actually held — so a user who had picked Male was shown, every time they looked,
  /// that they had not. There was no way to tell a setting that had not saved from one
  /// that had.
  final String? current;

  static Future<String?> show(BuildContext context, {String? current}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceSelectorPopup(current: current),
    );
  }

  @override
  State<VoiceSelectorPopup> createState() => _VoiceSelectorPopupState();
}

class _VoiceSelectorPopupState extends State<VoiceSelectorPopup> {
  late String _selectedVoice = _normalise(widget.current);

  /// Map whatever the profile holds onto one of the two options this sheet offers.
  ///
  /// The backend column is free-ish text with choices, and an account created before the
  /// selector existed can carry an empty value; both land on Female, which is the voice
  /// such an account actually hears.
  static String _normalise(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    return value.startsWith('m') ? 'Male' : 'Female';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColorsApps.skyBlueLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text('Choose voice', style: AppsTextStyles.textDefaultStyle),
          const SizedBox(height: 16),

          // Female option
          _buildVoiceOption('Female'),

          // Male option
          _buildVoiceOption('Male'),
        ],
      ),
    );
  }

  Widget _buildVoiceOption(String voice) {
    final isSelected = _selectedVoice == voice;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedVoice = voice;
        });
        // Close and return selected voice
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context, voice);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(voice, style: AppsTextStyles.myWorkSansStyle),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF4C3EDD), size: 24),
          ],
        ),
      ),
    );
  }
}
