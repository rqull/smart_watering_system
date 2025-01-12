#include <LiquidCrystal_I2C.h>
#include <Wire.h>

#define SOIL_SENSOR 33  // Pin sensor kelembapan

// Kalibrasi sensor (disesuaikan dengan pembacaan aktual)
const int AIR_VALUE = 4095;    // Nilai saat di udara (kering) - nilai maksimum ESP32
const int WATER_VALUE = 2400;  // Nilai saat di air (basah) - dari pembacaan Anda

// Initialize LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Array untuk rata-rata pembacaan
const int numReadings = 10;
int readings[numReadings];
int readIndex = 0;
int total = 0;
int average = 0;

void setup() {
  Serial.begin(115200);
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.print("Moisture Sensor");
  lcd.setCursor(0, 1);
  lcd.print("Calibrating...");
  
  // Initialize sensor pin
  pinMode(SOIL_SENSOR, INPUT);
  
  // Initialize readings array
  for (int i = 0; i < numReadings; i++) {
    readings[i] = 0;
  }
  
  delay(2000);
  
  // Tampilkan nilai kalibrasi
  Serial.println("Calibration Values:");
  Serial.print("AIR_VALUE (0%): ");
  Serial.println(AIR_VALUE);
  Serial.print("WATER_VALUE (100%): ");
  Serial.println(WATER_VALUE);
  Serial.println("-------------------");
}

void loop() {
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
  
  // Tampilkan di Serial Monitor
  Serial.print("Raw Value: ");
  Serial.print(average);
  Serial.print(" | Moisture: ");
  Serial.print(moisturePercent);
  Serial.print("% | Status: ");
  
  // Tentukan status kelembapan
  if (moisturePercent < 20) {
    Serial.println("KERING");
  } else if (moisturePercent < 40) {
    Serial.println("AGAK KERING");
  } else if (moisturePercent < 60) {
    Serial.println("IDEAL");
  } else if (moisturePercent < 80) {
    Serial.println("LEMBAB");
  } else {
    Serial.println("BASAH");
  }
  
  // Tampilkan di LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Raw: ");
  lcd.print(average);
  
  lcd.setCursor(0, 1);
  lcd.print("Moist: ");
  lcd.print(moisturePercent);
  lcd.print("%");
  
  delay(100);  // Update lebih cepat
}
