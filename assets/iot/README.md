# SpotFinder — Prototipo IoT

Artefactos del dispositivo IoT (hardware + firmware) del proyecto SpotFinder.

## Archivos

| Archivo | Descripción |
|---|---|
| `diagram.json` | Esquemático del prototipo para **Wokwi**. Incluye HC-SR04, LEDs de guiado (el sim los representa con un NeoPixel; el build físico usa 2 LEDs discretos verde/rojo), MQ-2 (potenciómetro), buzzer, botón (reset/reenvío), **servo SG90 (barrera)** y **2 sensores IR (entrada/salida)**. |
| `sketch.ino` | Sketch de **simulación** (Wokwi) del nodo. El firmware autoritativo (Opción A, dos nodos) está en el repo **SpotFinder-EmbeddedApp** (`src/main.cpp` + `arduino/PlateCameraNode/PlateCameraNode.ino`). Habla **HTTP/REST con el Edge Gateway**, que reenvía al backend. |

## Cómo simular en Wokwi

1. Entrar a [wokwi.com](https://wokwi.com) → New Project → ESP32.
2. Reemplazar `diagram.json` por el de esta carpeta.
3. Pegar `sketch.ino` en el editor de código.
4. En la pestaña **Library Manager** agregar: `Adafruit NeoPixel`, `ESP32Servo`, `ArduinoJson`.
5. Iniciar la simulación. Los 2 IR se simulan con pulsadores (presionar = vehículo detectado); el MQ-2 con el potenciómetro.

## Mapeo de pines (Parking Spot + Barrier Node, ESP32 DevKit)

Bajo la **Opción A**, la ocupación, el gas y la barrera (2× IR + servo) viven en el ESP32 DevKit; la cámara es un nodo físico aparte (ESP32-CAM). Estos son los GPIO reales del firmware (coinciden con la simulación Wokwi):

| Función | GPIO (DevKit real = Wokwi) |
|---|---|
| HC-SR04 Trig / Echo | 5 / 18 |
| LED verde / LED rojo | 32 / 33 (sim: NeoPixel en 4) |
| MQ-2 AO | 34 |
| Buzzer | 25 |
| Botón (reset/reenvío) | 13 |
| **Servo barrera** | 26 |
| **IR entrada** | 14 |
| **IR salida** | 27 |

> El **Plate Camera Node** (ESP32-CAM, sensor OV3660) es un nodo aparte: solo cámara, envía la placa al Edge (`POST /api/v1/access/plate`). No se simula en Wokwi.

## Notas

- El firmware real apunta al **Edge Gateway** en `http://<IP-de-la-laptop>:5000` — cambiar el host por la IP real. No usar `localhost` desde el ESP32.
- Flujo de barrera (Opción A): la cámara envía la placa al Edge (`POST /api/v1/access/plate`); el Edge reenvía al backend (`POST /api/v1/access/entries`) para el ALPR y, tras crear la sesión, marca `OPEN`; el DevKit consulta `GET /api/v1/access/barrier` y abre el servo.
