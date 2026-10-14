import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Lock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Application> apps = [];
  Set<String> lockedApps = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await DeviceApps.getInstalledApplications(
      onlyAppsWithLaunchIntent: true,
      includeSystemApps: false,
      includeAppIcons: true,
    );
    list.sort((a, b) =>
        a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    lockedApps = (prefs.getStringList('locked') ?? []).toSet();

    setState(() {
      apps = list;
      loading = false;
    });
  }

  Future<void> _toggle(String pkg, bool val) async {
    setState(() {
      if (val) {
        lockedApps.add(pkg);
      } else {
        lockedApps.remove(pkg);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('locked', lockedApps.toList());
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Simple Lock"),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: apps.length,
        itemBuilder: (context, i) {
          final app = apps[i];
          final isLocked = lockedApps.contains(app.packageName);
          return ListTile(
            leading: app is ApplicationWithIcon
                ? Image.memory(app.icon, width: 40, height: 40)
                : const Icon(Icons.apps),
            title: Text(app.appName),
            trailing: Switch(
              value: isLocked,
              activeColor: Colors.green,
              onChanged: (val) => _toggle(app.packageName, val),
            ),
          );
        },
      ),
    );
  }
}
