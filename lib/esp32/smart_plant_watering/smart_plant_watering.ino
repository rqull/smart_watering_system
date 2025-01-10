#include <LiquidCrystal_I2C.h>
#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>

#define SOIL_SENSOR 33
#define RELAY_PIN 4

// WiFi credentials
const char* ssid = "mautauajaniorang";
const char* password = "Garuda Skip";

// MQTT Broker settings
const char* mqtt_server = "test.mosquitto.org";  // Broker MQTT publik yang lebih stabil
const int mqtt_port = 1883;
const char* mqtt_client_id = "esp32_plant_123";  // ID unik untuk client
const char* mqtt_topic_moisture = "plant/moisture";
const char* mqtt_topic_pump = "plant/pump";

// Initialize LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Initialize WiFi and MQTT clients
WiFiClient espClient;
PubSubClient client(espClient);

unsigned long lastMsg = 0;
const long interval = 2000;  // Send data every 2 seconds

void setup_wifi() {
  delay(10);
  Serial.println("\nConnecting to WiFi");
  lcd.setCursor(0, 0);
  lcd.print("Connecting WiFi");

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  
  lcd.clear();
  lcd.print("WiFi Connected");
  delay(1000);
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("Message received on topic: ");
  Serial.println(topic);
  Serial.print("Message: ");
  Serial.println(message);
  
  if (String(topic) == mqtt_topic_pump) {
    if (message == "ON") {
      digitalWrite(RELAY_PIN, LOW);
      lcd.setCursor(0, 1);
      lcd.print("Pump: ON ");
      Serial.println("Pump turned ON");
    } else {
      digitalWrite(RELAY_PIN, HIGH);
      lcd.setCursor(0, 1);
      lcd.print("Pump: OFF");
      Serial.println("Pump turned OFF");
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    if (client.connect(mqtt_client_id)) {
      Serial.println("connected");
      client.subscribe(mqtt_topic_pump);
      Serial.println("Subscribed to pump control topic");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 5 seconds");
      // Tambahan debug info
      switch(client.state()) {
        case -4: Serial.println("Connection timeout"); break;
        case -3: Serial.println("Connection lost"); break;
        case -2: Serial.println("Connection failed"); break;
        case -1: Serial.println("Connection disconnected"); break;
      }
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  
  // Initialize pins
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);  // Turn off pump initially
  pinMode(SOIL_SENSOR, INPUT);
  
  // Setup WiFi and MQTT
  setup_wifi();
  
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  
  lcd.clear();
  lcd.print("System Ready");
  Serial.println("System initialization complete");
}

void readAndPublishMoisture() {
  int value = analogRead(SOIL_SENSOR);
  value = map(value, 0, 4095, 0, 100);
  value = (value - 100) * -1;
  
  char moistureStr[8];
  dtostrf(value, 1, 2, moistureStr);
  
  client.publish(mqtt_topic_moisture, moistureStr);
  Serial.print("Published moisture value: ");
  Serial.println(moistureStr);
  
  lcd.setCursor(0, 0);
  lcd.print("Moisture: ");
  lcd.print(value);
  lcd.print("%  ");
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();
  if (now - lastMsg > interval) {
    lastMsg = now;
    readAndPublishMoisture();
  }
}
