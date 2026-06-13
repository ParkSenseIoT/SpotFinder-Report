/* ============================================================================
 *  SpotFinder — Firmware del nodo IoT (ESP32 / ESP32-CAM)
 *  ParkSense IoT
 *
 *  Integra en un solo sketch las tres responsabilidades físicas del prototipo:
 *
 *   1. Parking Spot Node  : HC-SR04 (ocupación) + WS2812B (guiado visual)
 *   2. Emergency Node     : MQ-2 (gas/humo, simulado con potenciómetro) + buzzer
 *   3. Access Barrier Node: 2x IR (entrada/salida) + servo SG90 (barrera)
 *
 *  El nodo se conecta por Wi-Fi y habla por HTTP REST con el Backend Spring Boot
 *  (en la demo, directo; en producción, vía el Edge Server Flask + MQTT).
 *
 *  Endpoints usados:
 *   - POST   /api/v1/sensor-readings        (ocupación del slot)
 *   - POST   /api/v1/parking-sessions       (entrada: crea sesión por placa)
 *   - GET    /api/v1/parking-sessions/{id}  (salida: verifica paymentStatus)
 *   - PATCH  /api/v1/parking-sessions/{id}/end
 *   - POST   /api/v1/emergency/alerts        (gas > umbral)
 *
 *  Librerías (Arduino IDE / PlatformIO):
 *   - WiFi.h           (incluida en el core ESP32)
 *   - HTTPClient.h     (incluida en el core ESP32)
 *   - ArduinoJson      (Benoit Blanchon)
 *   - Adafruit_NeoPixel
 *   - ESP32Servo
 * ========================================================================== */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Adafruit_NeoPixel.h>
#include <ESP32Servo.h>

// ------------------------- Configuración de red ----------------------------
const char* WIFI_SSID     = "Wokwi-GUEST";          // en físico: tu red real
const char* WIFI_PASSWORD = "";                      // Wokwi-GUEST no usa clave
const char* API_BASE      = "http://192.168.1.40:8080"; // IP de la laptop, NO localhost

// ------------------------- Identidad del nodo ------------------------------
const char* FLOOR_ID    = "B2";
const long  SLOT_ID     = 1;          // id de parking_slots en la BD
const char* SENSOR_ID   = "ultra-B2-A01";
const char* TEST_PLATE  = "A0B-123";  // placa simulada (no hay cámara en el sim)
const char* BARRIER_IN  = "ENTRY-01";
const long  DEMO_USER   = 1;          // userId dueño de la sesión

// ------------------------- Pines (ESP32 DevKit / Wokwi) --------------------
// NOTA: en el ESP32-CAM físico se usan GPIO 13 (IR entrada), 15 (IR salida) y
// 14 (servo); aquí se usa el mapeo del DevKit para la simulación en Wokwi.
const int PIN_TRIG   = 5;
const int PIN_ECHO   = 18;
const int PIN_LED    = 4;     // WS2812B (DIN, con R=330 ohm)
const int PIN_MQ2    = 34;    // ADC1 (potenciómetro simula gas)
const int PIN_BUZZER = 25;
const int PIN_BTN    = 13;    // provisioning (INPUT_PULLUP)
const int PIN_SERVO  = 26;    // barrera
const int PIN_IR_IN  = 14;    // IR entrada  (LOW = vehículo detectado)
const int PIN_IR_OUT = 27;    // IR salida

// ------------------------- Umbrales ----------------------------------------
const float OCCUPIED_CM   = 100.0;  // < 100 cm sostenido => ocupado
const int   GAS_THRESHOLD = 2200;   // ADC (~900 PPM equivalentes)
const int   BARRIER_OPEN  = 90;     // grados
const int   BARRIER_CLOSE = 0;

// ------------------------- Paleta SpotFinder (GRB del NeoPixel) ------------
Adafruit_NeoPixel pixel(1, PIN_LED, NEO_GRB + NEO_KHZ800);
Servo barrier;

