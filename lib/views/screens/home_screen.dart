import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/plant_controller.dart';
import '../widgets/moisture_card.dart';
import '../widgets/pump_control_card.dart';
import '../widgets/status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Plant Watering'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<PlantController>(
        builder: (context, controller, child) {
          final state = controller.state;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoistureCard(state: state),
                const SizedBox(height: 16),
                PumpControlCard(
                  state: state,
                  onPumpToggle: controller.togglePump,
                ),
                const SizedBox(height: 16),
                StatusCard(
                  state: state,
                  controller: controller,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
