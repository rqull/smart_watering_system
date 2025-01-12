import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/plant_state.dart';

class MQTTService {
  static const String broker = 'test.mosquitto.org';
  static const int port = 1883;
  static const String clientIdentifier = 'flutter_client_123';

  late MqttServerClient client;
  final ValueNotifier<PlantState?> currentData =
      ValueNotifier<PlantState?>(null);
  final ValueNotifier<String?> statusMessage = ValueNotifier<String?>(null);
  final ValueNotifier<bool> deviceOnline = ValueNotifier<bool>(false);
  bool _isConnected = false;

  // Timer untuk mengecek last seen
  DateTime? _lastMessageTime;
  static const Duration offlineThreshold = Duration(seconds: 30);

  Future<void> initialize() async {
    print('Initializing MQTT Service...');
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.logging(on: true);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .withWillTopic('plant/status')
        .withWillMessage('Flutter Client Offline')
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain()
        .startClean();
    client.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker: $broker');
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      statusMessage.value = 'Connection failed: $e';
      deviceOnline.value = false;
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      _isConnected = true;
      _setupSubscriptions();
      _setupUpdatesListener();

      // Publish online status
      client.publishMessage(
          'plant/status',
          MqttQos.atLeastOnce,
          MqttClientPayloadBuilder()
              .addString('Flutter Client Online')
              .payload!,
          retain: true);

      // Start periodic check for device online status
      _startDeviceStatusCheck();
    } else {
      print('Connection failed - status is ${client.connectionStatus}');
      statusMessage.value = 'Connection failed: ${client.connectionStatus}';
      deviceOnline.value = false;
      _isConnected = false;
    }
  }

  void _startDeviceStatusCheck() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_lastMessageTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastMessageTime!);
        if (difference > offlineThreshold) {
          deviceOnline.value = false;
          statusMessage.value = 'Device Offline';
        }
      }
      if (_isConnected) {
        _startDeviceStatusCheck();
      }
    });
  }

  void _setupSubscriptions() {
    print('Setting up MQTT subscriptions');
    client.subscribe('plant/moisture', MqttQos.atLeastOnce);
    client.subscribe('plant/pump', MqttQos.atLeastOnce);
    client.subscribe('plant/status', MqttQos.atLeastOnce);
  }

  void _setupUpdatesListener() {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      _lastMessageTime = DateTime.now();
      deviceOnline.value = true;

      final MqttPublishMessage message =
          messages[0].payload as MqttPublishMessage;
      final String topic = messages[0].topic;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received message: $payload on topic: $topic');

      if (topic == 'plant/moisture') {
        try {
          final double moisture = double.parse(payload);
          print('Updating moisture value: $moisture');
          currentData.value = PlantState(
            moisture: moisture,
            isPumpOn: currentData.value?.isPumpOn ?? false,
            timestamp: DateTime.now(),
          );
        } catch (e) {
          print('Error parsing moisture value: $e');
          statusMessage.value = 'Error reading moisture: $e';
        }
      } else if (topic == 'plant/pump') {
        print('Updating pump status: $payload');
        currentData.value = PlantState(
          moisture: currentData.value?.moisture ?? 0.0,
          isPumpOn: payload == 'ON',
          timestamp: DateTime.now(),
        );
      } else if (topic == 'plant/status') {
        print('Received status update: $payload');
        statusMessage.value = payload;
        if (payload.contains('Device Online')) {
          deviceOnline.value = true;
        } else if (payload.contains('Device Offline')) {
          deviceOnline.value = false;
        }
      }
    });
  }

  Future<void> togglePump(bool turnOn) async {
    if (!_isConnected) {
      print('MQTT not connected, cannot toggle pump');
      statusMessage.value = 'Error: Not connected to MQTT';
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
      statusMessage.value = 'Error: Failed to control pump';
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
    _isConnected = true;
    statusMessage.value = 'Connected to MQTT';
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    _isConnected = false;
    deviceOnline.value = false;
    statusMessage.value = 'Disconnected from MQTT';
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void dispose() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Disconnecting from MQTT broker');
      client.disconnect();
    }
  }
}
