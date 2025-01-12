#include <LiquidCrystal_I2C.h>
#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>

#define SOIL_SENSOR 33
#define RELAY_PIN 4

// Konstanta untuk keamanan pompa
const unsigned long MAX_PUMP_ON_TIME = 30000;  // Maksimum 30 detik
const int MAX_MOISTURE = 80;                   // Maksimum 80% moisture
const int MIN_MOISTURE = 20;                   // Minimum 20% moisture
unsigned long pumpStartTime = 0;               // Waktu pompa mulai
bool isPumpRunning = false;                    // Status pompa

// Kalibrasi sensor moisture
const int AIR_VALUE = 4095;    // Nilai saat di udara (kering)
const int WATER_VALUE = 2400;  // Nilai saat di air (basah)

// Array untuk rata-rata pembacaan
const int numReadings = 10;
int readings[numReadings];
int readIndex = 0;
int total = 0;
int average = 0;

// WiFi credentials
const char* ssid = "realme 8";
const char* password = "niggaman";

// MQTT Broker settings
const char* mqtt_server = "test.mosquitto.org";
const int mqtt_port = 1883;
const char* mqtt_client_id = "esp32_plant_123";
const char* mqtt_topic_moisture = "plant/moisture";
const char* mqtt_topic_pump = "plant/pump";
const char* mqtt_topic_status = "plant/status";

// Initialize LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Initialize WiFi and MQTT clients
WiFiClient espClient;
PubSubClient client(espClient);

unsigned long lastMsg = 0;
const long interval = 2000;
unsigned long lastReconnectAttempt = 0;

void initializeRelay() {
  // Pastikan relay mati saat startup
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);  // LOW = Pompa MATI
  isPumpRunning = false;
  
  Serial.println("Relay initialized - Pump OFF");
  lcd.setCursor(0, 1);
  lcd.print("Pump: OFF");
}

void initializeMoistureSensor() {
  pinMode(SOIL_SENSOR, INPUT);
  
  // Initialize readings array
  for (int i = 0; i < numReadings; i++) {
    readings[i] = 0;
  }
  
  Serial.println("Moisture sensor initialized");
}

void setup_wifi() {
  delay(10);
  Serial.println("\nConnecting to WiFi");
  lcd.clear();
  lcd.print("Connecting WiFi");

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    
    lcd.clear();
    lcd.print("WiFi Connected");
    delay(1000);
  } else {
    Serial.println("\nWiFi connection failed!");
    ESP.restart();
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  char message[50];
  memcpy(message, payload, length);
  message[length] = '\0';
  
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);
  Serial.print("Message: ");
  Serial.println(message);
  
  if (strcmp(topic, mqtt_topic_pump) == 0) {
    if (strcmp(message, "ON") == 0 && !isPumpRunning) {
      // Cek moisture sebelum menyalakan pompa
      int moisture = readMoisture();
      if (moisture >= MAX_MOISTURE) {
        Serial.println("Cannot turn on pump: Moisture too high");
        client.publish(mqtt_topic_status, "Pump blocked: Moisture too high", true);
        return;
      }
      
      Serial.println("Turning pump ON");
      digitalWrite(RELAY_PIN, HIGH);  // HIGH = Pompa NYALA
      isPumpRunning = true;
      pumpStartTime = millis();
      
      lcd.setCursor(0, 1);
      lcd.print("Pump: ON ");
      client.publish(mqtt_topic_pump, "ON", true);
    } 
    else if (strcmp(message, "OFF") == 0 && isPumpRunning) {
      Serial.println("Turning pump OFF");
      digitalWrite(RELAY_PIN, LOW);  // LOW = Pompa MATI
      isPumpRunning = false;
      
      lcd.setCursor(0, 1);
      lcd.print("Pump: OFF");
      client.publish(mqtt_topic_pump, "OFF", true);
    }
  }
}

boolean mqttReconnect() {
  if (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    lcd.setCursor(0, 1);
    lcd.print("MQTT Connecting");
    
    // Create a random client ID
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);
    
    // Attempt to connect with last will message
    if (client.connect(clientId.c_str(), NULL, NULL, mqtt_topic_status, 0, true, "Device Offline")) {
      Serial.println("connected");
      lcd.setCursor(0, 1);
      lcd.print("MQTT Connected ");
      
      // Subscribe to pump control topic
      client.subscribe(mqtt_topic_pump);
      
      // Publish initial states
      client.publish(mqtt_topic_status, "Device Online", true);
      client.publish(mqtt_topic_pump, "OFF", true);  // Pastikan status pompa OFF
      
      return true;
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retry in 5 seconds");
      lcd.setCursor(0, 1);
      lcd.print("MQTT Failed   ");
      return false;
    }
  }
  return true;
}

