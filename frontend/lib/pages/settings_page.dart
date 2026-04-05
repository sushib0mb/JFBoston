import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import 'admin/admin_page.dart';
import 'package:share_plus/share_plus.dart';

// import 'theme_notifier.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;
    final double padH = isTablet ? 24 : 8;
    final double padV = isTablet ? 16 : 8;
    final double iconSize = isTablet ? 32 : 24;
    final double titleSize = isTablet ? 20 : 16;
    final double subtitleSize = isTablet ? 18 : 14;
    final double headerSize = isTablet ? 24 : 20;

    // final theme = context.watch<ThemeNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontSize: headerSize)),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        children: [
          // Share this app
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: padH,
              vertical: padV,
            ),
            leading: Icon(Icons.share, size: iconSize),
            title: Text(
              'Share this App',
              style: TextStyle(fontSize: titleSize),
            ),
            onTap: () {
              final iosUrl =
                  'https://apps.apple.com/us/app/jfboston/id6744838556';
              final link = iosUrl;
              Share.share(
                'Check out the JFB Festival app! Download it now and plan your visit:\n$link',
                subject: 'JFB Festival App',
              );
            },
          ),

          // About & Version
          AboutListTile(
            icon: Icon(Icons.info_outline, size: iconSize),
            applicationName: 'JFBoston',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 Boston Japan Community Hub Inc.',
            aboutBoxChildren: [],
            dense: false,
            child: Text('About', style: TextStyle(fontSize: titleSize)),
          ),

          SizedBox(height: padV * 2),

          // Credits header
          Center(
            child: Text(
              'Credits',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: headerSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: padV),

          // Credits list
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Application Development Team',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleSize,
                ),
              ),
              SizedBox(height: padV / 2),
              Text(
                'Taizo Azuchi — Team Leader',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Jordan Lin — Lead Developer',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Soi Hirose — Lead Developer',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Ryusei Okamoto — Developer',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Umi Imai — Developer',
                style: TextStyle(fontSize: subtitleSize),
              ),

              SizedBox(height: padV),
              Text(
                'Application Design Team',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleSize,
                ),
              ),
              SizedBox(height: padV / 2),
              Text(
                'Hiroharu Okabe — UI/UX Designer',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Chikada Hanezu — UI/UX Designer',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Mina Baba — UI/UX Designer',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Hayate Kosuga — Logo Animator',
                style: TextStyle(fontSize: subtitleSize),
              ),

              SizedBox(height: padV),
              Text(
                'Special Thanks To',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleSize,
                ),
              ),
              SizedBox(height: padV / 2),
              Text(
                'Nobuhiro Mitsuoka',
                style: TextStyle(fontSize: subtitleSize),
              ),
              Text(
                'Yoshiatsu Murata',
                style: TextStyle(fontSize: subtitleSize),
              ),

              SizedBox(height: padV * 2),
            ],
          ),

          SizedBox(height: 25),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH + 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Code',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), // Default state
                      focusedBorder: OutlineInputBorder(
                        // Selected/Focused state
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 224, 105, 96),
                          width: 2.0,
                        ),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color.fromARGB(
                      255,
                      69,
                      69,
                      69,
                    ), // Changes the text color to red
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
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

  void _handleSubmit() {
    // Read the text and remove any accidental whitespace
    final String inputCode = _codeController.text.trim().toLowerCase();

    if (inputCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a code.')));
      return;
    }

    // Check the input and execute different logic
    switch (inputCode) {
      case 'jfbadmin':
        // If they type JFBADMIN, show the login dialog
        _showLoginDialog(context);
        break;
      case 'ilovejapan':
        // Show some developer tools or a specific message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Japan loves you too!')));
        break;
      default:
        // Handle invalid or unknown codes
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid code entered.')));
        // Optionally clear the text field
        _codeController.clear();
    }
  }

  void _showLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // TODO: ONLY FOR DEBUG!!! REMOVE BEFORE PRODUCTION!!
    emailController.text = "jfbstudents@gmail.com";
    passwordController.text = "jfbadmin";

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Admin Access'),
            content: Column(
              mainAxisSize:
                  MainAxisSize.min, // Prevents dialog from taking full screen
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
                onPressed: () => Navigator.pop(context), // Closes the dialog
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                // Inside your ElevatedButton in the Dialog
                onPressed: () async {
                  try {
                    // 1. Log in
                    await supabase.auth.signInWithPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );

                    if (context.mounted) {
                      // 2. Close the Login Dialog
                      Navigator.pop(context);

                      // 3. Navigate to the Admin Page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminPage(),
                        ),
                      );
                    }
                  } catch (e) {
                    // Show the error if login fails
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Access Denied: $e")),
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
