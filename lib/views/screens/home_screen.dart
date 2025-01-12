import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/plant_controller.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/moisture_card.dart';
import '../widgets/pump_control_card.dart';
import '../widgets/status_card.dart';
import '../widgets/connection_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Watering'),
        actions: [
          IconButton(
            icon: Icon(
              themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: themeController.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Consumer<PlantController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ConnectionStatusCard(),
                  const SizedBox(height: 16),
                  MoistureCard(state: controller.state),
                  const SizedBox(height: 16),
                  PumpControlCard(
                    state: controller.state,
                    onPumpToggle: controller.togglePump,
                  ),
                  const SizedBox(height: 16),
                  StatusCard(
                    state: controller.state,
                    controller: controller,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