// Estado
bool   slotOccupied = false;
long   activeSessionId = -1;
unsigned long lastReadingMs = 0;

// ========================================================================== //
//  Helpers de color (alineados con la guía de estilos §5.1.2)
// ========================================================================== //
void ledGreen() { pixel.setPixelColor(0, pixel.Color(0, 200, 60));  pixel.show(); } // #10B981
void ledRed()   { pixel.setPixelColor(0, pixel.Color(220, 30, 30)); pixel.show(); } // #EF4444
void ledBlue()  { pixel.setPixelColor(0, pixel.Color(20, 120, 255));pixel.show(); } // #1A82FF
void ledOff()   { pixel.setPixelColor(0, 0); pixel.show(); }

// ========================================================================== //
//  Wi-Fi
// ========================================================================== //
void connectWifi() {
  ledBlue();                               // azul = provisioning / buscando red
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Conectando a Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300); Serial.print(".");
  }
  Serial.printf("\nWi-Fi OK. IP: %s\n", WiFi.localIP().toString().c_str());
  ledGreen();                              // verde = operativo / disponible
}

// ========================================================================== //
//  HTTP genéricos
// ========================================================================== //
int httpPost(const String& path, const String& body, String& out) {
  HTTPClient http;
  http.begin(String(API_BASE) + path);
  http.addHeader("Content-Type", "application/json");
  int code = http.POST(body);
  out = http.getString();
  http.end();
  return code;
}

int httpGet(const String& path, String& out) {
  HTTPClient http;
  http.begin(String(API_BASE) + path);
  int code = http.GET();
  out = http.getString();
  http.end();
  return code;
}

int httpPatch(const String& path) {
  HTTPClient http;
  http.begin(String(API_BASE) + path);
  http.addHeader("Content-Type", "application/json");
  int code = http.PATCH("{}");
  http.end();
  return code;
}

// ========================================================================== //
//  1. Parking Spot Node — ocupación
// ========================================================================== //
float readDistanceCm() {
  digitalWrite(PIN_TRIG, LOW);  delayMicroseconds(2);
  digitalWrite(PIN_TRIG, HIGH); delayMicroseconds(10);
  digitalWrite(PIN_TRIG, LOW);
  long us = pulseIn(PIN_ECHO, HIGH, 30000);
  if (us == 0) return 999.0;
  return us / 58.0;
}

void publishReading(float cm) {
  StaticJsonDocument<192> doc;
  doc["sensorId"] = SENSOR_ID;
  doc["slotId"]   = SLOT_ID;
  doc["distance"] = cm;
  String body; serializeJson(doc, body);
  String resp;
  int code = httpPost("/api/v1/sensor-readings", body, resp);
  Serial.printf("[slot] POST /sensor-readings -> %d\n", code);
}

void handleOccupancy() {
  float cm = readDistanceCm();
  bool nowOccupied = (cm < OCCUPIED_CM);
  if (nowOccupied != slotOccupied) {
    slotOccupied = nowOccupied;
    slotOccupied ? ledRed() : ledGreen();
    publishReading(cm);
  }
}

// ========================================================================== //
//  2. Emergency Node — gas / humo
// ========================================================================== //
void emergencyBuzzer() {
  for (int f = 400; f <= 1200; f += 100) { tone(PIN_BUZZER, f, 60); delay(60); }
  for (int f = 1200; f >= 400; f -= 100) { tone(PIN_BUZZER, f, 60); delay(60); }
  noTone(PIN_BUZZER);
}

void handleEmergency() {
  int gas = analogRead(PIN_MQ2);
  if (gas > GAS_THRESHOLD) {
    Serial.printf("[emg] GAS %d > %d  -> POST /emergency/alerts\n", gas, GAS_THRESHOLD);
    StaticJsonDocument<192> doc;
    doc["sensorId"]       = "mq2-B2-A01";
    doc["gasLevel"]       = gas;
    doc["type"]           = "GAS";
    doc["sensorLocation"] = "Piso B2 - Pasillo A";
    String body; serializeJson(doc, body);
    String resp;
    httpPost("/api/v1/emergency/alerts", body, resp);
    // Protocolo: LED rojo estroboscópico + sirena
    for (int i = 0; i < 5; i++) { ledRed(); delay(120); ledOff(); delay(120); }
    emergencyBuzzer();
    ledGreen();
  }
}

