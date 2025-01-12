# Smart Watering System

A smart plant watering system built with ESP32 microcontroller and Flutter mobile application. This system monitors soil moisture levels and controls a water pump automatically to maintain optimal plant hydration.

## Features

- 🌱 Real-time soil moisture monitoring
- 💧 Automatic and manual pump control
- 🌙 Dark/Light theme support
- 📱 Mobile app interface
- 📊 Status monitoring and notifications
- 🔌 WiFi connectivity status
- 🔄 MQTT communication

## Hardware Requirements

- ESP32 Development Board
- Soil Moisture Sensor
- Relay Module
- Water Pump
- LCD Display (I2C)
- Power Supply
- Jumper Wires

## Software Requirements

- Flutter SDK
- Arduino IDE
- MQTT Broker (test.mosquitto.org)
- Required Libraries:
  - ESP32 Arduino Core
  - PubSubClient
  - LiquidCrystal_I2C
  - Wire

## Installation

### ESP32 Setup

1. Install Arduino IDE and ESP32 board support
2. Install required libraries:
   ```
   - PubSubClient
   - LiquidCrystal_I2C
   - Wire
   ```
3. Open `lib/esp32/smart_plant_watering/smart_plant_watering.ino`
4. Configure WiFi credentials
5. Upload to ESP32

### Flutter App Setup

1. Install Flutter SDK
2. Clone this repository
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── controllers/     # State management
├── models/          # Data models
├── services/        # MQTT service
├── views/           # UI components
└── esp32/          # ESP32 Arduino code
```

## Configuration

### MQTT Settings

- Broker: test.mosquitto.org
- Port: 1883
- Topics:
  - plant/moisture
  - plant/pump
  - plant/status

### Soil Moisture Calibration

- Air Value: 4095 (dry)
- Water Value: 2400 (wet)

## Features in Development

- [ ] Historical data logging
- [ ] Multiple plant support
- [ ] Customizable watering schedules
- [ ] Weather integration

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- ESP32 community for their support
- MQTT community for the messaging protocol
