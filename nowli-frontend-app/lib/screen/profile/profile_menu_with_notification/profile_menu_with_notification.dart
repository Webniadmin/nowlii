import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/profile_service.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:nowlii/services/subscription_schedule.dart';
import 'package:nowlii/services/subscription_service.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key});

  @override
  State<ProfileNotificationsScreen> createState() => _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState extends State<ProfileNotificationsScreen> with WidgetsBindingObserver {
  ProfileData? _profileData;
  int _streakCount = 0;
  bool _isLoading = true;

  /// Quests still open. Null while loading, and null again if the fetch failed — a blocked
  /// or offline user must not be told they have zero quests when we simply could not count.
  int? _activeQuests;

  SubscriptionStatus? _subStatus;
  SubscriptionPlan? _subPlan;

  /// The stage the user is paying for, e.g. "Rhythm". Null for someone on the trial, who is
  /// not on a paid stage yet.
  String? get _planStage =>
      stageForMonth(_subPlan, _subStatus?.monthIndex ?? 0);

  /// Their plan has lapsed and nothing is covering them any more.
  bool get _planExpired => _subStatus != null && !_subStatus!.hasAccess;

  /// What the card calls the plan the user is on right now.
  ///
  /// "Nowlii Pro" is only the loading state. Everything else names the actual position:
  /// the trial while it runs, the paid stage once one starts, the free-forever stage after
  /// the year, and what ended if it ended. A card on the profile that says "Nowlii Pro"
  /// forever tells the user nothing they did not already know from installing the app.
  String get _planTitle {
    final status = _subStatus;
    if (status == null) return 'NOWLII PRO';
    final stage = _planStage;

    if (_planExpired) {
      if (stage != null) return '${stage.toUpperCase()} PLAN EXPIRED';
      // Never reached a paid stage — what ended was the trial, and saying "plan" would
      // imply they had bought one.
      return status.trialUsed ? 'FREE TRIAL ENDED' : 'PLAN EXPIRED';
    }
    if (status.lifetimeFree) return 'FREE FOREVER';
    if (status.inTrial) return 'FREE TRIAL';
    if (stage != null) return '${stage.toUpperCase()} PLAN';
    return 'NOWLII PRO';
  }

  /// The line under the title: how long is left, or what it costs. Null when there is
  /// nothing truthful to add.
  String? get _planSubtitle {
    final status = _subStatus;
    if (status == null || _planExpired) return null;
    if (status.lifetimeFree) return 'Free forever — nothing more to pay';
    if (status.inTrial) {
      final days = status.trialDaysLeft;
      final left = days == 1 ? '1 day left' : '$days days left';
      return '$left · then \$${status.currentPrice.toStringAsFixed(2)}/mo';
    }
    if (status.monthIndex > 0) {
      return '\$${status.currentPrice.toStringAsFixed(2)}/mo · month ${status.monthIndex}';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload profile when app comes to foreground
      _loadProfileData();
    }
  }

  @override
  void didUpdateWidget(ProfileNotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload profile when widget updates
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profileService = ProfileService();
    final subService = SubscriptionService();
    final profile = await profileService.fetchProfile();
    final streak = await profileService.fetchStreak();
    final status = await subService.getMyStatus();
    final plan = await subService.getPlan();

    // Reading quests survives a lapse, so a lapsed user still gets a real count — the
    // design shows it in the expired state too. The count is only withheld when the
    // backend did not answer at all: `fetchAllQuests` reports failure as an empty list,
    // and "0 quests active" is a claim about the user's week, not about our connection.
    int? activeQuests;
    if (status != null) {
      final quests = await QuestService().fetchAllQuests();
      activeQuests = quests.where((q) => !q.taskDone).length;
    }

    if (mounted) {
      setState(() {
        _profileData = profile;
        _streakCount = streak;
        _subStatus = status;
        _subPlan = plan;
        _activeQuests = activeQuests;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              Assets.svgImages.profile.path,
              fit: BoxFit.cover,
            ),
          ),
          // Scrollable Content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileSection(context),
                      const SizedBox(height: 20),
                      _buildNotificationsSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(Assets.svgIcons.profileBack.path, () {
                context.pop();
              }),
              _buildIconButton(Assets.svgIcons.settingProfile.path, () {
                context.push('/settingsScreen');
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Profile Picture
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    image: _profileData?.profileImage.isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(_profileData!.profileImage),
                            fit: BoxFit.cover,
                          )
                        : DecorationImage(
                            image: AssetImage(Assets.svgIcons.editProfilePng_.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 90,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      Assets.images.love.path,
                      height: 26,
                      width: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 65),

          // Profile Card
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColorsApps.softCream1,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Streak Badge
                    _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _buildStatRow(
                            Assets.svgIcons.fireTab.path,
                            '$_streakCount day${_streakCount != 1 ? 's' : ''} streak',
                          ),

                    // Only shown when we actually counted — see [_activeQuests].
                    if (!_isLoading && _activeQuests != null) ...[
                      const SizedBox(height: 8),
                      _buildStatRow(
                        Assets.svgIcons.magicWand.path,
                        '$_activeQuests quest${_activeQuests != 1 ? 's' : ''} active',
                      ),
                    ],

                    const SizedBox(height: 20),
                    _buildPlanCard(context),
                  ],
                ),
              ),

              // User Name Badge
              Positioned(
                top: -68,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    height: 74,
                    width: 265,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FFF00),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          // The shared 52pt title is a display size meant for short
                          // headings; a name is user-supplied and can be any length, and
                          // at 52 an eight-character one needed ~250dp of the 225dp this
                          // pill has, so it ran to the edges. 40 with a scale-down keeps
                          // short names large and lets long ones shrink instead of
                          // colliding with the padding. Local override — the style is
                          // shared with the quest screens, which are not affected.
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                (_profileData?.name ?? 'USER').toUpperCase(),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: AppTextStylesQutes.alfaSlabOneTitle
                                    .copyWith(fontSize: 40),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionButton(
                'Edit Profile',
                Assets.svgIcons.editProfilePng.path,
                () async {
                  // Navigate and reload when returning
                  await context.push('/editProfileScreen');
                  // Reload profile data
                  if (mounted) {
                    _loadProfileData();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Contact support',
                Assets.svgIcons.contactSupport.path,
                () {
                  context.push('/supportScreen');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(minHeight: screenHeight * 0.5),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notifications Header
          Row(
            children: [
              Text('NOTIFICATIONS', style: AppsTextStyles.signupText32),
              const SizedBox(width: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFA0E871),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '0',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Nothing has arrived yet. The design answers that with an invitation rather
          // than an empty panel, so the screen still offers a next step.
          Center(
            child: SizedBox(
              width: 212,
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Assets.svgIcons.bellSimpleSlash.svg(
                        width: 17.54,
                        height: 19.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Looks quiet here right now.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tiny wins make big shifts.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4C586E),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutespath.aiVoice),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF4542EB),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'Talk to Fuzzy',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFFFFFEF8),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// One "🔥 3 days streak" / "🪄 12 quests active" line inside the profile card.
  Widget _buildStatRow(String iconPath, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(iconPath, height: 24, width: 24),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.workSans(
            color: const Color(0xFF011F54),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.20,
            letterSpacing: -0.50,
          ),
        ),
      ],
    );
  }

  /// The plan the user is on, in the two states the design gives it.
  ///
  /// Green while it is carrying them, orange with a Renew action once it has lapsed. The
  /// stage name comes from the backend's own schedule (see [stageForMonth]) — the card
  /// falls back to "Nowlii Pro" only while the plan is still loading or for a trial user,
  /// who is not on a named paid stage yet.
  Widget _buildPlanCard(BuildContext context) {
    final expired = _planExpired;
    final title = _planTitle;
    final subtitle = _planSubtitle;

    // Radial gradients lifted from the design: green reads as "running", orange as
    // "needs you".
    const greenFill = RadialGradient(
      center: Alignment(-0.07, 0),
      radius: 1.1,
      colors: [
        Color(0xFFC9FFA7),
        Color(0xFFA6ED90),
        Color(0xFF82DA79),
        Color(0xFF5FC862),
        Color(0xFF3BB64B),
      ],
      stops: [0, 0.25, 0.5, 0.75, 1],
    );
    const orangeFill = RadialGradient(
      center: Alignment(-0.07, 0),
      radius: 1.1,
      colors: [
        Color(0xFFFFFCF1),
        Color(0xFFFFE1BE),
        Color(0xFFFFC68C),
        Color(0xFFFFAA59),
        Color(0xFFFF9D3F),
        Color(0xFFFF8F26),
      ],
      stops: [0, 0.25, 0.5, 0.75, 0.875, 1],
    );

    return GestureDetector(
      onTap: () => context.push('/nowliProSubscription'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: expired ? orangeFill : greenFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Wosker',
                color: Color(0xFF011F54),
                fontSize: 32,
                height: 0.8,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: GoogleFonts.workSans(
                  color: const Color(0xCC011F54),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
            // A lapsed plan is the one case where the card has something to do, so it
            // carries the action rather than relying on the whole card being tappable.
            if (expired) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.push('/nowliProSubscription'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F26),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                  ),
                  child: Text(
                    'Renew',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(String assetPath, VoidCallback onPressed) {
    return IconButton(icon: Image.asset(assetPath), onPressed: onPressed);
  }

  Widget _buildActionButton(
    String text,
    String assetPath,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColorsApps.skyBlue2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(assetPath, width: 28, height: 28),
            const SizedBox(width: 8),
            Text(text, style: AppsTextStyles.workSansBlack20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    IconData? icon,
    String? iconPath,
    required String title,
    required String subtitle,
    required String action,
    required String time,
    bool isNew = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: iconPath != null
                ? Image.asset(iconPath, width: 50, height: 50)
                : Icon(icon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(
                            action,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Color(0xFF4A90E2),
                          ),
                        ],
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7FFF00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
