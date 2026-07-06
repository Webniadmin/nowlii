import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GenderPage extends StatelessWidget {
  final String userName;
  final String selectedGender;
  final Function(String) onGenderSelected;

  const GenderPage({
    super.key,
    required this.userName,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFD9E5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEY ${userName.toUpperCase()}!',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 52.sp,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'WHICH GENDER DESCRIBES YOU?',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 48.sp,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  GenderButton(
                    text: 'I\'m a man',
                    value: "I'm a man",
                    isSelected: selectedGender == "I'm a man",
                    onPressed: () => onGenderSelected("I'm a man"),
                  ),
                  SizedBox(height: 10.h),
                  GenderButton(
                    text: 'I\'m a woman',
                    value: "I'm a woman",
                    isSelected: selectedGender == "I'm a woman",
                    onPressed: () => onGenderSelected("I'm a woman"),
                  ),
                  SizedBox(height: 10.h),
                  GenderButton(
                    text: 'Another gender',
                    value: 'Another gender',
                    isSelected: selectedGender == 'Another gender',
                    onPressed: () => onGenderSelected('Another gender'),
                  ),
                  SizedBox(height: 140.h),
                  Text(
                    'You can always update this later. We\'ve got you.',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4C586E),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GenderButton extends StatelessWidget {
  final String text;
  final String value;
  final bool isSelected;
  final VoidCallback onPressed;

  const GenderButton({
    super.key,
    required this.text,
    required this.value,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 70.h,
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5865F2) : const Color(0xFFD9E5F5),
          borderRadius: BorderRadius.circular(35.r),
          border: Border.all(color: const Color(0xFF4542EB), width: 2.5.w),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              color: isSelected ? Colors.white : const Color(0xFF4542EB),
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
