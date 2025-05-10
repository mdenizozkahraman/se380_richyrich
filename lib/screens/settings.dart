import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:se380_richyrich/providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              settings.getText('settings'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[900]!, Colors.blue[900]!],
                ),
              ),
            ),
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(settings.getText('language')),
                subtitle: Text(settings.language),
                leading: const Icon(Icons.language),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(settings.getText('language')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(settings.getText('english')),
                            onTap: () {
                              settings.setLanguage('English');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text(settings.getText('turkish')),
                            onTap: () {
                              settings.setLanguage('Türkçe');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: Text(settings.getText('currency')),
                subtitle: Text(settings.currency),
                leading: const Icon(Icons.currency_exchange),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(settings.getText('currency')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(settings.getText('try')),
                            onTap: () {
                              settings.setCurrency('TRY');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text(settings.getText('usd')),
                            onTap: () {
                              settings.setCurrency('USD');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text(settings.getText('eur')),
                            onTap: () {
                              settings.setCurrency('EUR');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: Text(settings.getText('help')),
                leading: const Icon(Icons.help_outline),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(settings.getText('help')),
                      content: SingleChildScrollView(
                        child: Text(settings.getText('helpContent')),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(settings.getText('close')),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              // SwitchListTile(
              //   title: Text(settings.getText('darkMode')),
              //   secondary: const Icon(Icons.dark_mode),
              //   value: settings.isDarkMode,
              //   onChanged: (bool value) {
              //     settings.toggleDarkMode();
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}