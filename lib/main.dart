import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/plant_controller.dart';
import 'controllers/theme_controller.dart';
import 'services/mqtt_service.dart';
import 'views/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeController(prefs: prefs),
        ),
        Provider<MQTTService>(
          create: (_) {
            final mqttService = MQTTService();
            mqttService.initialize();
            return mqttService;
          },
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider<PlantController>(
          create: (context) => PlantController(
            mqttService: context.read<MQTTService>(),
          ),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            showSemanticsDebugger: false,
            debugShowCheckedModeBanner: false,
            title: 'Smart Watering',
            theme: themeController.currentTheme,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
