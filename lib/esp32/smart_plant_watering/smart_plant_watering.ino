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
const char* mqtt_server = "test.mosquitto.org";
const int mqtt_port = 1883;
const char* mqtt_client_id = "esp32_plant_123";
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
  // Membuat string dari payload
  char message[50];
  memcpy(message, payload, length);
  message[length] = '\0';
  
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);
  Serial.print("Message: ");
  Serial.println(message);
  
  // Periksa topic pompa
  if (strcmp(topic, mqtt_topic_pump) == 0) {
    if (strcmp(message, "ON") == 0) {
      Serial.println("Attempting to turn pump ON");
      Serial.print("Relay pin state before: ");
      Serial.println(digitalRead(RELAY_PIN));
      
      digitalWrite(RELAY_PIN, LOW);  // Nyalakan pompa
      delay(100);  // Tunggu sebentar
      
      Serial.print("Relay pin state after: ");
      Serial.println(digitalRead(RELAY_PIN));
      
      lcd.setCursor(0, 1);
      lcd.print("Pump: ON ");
      Serial.println("Pump turned ON");
      
      // Kirim konfirmasi status pompa
      client.publish(mqtt_topic_pump, "ON", true);
    } 
    else if (strcmp(message, "OFF") == 0) {
      Serial.println("Attempting to turn pump OFF");
      Serial.print("Relay pin state before: ");
      Serial.println(digitalRead(RELAY_PIN));
      
      digitalWrite(RELAY_PIN, HIGH); // Matikan pompa
      delay(100);  // Tunggu sebentar
      
      Serial.print("Relay pin state after: ");
      Serial.println(digitalRead(RELAY_PIN));
      
      lcd.setCursor(0, 1);
      lcd.print("Pump: OFF");
      Serial.println("Pump turned OFF");
      
      // Kirim konfirmasi status pompa
      client.publish(mqtt_topic_pump, "OFF", true);
    }
  }
}

void reconnect() {
  int retries = 0;
  while (!client.connected() && retries < 5) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect(mqtt_client_id)) {
      Serial.println("connected");
      
      // Subscribe ke topic pump
      client.subscribe(mqtt_topic_pump);
      Serial.println("Subscribed to pump control topic");
      
      // Publish status awal pompa
      client.publish(mqtt_topic_pump, "OFF", true);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 5 seconds");
      retries++;
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  
  // Initialize pins dengan debug
  Serial.println("Initializing relay pin...");
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);  // Matikan pompa saat startup
  Serial.print("Initial relay pin state: ");
  Serial.println(digitalRead(RELAY_PIN));
  
  pinMode(SOIL_SENSOR, INPUT);
  
  // Setup WiFi
  setup_wifi();
  
  // Setup MQTT
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
  
  // Publish moisture value dengan retained flag
  client.publish(mqtt_topic_moisture, moistureStr, true);
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
