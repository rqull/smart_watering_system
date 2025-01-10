import 'package:flutter/material.dart';
import '../../models/plant_state.dart';

class PumpControlCard extends StatelessWidget {
  final PlantState state;
  final Function(bool) onPumpToggle;

  const PumpControlCard({
    Key? key,
    required this.state,
    required this.onPumpToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Kontrol Pompa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Switch(
              value: state.isPumpOn,
              onChanged: onPumpToggle,
            ),
            Text(
              state.isPumpOn ? 'Pompa AKTIF' : 'Pompa MATI',
              style: TextStyle(
                color: state.isPumpOn ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
