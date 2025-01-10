import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';
import '../models/plant_state.dart';

class MQTTService {
  static const String broker = 'test.mosquitto.org';
  static const int port = 1883;
  static const String clientIdentifier = 'flutter_client_123';

  late MqttServerClient client;
  final ValueNotifier<PlantState?> currentData =
      ValueNotifier<PlantState?>(null);
  bool _isConnected = false;

  Future<void> initialize() async {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    try {
      await client.connect();
      _isConnected = true;
      print('MQTT Connected');
    } catch (e) {
      print('Exception: $e');
      _isConnected = false;
      client.disconnect();
    }

    if (_isConnected) {
      print('Subscribing to topics...');
      _subscribeToTopics();
      _setupUpdatesListener();
    }
  }

  void _setupUpdatesListener() {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage message =
          messages[0].payload as MqttPublishMessage;
      final String topic = messages[0].topic;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received message: $payload on topic: $topic');

      if (topic == 'plant/moisture') {
        try {
          final double moisture = double.parse(payload);
          currentData.value = PlantState(
            moisture: moisture,
            timestamp: DateTime.now(),
            isPumpOn: currentData.value?.isPumpOn ?? false,
          );
        } catch (e) {
          print('Error parsing moisture value: $e');
        }
      } else if (topic == 'plant/pump') {
        final bool isPumpOn = payload == 'ON';
        if (currentData.value != null) {
          currentData.value = PlantState(
            moisture: currentData.value!.moisture,
            timestamp: DateTime.now(),
            isPumpOn: isPumpOn,
          );
        }
      }
    });
  }

  void _subscribeToTopics() {
    client.subscribe('plant/moisture', MqttQos.atLeastOnce);
    client.subscribe('plant/pump', MqttQos.atLeastOnce);
    print('Subscribed to topics');
  }

  void _onDisconnected() {
    print('MQTT Disconnected');
    _isConnected = false;
    _reconnect();
  }

  void _onConnected() {
    print('MQTT Connected');
    _isConnected = true;
    _subscribeToTopics();
  }

  void _onSubscribed(String topic) {
    print('Subscribed to: $topic');
  }

  Future<void> _reconnect() async {
    while (!_isConnected) {
      try {
        await client.connect();
        _isConnected = true;
        print('MQTT Reconnected');
        _subscribeToTopics();
      } catch (e) {
        print('Reconnection failed: $e');
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  void togglePump(bool turnOn) {
    if (!_isConnected) {
      print('MQTT not connected. Attempting to reconnect...');
      _reconnect();
      return;
    }

    try {
      final String message = turnOn ? 'ON' : 'OFF';
      print('Sending pump command: $message');

      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      client.publishMessage(
        'plant/pump',
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );

      print('Pump command sent successfully');
    } catch (e) {
      print('Error sending pump command: $e');
    }
  }

  void dispose() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
    }
  }
}
