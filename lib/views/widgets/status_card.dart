import 'package:flutter/material.dart';
import '../../models/plant_state.dart';
import '../../controllers/plant_controller.dart';

class StatusCard extends StatelessWidget {
  final PlantState state;
  final PlantController controller;

  const StatusCard({
    Key? key,
    required this.state,
    required this.controller,
  }) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Sistem',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pembaruan Terakhir: ${_formatDateTime(state.timestamp)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${controller.getMoistureStatus()}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
