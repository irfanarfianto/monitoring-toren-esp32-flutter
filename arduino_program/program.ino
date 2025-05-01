#include <Wire.h>
#include <LiquidCrystal_PCF8574.h>
#include <ESP32Servo.h>
#include <WiFi.h>
#include <HTTPClient.h>

// Alamat I2C LCD
LiquidCrystal_PCF8574 lcd(0x27);

// Pin Ultrasonic HC-SR04
const int trigPin = 5;     // Pin Trig
const int echoPin = 18;    // Pin Echo

// Pin Servo
const int servoPin = 4;    // Pin untuk servo

// Pin LED
const int ledPin = 2;      // Misal, gunakan pin 2 untuk LED (sesuaikan dengan rangkaian)

// Variabel pengukuran air
const float containerHeight = 100.0; // Tinggi wadah (cm)
float measuredDistance = 0.0;  // Jarak dari sensor ke permukaan air (cm)
float waterLevel = 0.0;        // Ketinggian air di dalam wadah (cm)
float waterPercentage = 0.0;   // Persentase pengisian wadah

Servo myServo;  // Gunakan ESP32Servo

// WiFi Credentials
const char* ssid = "Nama WIFI";  // Ganti dengan nama WiFi Anda
const char* password = "Password WIFI";  // Ganti dengan password WiFi Anda

// Supabase config
const char* supabaseUrl = "https://jaewdybdjwobsyqxxkld.supabase.co/rest/v1/water_levels";
const char* supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphZXdkeWJkandvYnN5cXh4a2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYwMjcyMzMsImV4cCI6MjA2MTYwMzIzM30.moQIGJ9uxgPjEPVq529TNYLSeskKgyytB0C1gi_1POE";  // Ganti dengan Supabase anonKey Anda

void setup() {
  Serial.begin(9600);
  Wire.begin(21, 22);         // Setup SDA dan SCL untuk ESP32
  lcd.begin(16, 2);           // Konfigurasi LCD 16x2
  lcd.setBacklight(255);      // Aktifkan backlight

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(ledPin, OUTPUT);

  // Inisialisasi servo
  myServo.attach(servoPin);
  myServo.write(0); // Posisi default

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Mengukur...");

  // Koneksi WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connected");
}

void loop() {
  // Mengukur jarak dari sensor ke permukaan air
  measuredDistance = measureDistance();

  // Jika jarak mencapai 7 cm atau kurang, dianggap air penuh
  if (measuredDistance <= 7.0) {
    // Setting kondisi air penuh
    waterLevel = containerHeight;  // Dianggap penuh
    waterPercentage = 100.0;

    // Tampilkan notifikasi pada LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Air: FULL");
    lcd.setCursor(0, 1);
    lcd.print("<<AIR PENUH>>");

    // Gerakan servo ke posisi notifikasi (misalnya 90 derajat)
    myServo.write(90);

    // Menyalakan LED
    digitalWrite(ledPin, HIGH);

    Serial.println("<<AIR PENUH>>");
  } else {
    // Perhitungan ketinggian air saat normal (sensor dipasang di atas wadah)
    waterLevel = containerHeight - measuredDistance;

    // Koreksi nilai ketinggian air agar valid
    if (waterLevel < 0) {
      waterLevel = 0;
    }
    else if (waterLevel > containerHeight) {
      waterLevel = containerHeight;
    }

    // Hitung presentase pengisian
    waterPercentage = (waterLevel / containerHeight) * 100.0;

    // Tampilan hasil pengukuran pada LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Air: ");
    lcd.print(waterLevel, 1);
    lcd.print(" cm");

    lcd.setCursor(0, 1);
    lcd.print(waterPercentage, 0);
    lcd.print("%");

    // Kembalikan servo ke posisi default
    myServo.write(0);

    // Matikan LED
    digitalWrite(ledPin, LOW);

    Serial.print("Water Level: ");
    Serial.print(waterLevel, 1);
    Serial.print(" cm, Persen: ");
    Serial.print(waterPercentage, 0);
    Serial.println("%");
  }

  // Kirim data ke Supabase
  sendDataToSupabase(measuredDistance, waterLevel, waterPercentage);

  delay(1000); // Tunggu 1 detik sebelum pembaruan
}

// Fungsi untuk mengukur jarak (dari sensor ke permukaan air)
float measureDistance() {
  long duration;
  float distance;
  
  // Kirim sinyal trigger ke sensor ultrasonic
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  // Baca durasi sinyal Echo
  duration = pulseIn(echoPin, HIGH);
  
  // Hitung jarak dalam cm
  distance = (duration * 0.0343) / 2;
  if (distance < 0) {
    distance = 0;
  }
  
  return distance;
}

// Fungsi untuk mengirimkan data ke Supabase
void sendDataToSupabase(float distance, float level, float percent) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    // Kirim permintaan POST ke Supabase
    http.begin(supabaseUrl);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", ("Bearer " + String(supabaseKey)).c_str());

    String json = "{\"distance_cm\":" + String(distance, 2) + 
                  ",\"level_cm\":" + String(level, 2) + 
                  ",\"percent\":" + String(percent, 2) + "}";

    int httpResponseCode = http.POST(json);

    // Debugging response dari Supabase
    Serial.println("Data ke Supabase: " + json);
    Serial.println("HTTP Response: " + String(httpResponseCode));

    http.end();
  } else {
    Serial.println("WiFi tidak terhubung!");
  }
}
