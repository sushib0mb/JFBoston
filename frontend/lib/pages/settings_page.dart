// =============================================================================
// settings_page.dart
//
// Application settings screen for the JFBoston festival app.
//
// Features:
//   - Share button: opens the native share sheet with the App Store link
//   - About dialog: shows app name, version, and legal information
//   - Credits section: lists the full development and design team
//   - Admin code entry: hidden code field that triggers a login dialog to
//     access the AdminPage (Supabase-authenticated)
//   - Fixed layout constants: all sizing defined as static const — no
//     MediaQuery math or isTablet checks
//
// Dependencies:
//   - share_plus       : native share sheet
//   - supabase_config  : Supabase client singleton
//   - admin/admin_page : admin dashboard (accessed via code + login)
// =============================================================================

import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import 'admin/admin_page.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ── Fixed layout constants ─────────────────────────────────────────────────
  static const double _padH = 8.0;
  static const double _padV = 8.0;
  static const double _iconSize = 24.0;
  static const double _titleSize = 16.0;
  static const double _subtitleSize = 14.0;
  static const double _headerSize = 20.0;
  static const double _codeSectionHPad = 12.5; // _padH + 30
  static const double _codeRowSpacing = 16.0;
  static const double _codeFieldHPad = 12.0;
  static const double _codeFieldVPad = 12.0;
  static const double _submitBtnRadius = 4.0;
  static const double _sectionGap = 25.0;
  static const double _borderWidth = 1.0;
  // ──────────────────────────────────────────────────────────────────────────

  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: _headerSize)),
        backgroundColor: const Color(0xFFECE0CF),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        children: [
          // ── Share this app ───────────────────────────────────────────────
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: _padH,
              vertical: _padV,
            ),
            leading: const Icon(Icons.share, size: _iconSize),
            title: const Text(
              'Share this App',
              style: TextStyle(fontSize: _titleSize),
            ),
            onTap: () {
              const iosUrl =
                  'https://apps.apple.com/us/app/jfboston/id6744838556';
              Share.share(
                'Check out the JFB Festival app! Download it now and plan your visit:\n$iosUrl',
                subject: 'JFB Festival App',
              );
            },
          ),

          // ── About & version ──────────────────────────────────────────────
          const AboutListTile(
            icon: Icon(Icons.info_outline, size: _iconSize),
            applicationName: 'JFBoston',
            applicationVersion: '2.0.0',
            applicationLegalese: '© 2026 Boston Japan Community Hub Inc.',
            aboutBoxChildren: [],
            dense: false,
            child: Text('About', style: TextStyle(fontSize: _titleSize)),
          ),

          SizedBox(height: _padV * 2),

          // ── Credits header ───────────────────────────────────────────────
          const Center(
            child: Text(
              'Credits',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _headerSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: _padV),

          // ── Credits list ─────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'Application Development Team',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _titleSize,
                ),
              ),
              SizedBox(height: _padV / 2),
              Text(
                'Taizo Azuchi — Team Leader',
                style: TextStyle(fontSize: _subtitleSize),
              ),
              Text(
                'Jordan Lin — Lead Developer',
                style: TextStyle(fontSize: _subtitleSize),
              ),
              Text(
                'Soi Hirose — Lead Developer',
                style: TextStyle(fontSize: _subtitleSize),
              ),
              Text(
                'Umi Imai — Developer',
                style: TextStyle(fontSize: _subtitleSize),
              ),

              SizedBox(height: _padV),
              Text(
                'Application Design Team',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _titleSize,
                ),
              ),
              SizedBox(height: _padV / 2),
              Text(
                'Hiroharu Okabe — UI/UX Designer',
                style: TextStyle(fontSize: _subtitleSize),
              ),
              Text(
                'Chikada Hanezu — UI/UX Designer',
                style: TextStyle(fontSize: _subtitleSize),
              ),
              Text(
                'Mina Baba — UI/UX Designer',
                style: TextStyle(fontSize: _subtitleSize),
              ),
              Text(
                'Hayate Kosuga — Logo Animator',
                style: TextStyle(fontSize: _subtitleSize),
              ),

              SizedBox(height: _padV),
              Text(
                'Special Thanks To',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _titleSize,
                ),
              ),
              SizedBox(height: _padV / 2),
              Text(
                'Nobuhiro Mitsuoka',
                style: TextStyle(fontSize: _subtitleSize),
              ),
              Text(
                'Yoshiatsu Murata',
                style: TextStyle(fontSize: _subtitleSize),
              ),

              SizedBox(height: _padV * 2),
            ],
          ),

          const SizedBox(height: _sectionGap),

          // Code entry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _codeSectionHPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Code',
                  style: TextStyle(
                    fontSize: _titleSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: _codeRowSpacing),
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 224, 105, 96),
                          width: _borderWidth,
                        ),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _codeFieldHPad,
                        vertical: _codeFieldVPad,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _codeRowSpacing),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 69, 69, 69),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_submitBtnRadius),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Handles the admin code submission and routes to the appropriate action
  // ---------------------------------------------------------------------------
  void _handleSubmit() {
    // TODO: TESTING PURPOSES ONLY — replace with _codeController.text.trim().toLowerCase() before production
    const String inputCode = 'jfbadmin';

    if (inputCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a code.')));
      return;
    }

    switch (inputCode) {
      case 'jfbadmin':
        _showLoginDialog(context);
        break;
      case 'ilovejapan':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Japan loves you too!')));
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid code entered.')));
        _codeController.clear();
    }
  }

  // ---------------------------------------------------------------------------
  // Shows the admin login dialog and navigates to AdminPage on success
  // ---------------------------------------------------------------------------
  void _showLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // TODO: ONLY FOR DEBUG — remove pre-filled credentials before production
    emailController.text = 'jfbstudents@gmail.com';
    passwordController.text = 'jfbadmin';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Admin Access'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await supabase.auth.signInWithPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminPage(),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Access Denied: $e')),
                    );
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
    );
  }
}