// ========================================================================== //
//  3. Access Barrier Node — entrada / salida
// ========================================================================== //
void openBarrier()  { barrier.write(BARRIER_OPEN);  }
void closeBarrier() { barrier.write(BARRIER_CLOSE); }

void handleEntry() {
  if (digitalRead(PIN_IR_IN) != LOW) return;        // IR activo en LOW
  Serial.println("[barrier] IR entrada -> POST /parking-sessions");
  StaticJsonDocument<128> doc;
  doc["licensePlate"] = TEST_PLATE;                 // (con cámara: usar /access/entries)
  doc["userId"]       = DEMO_USER;
  String body; serializeJson(doc, body);
  String resp;
  int code = httpPost("/api/v1/parking-sessions", body, resp);
  if (code == 201) {
    StaticJsonDocument<384> r; deserializeJson(r, resp);
    activeSessionId = r["id"] | -1;
    Serial.printf("[barrier] sesion %ld creada -> ABRE\n", activeSessionId);
    openBarrier(); delay(3000); closeBarrier();
  } else {
    Serial.printf("[barrier] entrada rechazada (%d)\n", code);
  }
  delay(1500);                                      // anti-rebote del IR
}

void handleExit() {
  if (digitalRead(PIN_IR_OUT) != LOW) return;
  if (activeSessionId < 0) { Serial.println("[barrier] sin sesion activa"); delay(1000); return; }
  Serial.println("[barrier] IR salida -> verifica pago");
  String resp;
  int code = httpGet("/api/v1/parking-sessions/" + String(activeSessionId), resp);
  if (code == 200) {
    StaticJsonDocument<384> r; deserializeJson(r, resp);
    const char* pay = r["paymentStatus"] | "PENDING";
    if (String(pay) == "PAID") {
      httpPatch("/api/v1/parking-sessions/" + String(activeSessionId) + "/end");
      Serial.println("[barrier] PAID -> ABRE y cierra sesion");
      openBarrier(); delay(3000); closeBarrier();
      activeSessionId = -1;
    } else {
      Serial.println("[barrier] PENDING -> NO abre");
      for (int i = 0; i < 3; i++) { tone(PIN_BUZZER, 300, 150); delay(200); }
    }
  }
  delay(1500);
}

// ========================================================================== //
//  Provisioning button
// ========================================================================== //
void handleProvisioning() {
  if (digitalRead(PIN_BTN) == LOW) {
    unsigned long t0 = millis();
    while (digitalRead(PIN_BTN) == LOW) delay(10);
    if (millis() - t0 > 5000) {                     // pulsación larga
      Serial.println("[node] provisioning reset");
      ledBlue();
      WiFi.disconnect(true);
      delay(500);
      ESP.restart();
    } else {                                        // pulsación corta
      Serial.println("[node] republica estado");
      publishReading(readDistanceCm());
    }
  }
}

// ========================================================================== //
//  setup / loop
// ========================================================================== //
void setup() {
  Serial.begin(115200);
  pinMode(PIN_TRIG, OUTPUT);
  pinMode(PIN_ECHO, INPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_BTN, INPUT_PULLUP);
  pinMode(PIN_IR_IN, INPUT_PULLUP);
  pinMode(PIN_IR_OUT, INPUT_PULLUP);

  pixel.begin(); pixel.setBrightness(80); ledOff();
  barrier.attach(PIN_SERVO, 500, 2400);
  closeBarrier();

  connectWifi();
}

void loop() {
  handleProvisioning();
  handleEntry();
  handleExit();
  handleEmergency();

  if (millis() - lastReadingMs > 1000) {            // ocupación cada 1 s
    lastReadingMs = millis();
    handleOccupancy();
  }
}
