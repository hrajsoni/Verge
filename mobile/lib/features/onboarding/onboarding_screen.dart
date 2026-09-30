import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/liquid_glass_button.dart';
import '../../core/widgets/liquid_glass_card.dart';
import '../../core/widgets/liquid_mesh_background.dart';

enum OnboardingStep {
  welcome,
  nameAndDob,
  genderAndLookingFor,
  interests,
  preferences,
  location,
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingCompleted;

  const OnboardingScreen({
    super.key,
    required this.onOnboardingCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingStep _currentStep = OnboardingStep.welcome;

  // Form State
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDob = DateTime(2002, 1, 1);
  String _selectedGender = "MALE";
  String _lookingFor = "BOTH";
  final Set<String> _selectedInterests = {"Photography", "Art"};
  double _maxDistanceKm = 25.0;
  RangeValues _ageRange = const RangeValues(20, 28);
  bool _isLoading = false;

  final List<String> _availableInterests = [
    "Photography", "Techno", "Art", "Coffee", "Travel",
    "Running", "Design", "Coding", "Boba", "Electronic",
    "Cooking", "Film", "Gaming", "Yoga", "Music"
  ];

  void _nextStep() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_currentStep) {
        case OnboardingStep.welcome:
          _currentStep = OnboardingStep.nameAndDob;
          break;
        case OnboardingStep.nameAndDob:
          _currentStep = OnboardingStep.genderAndLookingFor;
          break;
        case OnboardingStep.genderAndLookingFor:
          _currentStep = OnboardingStep.interests;
          break;
        case OnboardingStep.interests:
          _currentStep = OnboardingStep.preferences;
          break;
        case OnboardingStep.preferences:
          _currentStep = OnboardingStep.location;
          break;
        case OnboardingStep.location:
          _completeOnboarding();
          break;
      }
    });
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_currentStep) {
        case OnboardingStep.welcome:
          break;
        case OnboardingStep.nameAndDob:
          _currentStep = OnboardingStep.welcome;
          break;
        case OnboardingStep.genderAndLookingFor:
          _currentStep = OnboardingStep.nameAndDob;
          break;
        case OnboardingStep.interests:
          _currentStep = OnboardingStep.genderAndLookingFor;
          break;
        case OnboardingStep.preferences:
          _currentStep = OnboardingStep.interests;
          break;
        case OnboardingStep.location:
          _currentStep = OnboardingStep.preferences;
          break;
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final idToken = auth.idToken;
        if (idToken != null) {
          final res = await ApiClient().googleLogin(idToken);
          if (res.data != null && res.data['accessToken'] != null) {
            await ApiClient().saveToken(res.data['accessToken']);
            if (res.data['onboardingDone'] == true) {
              if (mounted) {
                setState(() => _isLoading = false);
                widget.onOnboardingCompleted();
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[GoogleSignIn] Error or canceled: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _nextStep();
    }
  }

  void _completeOnboarding() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    double lat = 37.7749; // Default fallback
    double lon = -122.4194;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        lat = position.latitude;
        lon = position.longitude;
      }
    } catch (e) {
      debugPrint('[Geolocator] Error fetching position: $e');
    }

    final name = _nameController.text.trim().isEmpty ? 'Explorer' : _nameController.text.trim();
    final dobStr = DateFormat('yyyy-MM-dd').format(_selectedDob);

    try {
      await ApiClient().completeOnboarding({
        'displayName': name,
        'dateOfBirth': dobStr,
        'gender': _selectedGender,
        'lookingFor': _lookingFor,
        'minAge': _ageRange.start.toInt(),
        'maxAge': _ageRange.end.toInt(),
        'maxDistanceKm': _maxDistanceKm.toInt(),
        'genders': [_selectedGender == 'MALE' ? 'FEMALE' : 'MALE'],
        'latitude': lat,
        'longitude': lon,
        'bio': 'Living in the moment 📸',
      });
    } catch (e) {
      debugPrint('[ApiClient] completeOnboarding warning: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    HapticFeedback.mediumImpact();
    widget.onOnboardingCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidMeshBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Back Button & Liquid Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    if (_currentStep != OnboardingStep.welcome)
                      GestureDetector(
                        onTap: _prevStep,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                          child: const Icon(CupertinoIcons.chevron_back, size: 20),
                        ),
                      )
                    else
                      const SizedBox(width: 36),
                    const Spacer(),
                    // Step Progress Dots
                    Row(
                      children: OnboardingStep.values.map((step) {
                        final isPassed = step.index <= _currentStep.index;
                        final isCurrent = step == _currentStep;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isCurrent ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: isPassed
                                ? GlassTheme.snapYellow
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
              ),

              // Dynamic Step View
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.08, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStepContent(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return _buildWelcomeStep(isDark);
      case OnboardingStep.nameAndDob:
        return _buildNameAndDobStep(isDark);
      case OnboardingStep.genderAndLookingFor:
        return _buildGenderStep(isDark);
      case OnboardingStep.interests:
        return _buildInterestsStep(isDark);
      case OnboardingStep.preferences:
        return _buildPreferencesStep(isDark);
      case OnboardingStep.location:
        return _buildLocationStep(isDark);
    }
  }

  Widget _buildWelcomeStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Floating Liquid Glass Logo
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlassTheme.snapYellow,
              boxShadow: [
                BoxShadow(
                  color: GlassTheme.snapYellow.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(CupertinoIcons.flame_fill, color: Colors.black, size: 54),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Welcome to Be-Snap",
            textAlign: TextAlign.center,
            style: GlassTheme.headline(isDark: isDark).copyWith(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            "Discover people nearby through authentic, ephemeral moments.",
            textAlign: TextAlign.center,
            style: GlassTheme.body(isDark: isDark).copyWith(fontSize: 16),
          ),
          const Spacer(),
          // Google Sign-In Glass Button
          LiquidGlassCard(
            borderRadius: 32,
            padding: const EdgeInsets.symmetric(vertical: 4),
            onTap: _isLoading ? null : _signInWithGoogle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const CupertinoActivityIndicator(color: Colors.white)
                else ...[
                  const Icon(CupertinoIcons.globe, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    "Continue with Google",
                    style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 17),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "By continuing, you agree to our Terms & Privacy Policy.",
            textAlign: TextAlign.center,
            style: GlassTheme.caption(isDark: isDark),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNameAndDobStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("What's your name & age?", style: GlassTheme.headline(isDark: isDark)),
          const SizedBox(height: 8),
          Text("Your age will be public. Be-Snap is strictly 18+.", style: GlassTheme.body(isDark: isDark)),
          const SizedBox(height: 28),

          // Name Input
          LiquidGlassCard(
            borderRadius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              style: GlassTheme.body(isDark: isDark).copyWith(fontSize: 17),
              decoration: InputDecoration(
                hintText: "Enter your first name",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Cupertino Date of Birth Picker Wheel
          Text("DATE OF BIRTH", style: GlassTheme.caption(isDark: isDark)),
          const SizedBox(height: 8),
          LiquidGlassCard(
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 150,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: isDark ? Brightness.dark : Brightness.light,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDob,
                  maximumDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                  minimumYear: 1940,
                  maximumYear: DateTime.now().year - 18,
                  onDateTimeChanged: (date) {
                    setState(() => _selectedDob = date);
                  },
                ),
              ),
            ),
          ),
          const Spacer(),
          LiquidGlassButton(
            label: "Continue",
            variant: GlassButtonVariant.primary,
            accentColor: GlassTheme.iosBlue,
            onPressed: _nextStep,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderStep(bool isDark) {
    final genders = ["MALE", "FEMALE", "NON_BINARY"];
    final lookingForOptions = ["FRIENDSHIP", "DATING", "BOTH"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Gender & Intentions", style: GlassTheme.headline(isDark: isDark)),
          const SizedBox(height: 8),
          Text("Help us show you the right people.", style: GlassTheme.body(isDark: isDark)),
          const SizedBox(height: 24),

          Text("I IDENTIFY AS", style: GlassTheme.caption(isDark: isDark)),
          const SizedBox(height: 8),
          Row(
            children: genders.map((g) {
              final isSel = _selectedGender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGender = g);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel ? GlassTheme.snapYellow : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSel ? GlassTheme.snapYellow : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        g == "NON_BINARY" ? "Non-Binary" : g[0] + g.substring(1).toLowerCase(),
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),
          Text("I'M LOOKING FOR", style: GlassTheme.caption(isDark: isDark)),
          const SizedBox(height: 8),
          Column(
            children: lookingForOptions.map((opt) {
              final isSel = _lookingFor == opt;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _lookingFor = opt);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSel ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel ? GlassTheme.iosBlue : Colors.white.withValues(alpha: 0.15),
                      width: isSel ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        opt == "BOTH" ? "Friendship & Dating" : opt[0] + opt.substring(1).toLowerCase(),
                        style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 15),
                      ),
                      if (isSel)
                        const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: GlassTheme.iosBlue, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          LiquidGlassButton(
            label: "Continue",
            variant: GlassButtonVariant.primary,
            accentColor: GlassTheme.iosBlue,
            onPressed: _nextStep,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInterestsStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Pick your interests", style: GlassTheme.headline(isDark: isDark)),
          const SizedBox(height: 8),
          Text("Select at least 3 to match with people of similar vibes.", style: GlassTheme.body(isDark: isDark)),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableInterests.map((interest) {
                  final isSel = _selectedInterests.contains(interest);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isSel) {
                          _selectedInterests.remove(interest);
                        } else {
                          _selectedInterests.add(interest);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? GlassTheme.snapYellow.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel
                              ? GlassTheme.snapYellow
                              : Colors.white.withValues(alpha: 0.2),
                          width: 1.2,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: GlassTheme.snapYellow.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          LiquidGlassButton(
            label: "Continue",
            variant: GlassButtonVariant.primary,
            accentColor: GlassTheme.iosBlue,
            onPressed: _nextStep,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Discovery Radius", style: GlassTheme.headline(isDark: isDark)),
          const SizedBox(height: 8),
          Text("Set how far you want to explore.", style: GlassTheme.body(isDark: isDark)),
          const SizedBox(height: 32),

          LiquidGlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Maximum Distance", style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 16)),
                    Text(
                      "${_maxDistanceKm.toInt()} km",
                      style: const TextStyle(
                        color: GlassTheme.snapYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CupertinoSlider(
                  value: _maxDistanceKm,
                  min: 5,
                  max: 100,
                  activeColor: GlassTheme.snapYellow,
                  onChanged: (val) {
                    setState(() => _maxDistanceKm = val);
                  },
                ),
                const SizedBox(height: 18),
                Divider(color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Age Preference", style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 16)),
                    Text(
                      "${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} yrs",
                      style: const TextStyle(
                        color: GlassTheme.iosBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 60,
                  activeColor: GlassTheme.iosBlue,
                  inactiveColor: Colors.white.withValues(alpha: 0.2),
                  onChanged: (values) {
                    setState(() => _ageRange = values);
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          LiquidGlassButton(
            label: "Continue",
            variant: GlassButtonVariant.primary,
            accentColor: GlassTheme.iosBlue,
            onPressed: _nextStep,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLocationStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlassTheme.iosBlue.withValues(alpha: 0.25),
              border: Border.all(color: GlassTheme.iosBlue, width: 2),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.location_solid, color: GlassTheme.iosBlue, size: 44),
            ),
          ),
          const SizedBox(height: 24),
          Text("Enable Location", style: GlassTheme.headline(isDark: isDark)),
          const SizedBox(height: 12),
          Text(
            "Be-Snap calculates distances to show you genuine profiles nearby. Your precise coordinates are never shared with other users.",
            textAlign: TextAlign.center,
            style: GlassTheme.body(isDark: isDark),
          ),
          const Spacer(),
          LiquidGlassButton(
            label: "Allow Location & Finish",
            isLoading: _isLoading,
            variant: GlassButtonVariant.primary,
            accentColor: GlassTheme.snapYellow,
            onPressed: _completeOnboarding,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
