import 'package:flutter/material.dart';
import 'package:nowlii/themes/text_styles.dart';

class NamePage extends StatefulWidget {
  final VoidCallback onContinue;
  final Function(String) onNameChanged;
  final String initialName;

  const NamePage({
    super.key,
    required this.onContinue,
    required this.onNameChanged,
    required this.initialName,
  });

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  late TextEditingController _nameController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      setState(() {});
    });

    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Let's get to know each other!",
                style: AppsTextStyles.passwordDescription,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 343,
                child: Text(
                  'WHAT SHOULD NOWLII CALL YOU?',
                  style: TextStyle(
                    color: const Color(0xFF011F54) /* Background-bg-dark */,
                    fontSize: 46,
                    fontFamily: 'Wosker',
                    fontWeight: FontWeight.w400,
                    height: 0.80,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 🔹 TextField with focus tracking
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nameController,
                focusNode: _focusNode,
                onChanged: widget.onNameChanged,
                style: AppsTextStyles.typeSomeThingHere.copyWith(
                  color: const Color(0xFF4542EB),
                ),
                decoration: InputDecoration(
                  hintText: 'TYPE SOMETHING HERE...',
                  hintStyle: AppsTextStyles.typeSomeThingHere.copyWith(),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.3),

            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A3AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: AppsTextStyles.continueButton.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
