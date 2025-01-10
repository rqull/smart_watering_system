import 'package:flutter/material.dart';
import '../../models/plant_state.dart';

class MoistureCard extends StatelessWidget {
  final PlantState state;

  const MoistureCard({
    Key? key,
    required this.state,
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
              'Kelembaban Tanah',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: state.moisture / 100,
                    strokeWidth: 15,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                Text(
                  '${state.moisture.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
