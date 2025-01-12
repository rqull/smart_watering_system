import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/plant_state.dart';
import '../services/mqtt_service.dart';

class PlantController extends ChangeNotifier {
  final MQTTService mqttService;
  PlantState _state =
      PlantState(moisture: 0.0, isPumpOn: false, timestamp: DateTime.now());

  PlantController({required this.mqttService}) {
    mqttService.currentData.addListener(_updateState);
    mqttService.statusMessage.addListener(_handleStatusMessage);
  }

  PlantState get state => _state;

  void _updateState() {
    final newData = mqttService.currentData.value;
    if (newData != null) {
      _state = newData;
      notifyListeners();
    }
  }

  void _handleStatusMessage() {
    final message = mqttService.statusMessage.value;
    if (message != null && message.isNotEmpty) {
      // Tampilkan toast untuk pesan status tertentu
      if (message.contains("Moisture too high")) {
        _showToast(
            "Tidak dapat menyalakan pompa: Kelembaban tanah terlalu tinggi!");
      } else if (message.contains("Low moisture")) {
        _showToast("Peringatan: Kelembaban tanah rendah!");
      } else if (message.contains("Max time reached")) {
        _showToast("Pompa dimatikan: Batas waktu tercapai");
      }
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future<void> togglePump(bool turnOn) async {
    if (turnOn && _state.moisture >= 80) {
      _showToast(
          "Tidak dapat menyalakan pompa: Kelembaban tanah sudah di atas 80%!");
      return;
    }
    await mqttService.togglePump(turnOn);
  }

  String getMoistureStatus() {
    if (_state.moisture < 30) {
      return 'Tanah terlalu kering!';
    } else if (_state.moisture < 70) {
      return 'Kelembaban optimal';
    } else {
      return 'Tanah terlalu basah!';
    }
  }

  @override
  void dispose() {
    mqttService.currentData.removeListener(_updateState);
    mqttService.statusMessage.removeListener(_handleStatusMessage);
    mqttService.dispose();
    super.dispose();
  }
}
