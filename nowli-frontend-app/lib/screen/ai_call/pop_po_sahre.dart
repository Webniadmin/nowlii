import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class PopPoSahre extends StatefulWidget {
  const PopPoSahre({super.key});

  @override
  State<PopPoSahre> createState() => _PopPoSahreState();
}

class _PopPoSahreState extends State<PopPoSahre> {
  String selectedLanguage = "";
  String selectedVoice = "";

  // -------------------------------
  // LANGUAGE BOTTOM SHEET
  // -------------------------------
  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Transform.translate(
          offset: const Offset(0, -20), // Move up 20px
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Select Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                _languageTile("English"),
                _languageTile("Español"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageTile(String title) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selectedLanguage == title
              ? FontWeight.bold
              : FontWeight.normal,
          color: selectedLanguage == title ? Colors.blue : Colors.black,
        ),
      ),
      trailing: selectedLanguage == title
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() => selectedLanguage = title);
        Navigator.pop(context);
        _showVoiceSheet(context);
      },
    );
  }

  // -------------------------------
  // VOICE BOTTOM SHEET
  // -------------------------------
  void _showVoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Transform.translate(
          offset: const Offset(0, -20),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Choose Voice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                _voiceTile("Male"),
                _voiceTile("Female"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _voiceTile(String title) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selectedVoice == title
              ? FontWeight.bold
              : FontWeight.normal,
          color: selectedVoice == title ? Colors.blue : Colors.black,
        ),
      ),
      trailing: selectedVoice == title
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() => selectedVoice = title);
        Navigator.pop(context);
      },
    );
  }

  // -------------------------------
  // MAIN SCREEN UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Assets.svgImages.popupScreeLiner.image().image,
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close Button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, color: Colors.blue),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // TITLE + IMAGES + BUTTONS
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'In one line, how does the procrastination show up to you?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4542EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // IMAGE STACK
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: Assets.svgImages.twoColorPopupSpkeing
                                .image()
                                .image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: Assets.svgImages.popupSpeking.image().image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Assets.svgImages.popUpSpekingTwoCarton.image(
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // BUTTON ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Choose AI voice',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _showLanguageSheet(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'English',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
