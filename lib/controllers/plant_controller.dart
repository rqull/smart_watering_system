import 'package:flutter/foundation.dart';
import '../models/plant_state.dart';
import '../services/mqtt_service.dart';

class PlantController extends ChangeNotifier {
  final MQTTService _mqttService;
  PlantState _state = PlantState.initial();

  PlantController(this._mqttService) {
    _initialize();
  }

  PlantState get state => _state;

  Future<void> _initialize() async {
    await _mqttService.initialize();
    _mqttService.currentData.addListener(_updateState);
  }

  void _updateState() {
    final data = _mqttService.currentData.value;
    if (data != null) {
      _state = PlantState(
        moisture: data.moisture,
        timestamp: data.timestamp,
        isPumpOn: data.isPumpOn,
      );
      notifyListeners();
    }
  }

  void togglePump(bool value) {
    _mqttService.togglePump(value);
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
    _mqttService.currentData.removeListener(_updateState);
    _mqttService.dispose();
    super.dispose();
  }
}
