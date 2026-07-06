import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PopupChooseMoodUpdates extends StatelessWidget {
  const PopupChooseMoodUpdates({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/images/Popup_Choose mood updates (1).png",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // 🔴 TOP LEFT CLOSE BUTTON
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context), // tap korle close hobe
                      child: Image.asset(
                        'assets/images/blu_cross.png', // ekhane tomaar image path
                        width: 44,
                        height: 44,
                      ),
                    ),
                  ),
                ),
                Spacer(),
                SizedBox(height: 30),
                // 🟢 CENTER EMOJI IMAGES
                Container(
                  padding: const EdgeInsets.all(20),

                  child: Image.asset(
                    'assets/images/emoji.png', // ekhane tomaar image path
                    width: 231,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),

                const Spacer(flex: 1),

                // TEXT
                SizedBox(
                  width: 310,
                  height: 51,
                  child: Text(
                    'WANT TO KEEP TRACK OF HOW YOU FEEL?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF011F54) /* Text-text-default */,
                      fontSize: 32,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 0.80,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "Fuzzy can gently check in each day — to help you spot your emotional patterns and celebrate progress. 🌿",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF424242),
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(flex: 2),

                // 🔵 FIRST BUTTON - "Not now"
                SizedBox(
                  width: double.infinity,
                  height: 69,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          color: Color(0xFF4A46FF),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // context.push("");
                    },
                    child: Text(
                      'Not now',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF4542EB), // Text-text-primary
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 🟣 SECOND BUTTON - "Yes, I'd like that"
                SizedBox(
                  width: double.infinity,
                  height: 69,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A46FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.push("/energyCheckInScreen");
                    },
                    child: Text(
                      'Yes, I’d like that',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFFFFFDF7), // Text-text-light
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
