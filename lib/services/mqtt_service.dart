import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';
import '../models/plant_data.dart';

class MQTTService {
  static const String broker = 'test.mosquitto.org';
  static const int port = 1883;
  static const String clientIdentifier = 'flutter_client_123';

  late MqttServerClient client;
  final ValueNotifier<PlantData?> currentData = ValueNotifier<PlantData?>(null);

  Future<void> initialize() async {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      _subscribeToTopic('plant/moisture');
      _subscribeToTopic('plant/pump');
    }
  }

  void _onDisconnected() {
    print('MQTT client disconnected');
  }

  void _onConnected() {
    print('MQTT client connected');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage message =
          messages[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      if (topic == 'plant/moisture') {
        final double moisture = double.parse(payload);
        currentData.value = PlantData(
          moisture: moisture,
          timestamp: DateTime.now(),
          isPumpOn: currentData.value?.isPumpOn ?? false,
        );
      } else if (topic == 'plant/pump') {
        final bool isPumpOn = payload == 'ON';
        if (currentData.value != null) {
          currentData.value = PlantData(
            moisture: currentData.value!.moisture,
            timestamp: currentData.value!.timestamp,
            isPumpOn: isPumpOn,
          );
        }
      }
    });
  }

  void togglePump(bool turnOn) {
    final String message = turnOn ? 'ON' : 'OFF';
    client.publishMessage(
      'plant/pump',
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(message).payload!,
    );
  }

  void dispose() {
    client.disconnect();
  }
}
