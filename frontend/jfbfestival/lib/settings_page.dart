import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;

// import 'theme_notifier.dart';
import 'pages/survey/survey_page.dart';
import 'providers/reminder_provider.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
    final reminderProv = context.watch<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontSize: headerSize)),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        children: [
          // Event reminders
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: padH,
              vertical: padV,
            ),
            title: Text(
              'Event Reminders',
              style: TextStyle(fontSize: titleSize),
            ),
            subtitle: Text(
              reminderProv.enabled ? 'On' : 'Off',
              style: TextStyle(fontSize: subtitleSize),
            ),
            value: reminderProv.enabled,
            onChanged: (newVal) async {
              await reminderProv.toggle(context);
            },
          ),

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

          // Fill Out Survey
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: padH,
              vertical: padV,
            ),
            leading: Icon(Icons.poll, size: iconSize),
            title: Text(
              'Fill Out Survey',
              style: TextStyle(fontSize: titleSize),
            ),
            onTap: () => Navigator.pushNamed(context, SurveyPage.routeName),
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
        ],
      ),
    );
  }
}