void setup() {
  Serial.begin(115200);
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.print("Initializing...");
  
  // Initialize relay first
  initializeRelay();
  
  // Initialize soil sensor
  initializeMoistureSensor();
  
  // Setup WiFi
  setup_wifi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  client.setKeepAlive(60);
  
  // Generate random seed for client ID
  randomSeed(micros());
  
  // Initial MQTT connection
  mqttReconnect();
  
  lcd.clear();
  lcd.print("System Ready");
  Serial.println("System initialization complete");
}

void checkWiFiConnection() {
  static bool wasConnected = false;
  bool isConnected = WiFi.status() == WL_CONNECTED;
  
  // Jika status berubah
  if (wasConnected != isConnected) {
    wasConnected = isConnected;
    if (isConnected) {
      Serial.println("WiFi reconnected");
      lcd.setCursor(0, 0);
      lcd.print("WiFi: Connected ");
      
      // Reconnect MQTT jika WiFi terhubung kembali
      if (!client.connected()) {
        mqttReconnect();
      }
    } else {
      Serial.println("WiFi connection lost");
      lcd.setCursor(0, 0);
      lcd.print("WiFi: Lost     ");
    }
  }
}

void loop() {
  // Cek koneksi WiFi
  checkWiFiConnection();
  
  if (!client.connected()) {
    unsigned long now = millis();
    if (now - lastReconnectAttempt > 5000) {
      lastReconnectAttempt = now;
      // Attempt to reconnect
      if (mqttReconnect()) {
        lastReconnectAttempt = 0;
      }
    }
  } else {
    client.loop();
    
    // Check pump safety
    checkPumpSafety();
    
    // Regular updates
    unsigned long now = millis();
    if (now - lastMsg > interval) {
      lastMsg = now;
      readAndPublishMoisture();
      
      // Publish device status
      client.publish(mqtt_topic_status, "Device Online", true);
    }
  }
}

int readMoisture() {
  // Hapus nilai lama dari total
  total = total - readings[readIndex];
  
  // Baca nilai analog
  readings[readIndex] = analogRead(SOIL_SENSOR);
  
  // Tambahkan nilai baru ke total
  total = total + readings[readIndex];
  
  // Lanjut ke posisi berikutnya di array
  readIndex = readIndex + 1;
  
  // Kembali ke awal jika di akhir array
  if (readIndex >= numReadings) {
    readIndex = 0;
  }
  
  // Hitung rata-rata
  average = total / numReadings;
  
  // Konversi ke persentase (0-100%)
  int moisturePercent = map(average, AIR_VALUE, WATER_VALUE, 0, 100);
  moisturePercent = constrain(moisturePercent, 0, 100);
  
  return moisturePercent;
}

void checkPumpSafety() {
  if (!isPumpRunning) return;
  
  // Baca moisture level
  int moisture = readMoisture();
  
  // Cek waktu
  unsigned long currentTime = millis();
  unsigned long pumpDuration = currentTime - pumpStartTime;
  
  bool shouldStopPump = false;
  String reason = "";
  
  // Cek kondisi untuk mematikan pompa
  if (pumpDuration >= MAX_PUMP_ON_TIME) {
    shouldStopPump = true;
    reason = "Max time reached";
  }
  else if (moisture >= MAX_MOISTURE) {
    shouldStopPump = true;
    reason = "Max moisture reached";
  }
  
  // Matikan pompa jika diperlukan
  if (shouldStopPump) {
    digitalWrite(RELAY_PIN, LOW);  // LOW = Pompa MATI
    isPumpRunning = false;
    
    // Update LCD
    lcd.setCursor(0, 1);
    lcd.print("Pump: OFF (Safe)");
    
    // Kirim status ke MQTT
    String status = "Pump turned off: " + reason;
    client.publish(mqtt_topic_status, status.c_str(), true);
    client.publish(mqtt_topic_pump, "OFF", true);
    
    Serial.println(status);
  }
}

void readAndPublishMoisture() {
  int moisture = readMoisture();
  
  // Update LCD
  lcd.setCursor(0, 0);
  lcd.print("Moisture: ");
  lcd.print(moisture);
  lcd.print("%   ");
  
  // Publish ke MQTT
  char moistureStr[8];
  dtostrf(moisture, 1, 2, moistureStr);
  client.publish(mqtt_topic_moisture, moistureStr, true);
  
  // Cek status kelembapan
  if (moisture < MIN_MOISTURE) {
    client.publish(mqtt_topic_status, "Warning: Low moisture", true);
    lcd.setCursor(0, 1);
    lcd.print("Status: KERING ");
  } else if (moisture > MAX_MOISTURE) {
    client.publish(mqtt_topic_status, "Warning: High moisture", true);
    lcd.setCursor(0, 1);
    lcd.print("Status: BASAH  ");
  } else {
    lcd.setCursor(0, 1);
    lcd.print("Status: IDEAL  ");
  }
}
