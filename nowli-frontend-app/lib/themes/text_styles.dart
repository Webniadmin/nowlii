import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';

class AppsTextStyles {
  static TextStyle workSansBodyEntryScreen = GoogleFonts.workSans(
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    fontSize: 18,
    height: 1.4,
    color: const Color(0xFFC8CBD2) /* Text-text-primary-light */,
  );

  static TextStyle getStarted = const TextStyle(
    fontFamily: 'Wosker',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Color(0xFF011F54),
  );
  static TextStyle haveAnAccount = const TextStyle(
    fontFamily: 'Wosker',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFEF8),
  );
  static TextStyle appleAndGoogleText = TextStyle(
    fontFamily: 'Wosker',
    fontSize: 12.sp,
    color: const Color(0xFFFFFEF8),
  );
  static TextStyle readyToStart = TextStyle(
    fontFamily: 'Wosker',
    // fontSize: 10,
    fontSize: 14.sp,
    color: const Color(0xFFFFFEF8),
  );

  static final TextStyle normalText = TextStyle(
    fontSize: 14,
    color: Colors.black87,
    height: 1.4,
  );

  static final TextStyle linkText = TextStyle(
    color: Color(0xFF4542EB),
    decoration: TextDecoration.underline,
    fontWeight: FontWeight.w500,
  );
  static TextStyle signupText = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    fontSize: 68.sp, // ScreenUtil responsive font size
    color: const Color(0xFF011F54),
  );

  static TextStyle signupText28 = const TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular (400)
    fontStyle: FontStyle.normal,
    fontSize: 38, // 50px responsive
    color: Color(0xFF011F54), // Default color (can override)
  );
  static TextStyle signupText32 = const TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular (400)
    fontStyle: FontStyle.normal,
    fontSize: 24, // 50px responsive
    color: Color(0xFF011F54), // Default color (can override)
  );

  static TextStyle signInText = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular (400)
    fontStyle: FontStyle.normal,
    fontSize: 40.sp, // 50px responsive
    color: const Color(0xFF011F54), // Default color (can override)
  );

  static TextStyle fullNameAndEmail = GoogleFonts.workSans(
    fontWeight: FontWeight.w600, // SemiBold
    fontStyle: FontStyle.normal, // Normal
    fontSize: 20, // 16px
    height: 1.0, // Line-height 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF4542EB), // Hex color #4542EB
  );
  static TextStyle regular16 = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontStyle: FontStyle.normal, // Normal (not italic)
    fontSize: 16, // 16px
    height: 1.4, // Line-height 140%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF011F54), // Hex color #011F54
  );
  static TextStyle continueButton = GoogleFonts.workSans(
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.normal,
    fontSize: 20,
    height: 0.8, // Line-height 80%
    letterSpacing: 0, // 0px
  );
  static TextStyle signInContinueButton = GoogleFonts.workSans(
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.normal,
    fontSize: 20,
    height: 0.8, // Line-height 80%
    letterSpacing: 0, // 0px
    color: Color(0xFF8C4F15),
  );
  static TextStyle googleContinueButton = GoogleFonts.workSans(
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.normal,
    fontSize: 20,
    height: 0.8, // Line-height 80%
    letterSpacing: 0, // 0px
    color: const Color(0xFF4542EB), // Hex color #4542EB
  );
  static TextStyle googleContinueButton32 = const TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    fontSize: 32,
    height: 0.8, // Line-height 80%
    letterSpacing: 0, // 0px
    color: Color(0xFF4542EB), // Hex color #4542EB
  );
  static TextStyle googleContinueButton52 = const TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    fontSize: 52,
    height: 0.8, // Line-height 80%
    letterSpacing: 0, // 0px
    color: Color(0xFF4542EB), // Hex color #4542EB
  );
  static final TextStyle workSansSemiBold16 = GoogleFonts.workSans(
    fontWeight: FontWeight.w700, // SemiBold
    fontStyle: FontStyle.normal, // Regular style
    fontSize: 16, // 16px
    height: 1.0, // line-height: 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF011F54), // #011F54
  );
  static final TextStyle workSansSemiBold16SignInalredy = GoogleFonts.workSans(
    fontWeight: FontWeight.w700, // SemiBold
    fontStyle: FontStyle.normal, // Regular style
    fontSize: 16, // 16px
    height: 1.0, // line-height: 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF4542EB), // #4542EB
  );
  static final TextStyle workSansSemiBold16signIn = GoogleFonts.workSans(
    fontWeight: FontWeight.w900, // SemiBold
    fontStyle: FontStyle.normal, // Regular style
    fontSize: 20, // 16px
    height: 1.0, // line-height: 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF011F54), // #011F54
  );
  static final TextStyle workSansSemiBold16SignInAlread = GoogleFonts.workSans(
    fontWeight: FontWeight.w700, // SemiBold
    fontStyle: FontStyle.normal, // Regular style
    fontSize: 16, // 16px
    height: 1.0, // line-height: 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFFFF8F26), // #4542EB
  );
  static TextStyle fullNameAndEmailSignIn = GoogleFonts.workSans(
    fontWeight: FontWeight.w600, // SemiBold
    fontStyle: FontStyle.normal, // Normal
    fontSize: 20, // 16px
    height: 1.0, // Line-height 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF4542EB), // Hex color #4542EB
  );
  static TextStyle resetPassword = TextStyle(
    fontFamily: 'Wosker',
    color: Color(0xFF011F54), // Background-bg-dark
    fontSize: 48.sp, // 48px responsive
    fontWeight:
        FontWeight.w400, // AlfaSlabOne only has one weight, but this is fine
    height: 0.9,
  );
  static TextStyle sendResetLinkButton = GoogleFonts.workSans(
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.normal,
    fontSize: 20,
    height: 0.8, // Line-height 80%
    letterSpacing: 0, // 0px
    color: Color(0xFF011F54),
  );
  static final TextStyle didNotGetEmail = GoogleFonts.workSans(
    fontWeight: FontWeight.w500, // SemiBold
    fontStyle: FontStyle.normal, // Regular style
    fontSize: 16, // 16px
    height: 1.0, // line-height: 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF011F54), // #011F54
  );
  static final TextStyle resendLink = GoogleFonts.workSans(
    fontWeight: FontWeight.w500, // SemiBold
    fontStyle: FontStyle.normal, // Regular style
    fontSize: 16, // 16px
    height: 1.0, // line-height: 100%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFFFF8F26), // #4542EB
  );
  static final TextStyle passwordUpdate = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // ExtraBold
    fontSize: 20,
    height: 1.2, // 120%
    letterSpacing: -0.02 * 20, // -2%
    color: const Color(0xFF011F54),
  );
  static final TextStyle passwordUpdateSub = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 16,
    height: 1.32, // 132%
    letterSpacing: -0.05 * 16, // -5%
    color: const Color(0xFF4C586E),
  );
  static final TextStyle passwordDescription = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 16,
    height: 1.4, // 140%
    letterSpacing: -0.05 * 16, // -5%
    color: const Color(0xFF4C586E),
  );
  // ignore: non_constant_identifier_names
  static TextStyle saimTitle = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 38.sp,
    height: 1, // 80%
    letterSpacing: 0,
    color: Color(0xFF011F54),
  );
  static TextStyle saimTitle28 = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 36,
    height: 1, // 80%
    letterSpacing: 0,
    color: Color(0xFF011F54),
  );
  static const TextStyle saimTitle44 = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 44,
    height: 0.8, // 80%
    letterSpacing: 0,
    color: Color(0xFF011F54),
  );
  static const TextStyle alphaTitle = TextStyle(
    fontFamily: 'Wosker',
    // fontFamily: 'AlfaSlabOne',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 44,
    height: 0.8, // line-height: 80%
    letterSpacing: 0, // 0%
    color: Color(0xFFA9A8F6), // #A9A8F6
  );
  static const TextStyle typeSomeThingHere = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 32,
    height: 0.8, // 80%
    letterSpacing: 0, // 0%
    color: Color(0xFF869CBB),
  );
  static final TextStyle workSansRegular14 = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 14,
    height: 1.6, // 160%
    letterSpacing: 0, // 0px
    color: const Color(0xFF4C586E),
  );
  static final TextStyle extraBold32Centered = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // ExtraBold
    fontSize: 32,
    height: 1.2, // line-height: 120%
    letterSpacing: -1,
    color: const Color(0xFF011F54), // #011F54
  );
  static const TextStyle regular32Uppercase = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w600, // Regular
    fontSize: 27,
    height: 0.95, // line-height 80%
    letterSpacing: 0.7, // 2% of font size
    // Flutter-এ text-transform নেই, তাই Text widget-এ uppercase ব্যবহার করতে হবে
    color: Color(0xFF011F54), // চাইলে তোমার color বসাও
  );
  static final TextStyle regular16l = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 18,
    height: 1.4, // line-height: 140%
    letterSpacing: -0.5,
    color: const Color(0xFF011F54), // #011F54
  );
  static const TextStyle letsStartNext = TextStyle(
    fontFamily: 'Wosker',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 20,
    height: 1.4, // line-height: 140%
    letterSpacing: -0.5,
    color: Color(0xFF011F54), // #011F54
  );
  static final TextStyle black24Uppercase = GoogleFonts.workSans(
    fontWeight: FontWeight.w900, // Black
    fontSize: 24,
    height: 0.9, // line-height: 90%
    letterSpacing: -0.5,
    color: const Color(0xFF011F54), // #011F54
  );
  static final TextStyle extraBold16 = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // ExtraBold
    fontSize: 14,
    height: 1.4, // line-height: 140%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFF011F54), // #011F54
  );
  static final TextStyle extraBold22 = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // ExtraBold
    fontSize: 22.31,
    height: 1.4, // line-height: 140%
    letterSpacing: -0.56, // -0.56px
    color: const Color(0xFF011F54), // #011F54
  );
  static final TextStyle black24UppercaseSome = GoogleFonts.workSans(
    fontWeight: FontWeight.w900, // Black
    fontSize: 24,
    height: 0.9, // line-height: 90%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFFFFFCF1), // #FFFCF1
  );
  static final TextStyle regular18 = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 18,
    height: 1.4, // line-height: 140%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFFFFFCF1), // #FFFCF1
  );
  static final TextStyle semiBold18 = GoogleFonts.workSans(
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 22,
    height: 1.4, // line-height: 140%
    letterSpacing: -0.5, // -0.5px
    color: const Color(0xFFFFFCF1), // #FFFCF1
  );

  static final TextStyle workSansBlack20 = GoogleFonts.workSans(
    fontWeight: FontWeight.w900, // Black = 900
    fontSize: 20,
    height: 0.8, // line-height: 80% = 0.8 in Flutter
    letterSpacing: 0, // letter-spacing: 0px
    decoration: TextDecoration.none,
    color: AppColorsApps.lightBlueBackground,
  );

  static const TextStyle kSettingsTitleStyle = TextStyle(
    fontFamily: 'Wosker',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    height: 0.8, // 80% line height
    letterSpacing: 0,
    color: Color(0xFFFFFEF8),
  );
  static final TextStyle textDefaultStyle = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // ExtraBold
    fontStyle: FontStyle.normal,
    fontSize: 20,
    height: 1.2, // line-height 120%
    letterSpacing: -0.5,
    color: const Color(0xFF1A1A1A), // replace with your desired color
  );
  static final TextStyle myWorkSansStyle = GoogleFonts.workSans(
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 16,
    height: 1.4, // line-height: 140%
    letterSpacing: -0.05 * 18, // -5% of font size
    color: const Color(0xFF011F54),
  );
  static final TextStyle workSansRegular16 = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 16,
    height: 1.4, // 140%
    letterSpacing: -0.5, // directly in px
    color: const Color(0xFF1A1A1A), // replace with your desired color
  );
  static final TextStyle workSansRegularF16 = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 16,
    height: 1.4, // 140%
    letterSpacing: -0.5,
    color: const Color(0xFF595754),
  );
  static final TextStyle workSansExtraBold20 = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // 800 -> ExtraBold
    fontSize: 20,
    height: 1.2, // line-height 120%
    letterSpacing: -0.5,
  );

  static final TextStyle workSansy6ExtraBold20 = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // ExtraBold
    fontSize: 20,
    height: 1.2, // line-height 120%
    letterSpacing: -0.5,
  );

  static TextStyle workSansSemiBold18 = GoogleFonts.workSans(
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 18,
    height: 1.4, // line-height 140%
    letterSpacing: -0.05 * 18, // -5% of font size
  );

  static TextStyle workSansSemiBold15 = GoogleFonts.workSans(
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 18,
    height: 1.4, // line-height 140%
    letterSpacing: -0.05 * 18, // -5% of font size
  );
  static TextStyle workSansRegularAdd16 = GoogleFonts.workSans(
    fontWeight: FontWeight.w400, // Regular
    fontSize: 16,
    height: 1.4, // line-height 140%
    letterSpacing: -0.5,
    color: const Color(0xFF4C586E), // text color
  );
  static TextStyle workSansExtraBold20Center = GoogleFonts.workSans(
    fontWeight: FontWeight.w800, // ExtraBold
    fontSize: 20,
    height: 1.2, // line-height 120%
    letterSpacing: -0.5,
    color: const Color(0xFF011F54), // text color
  );
  static TextStyle workSansBlack18Center = GoogleFonts.workSans(
    fontWeight: FontWeight.w900, // Black
    fontSize: 18,
    height: 0.8, // line-height 80%
    letterSpacing: 0,
    color: const Color(0xFFFFFEF8), // text color
  );
  static TextStyle regularResponsive(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.06; // screen width এর 6% ধরে font size

    return TextStyle(
      fontFamily: 'Wosker',
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
      height: 0.8,
      color: const Color(0xFF011F54),
    );
  }

  static TextStyle workSansBlack18CenterBlue = GoogleFonts.workSans(
    fontWeight: FontWeight.w900, // Black
    fontSize: 18,
    height: 0.8, // 80% line-height
    letterSpacing: 0,
    color: const Color(0xFF4542EB), // #4542EB
  );

  static TextStyle labelworkSansSemiBold18 = GoogleFonts.workSans(
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 18,
    height: 1.4, // 140% line-height
    letterSpacing: -0.05 * 18, // -5% of font size
    color: Colors.black, // replace with your desired color
  );
}
