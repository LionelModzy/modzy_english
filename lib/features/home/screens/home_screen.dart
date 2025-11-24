import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/preferences_service.dart';
import '../../../models/user_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../lessons/screens/lessons_screen.dart';
import '../../quiz/screens/quiz_list_screen.dart';
import '../../vocabulary/screens/vocabulary_screen.dart';
import '../../videos/screens/video_screen.dart';
import '../../../core/services/user_progress_utils.dart';
import '../../mini_games/screens/mini_games_menu_screen.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';
import '../../social/screens/friend_challenge_screen.dart';
import '../widgets/rank_map_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthRepository.getCurrentUserData();
      if (mounted) {
        setState(() {
          currentUser = user;
          isLoading = false;
        });
      }
      // Sync progress after loading user
      await UserProgressUtils.syncUserProgressWithStats();
      // Reload user data to get updated progress
      final updatedUser = await AuthRepository.getCurrentUserData();
      if (mounted) {
        setState(() {
          currentUser = updatedUser;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final rememberMe = await PreferencesService.getRememberMe();
    if (!rememberMe) await PreferencesService.clearCredentials();
    await AuthRepository.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: _AppColors.background,
        body: Center(
          child: Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(_AppColors.primary),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final gridCrossAxisCount = isTablet ? 3 : 2;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: _Header(
                      displayName: currentUser?.displayName ?? 'User',
                      onProfileTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                        _loadUserData();
                      },
                      onLogoutTap: _signOut,
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _ProgressCard(user: currentUser, isDark: isDark),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _FeatureShortcutSection(
                      onChallengeTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FriendChallengeScreen()),
                        );
                      },
                    ),
                  ),
                ),
                
                if (currentUser?.isAdmin == true) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _AdminCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                          );
                        },
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
                
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isTablet ? 1.1 : 0.9,
                    ),
                    delegate: SliverChildListDelegate([
                      _ActionCard(
                        icon: Icons.play_lesson_rounded,
                        title: 'Start Lesson',
                        subtitle: 'Begin learning',
                        color: _AppColors.primary,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LessonsScreen()));
                        },
                        isDark: isDark,
                      ),
                      _ActionCard(
                        icon: Icons.quiz_rounded,
                        title: 'Take Quiz',
                        subtitle: 'Test knowledge',
                        color: _AppColors.secondary,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuizListScreen()));
                        },
                        isDark: isDark,
                      ),
                      _ActionCard(
                        icon: Icons.library_books_rounded,
                        title: 'Vocabulary',
                        subtitle: 'Learn words',
                        color: _AppColors.accent,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VocabularyScreen()));
                        },
                        isDark: isDark,
                      ),
                      _ActionCard(
                        icon: Icons.videocam_rounded,
                        title: 'Watch Videos',
                        subtitle: 'English videos',
                        color: _AppColors.success,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VideoScreen()));
                        },
                        isDark: isDark,
                      ),
                      _ActionCard(
                        icon: Icons.videogame_asset_rounded,
                        title: 'Mini Games',
                        subtitle: 'Play & learn',
                        color: _AppColors.feature5,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MiniGamesMenuScreen()));
                        },
                        isDark: isDark,
                      ),
                      _ActionCard(
                        icon: Icons.leaderboard_rounded,
                        title: 'Leaderboard',
                        subtitle: 'View rankings',
                        color: _AppColors.feature1,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                        },
                        isDark: isDark,
                      ),
                    ]),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                // Rank Map Widget
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: RankMapWidget(currentUser: currentUser),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String displayName;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const _Header({
    required this.displayName,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back! 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(icon: Icons.person_rounded, onTap: onProfileTap),
        const SizedBox(width: 12),
        _CircleButton(icon: Icons.logout_rounded, onTap: onLogoutTap),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        gradient: _AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final UserModel? user;
  final bool isDark;

  const _ProgressCard({this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Level ${user?.currentLevel ?? 1} - ${user?.levelName ?? "Beginner"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatItem(icon: Icons.book_rounded, label: 'Lessons', value: '${user?.totalLessonsCompleted ?? 0}'),
              _StatItem(icon: Icons.language_rounded, label: 'Vocabulary', value: '${user?.totalVocabularyLearned ?? 0}'),
              _StatItem(icon: Icons.percent_rounded, label: 'Progress', value: '${(user?.progressPercentage ?? 0).toInt()}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _AdminCard({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _AppColors.adminGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _AppColors.adminPrimary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Open Admin Dashboard',
            onPressed: onTap,
            isAdmin: true,
            icon: Icons.dashboard_rounded,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: _AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _FeatureShortcutSection extends StatelessWidget {
  final VoidCallback onChallengeTap;

  const _FeatureShortcutSection({required this.onChallengeTap});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.smart_toy_rounded,
        'title': 'AI Assistant',
        'subtitle': 'Trợ lý AI hỗ trợ học',
        'color': _AppColors.feature2,
      },
      {
        'icon': Icons.group_rounded,
        'title': 'Group Study',
        'subtitle': 'Học nhóm, cùng tiến bộ',
        'color': _AppColors.feature3,
      },
      {
        'icon': Icons.sports_kabaddi_rounded,
        'title': 'Challenge',
        'subtitle': 'Thách đấu bạn bè',
        'color': _AppColors.feature4,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Tính năng mới sắp ra mắt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Sử dụng LayoutBuilder để responsive
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            
            // Tính toán kích thước card responsive
            double cardWidth;
            double cardHeight;
            int itemsPerView;
            
            if (screenWidth < 380) {
              // Rất nhỏ (mobile nhỏ)
              cardWidth = 130;
              cardHeight = 130;
              itemsPerView = 3;
            } else if (screenWidth < 480) {
              // Mobile nhỏ
              cardWidth = 140;
              cardHeight = 135;
              itemsPerView = 3;
            } else if (screenWidth < 600) {
              // Mobile trung bình
              cardWidth = 150;
              cardHeight = 140;
              itemsPerView = 3;
            } else if (screenWidth < 800) {
              // Tablet nhỏ
              cardWidth = 160;
              cardHeight = 145;
              itemsPerView = 4;
            } else {
              // Tablet lớn
              cardWidth = 170;
              cardHeight = 150;
              itemsPerView = 4;
            }
            
            // Tính chiều rộng cần thiết để hiển thị
            final totalWidthNeeded = (cardWidth * itemsPerView) + (16 * (itemsPerView - 1));
            final shouldScroll = screenWidth < totalWidthNeeded;
            
            return SizedBox(
              height: cardHeight,
              child: ListView.separated(
                physics: shouldScroll ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(
                  right: shouldScroll ? 24 : 0,
                  left: 4,
                ),
                itemCount: features.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final f = features[i];
                  final isChallengeFeature = f['title'] == 'Challenge';
                  return SizedBox(
                    width: cardWidth,
                    child: _FeatureCard(
                      icon: f['icon'] as IconData,
                      title: f['title'] as String,
                      subtitle: f['subtitle'] as String,
                      color: f['color'] as Color,
                      onTap: () {
                        if (isChallengeFeature) {
                          onChallengeTap();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${f['title']} - Coming soon!'),
                              backgroundColor: _AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container với kích thước cố định
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              
              const Spacer(),
              
              // Title - giới hạn 1 dòng
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Subtitle - giới hạn 2 dòng với chiều cao cố định
              SizedBox(
                height: 28, // Chiều cao cố định cho 2 dòng
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: _AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppColors {
  // Blue color palette
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF10B981);
  
  // Admin colors
  static const Color adminPrimary = Color(0xFFDC2626);
  static const Color adminLight = Color(0xFFEF4444);
  
  // Feature colors
  static const Color feature1 = Color(0xFFF59E0B);
  static const Color feature2 = Color(0xFF06B6D4);
  static const Color feature3 = Color(0xFF10B981);
  static const Color feature4 = Color(0xFF8B5CF6);
  static const Color feature5 = Color(0xFFEC4899);
  
  // Background & text colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  
  // Gradients
  static final Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static final Gradient adminGradient = LinearGradient(
    colors: [adminPrimary, adminLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}