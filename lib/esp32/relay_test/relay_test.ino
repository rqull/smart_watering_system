#define RELAY_PIN 4

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  
  // Pastikan relay mati saat mulai
  digitalWrite(RELAY_PIN, HIGH);
  
  Serial.println("Relay Test - Basic");
  Serial.println("Pin 4 -> Relay Input");
  Serial.println("5V  -> Relay VCC");
  Serial.println("GND -> Relay GND");
}

void loop() {
  // Nyalakan relay (LOW)
  Serial.println("\nMencoba menyalakan relay...");
  digitalWrite(RELAY_PIN, LOW);
  delay(2000);

  // Matikan relay (HIGH)
  Serial.println("Mencoba mematikan relay...");
  digitalWrite(RELAY_PIN, HIGH);
  delay(2000);
}
