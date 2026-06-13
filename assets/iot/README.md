# SpotFinder — Prototipo IoT

Artefactos del dispositivo IoT (hardware + firmware) del proyecto SpotFinder.

## Archivos

| Archivo | Descripción |
|---|---|
| `diagram.json` | Esquemático del prototipo para **Wokwi**. Incluye HC-SR04, WS2812B, MQ-2 (potenciómetro), buzzer, botón de provisioning, **servo SG90 (barrera)** y **2 sensores IR (entrada/salida)**. |
| `sketch.ino` | Firmware del ESP32 / ESP32-CAM. Cubre los 3 nodos: ocupación, emergencia y barrera de acceso, con llamadas HTTP REST al backend. |

## Cómo simular en Wokwi

1. Entrar a [wokwi.com](https://wokwi.com) → New Project → ESP32.
2. Reemplazar `diagram.json` por el de esta carpeta.
3. Pegar `sketch.ino` en el editor de código.
4. En la pestaña **Library Manager** agregar: `Adafruit NeoPixel`, `ESP32Servo`, `ArduinoJson`.
5. Iniciar la simulación. Los 2 IR se simulan con pulsadores (presionar = vehículo detectado); el MQ-2 con el potenciómetro.

## Mapeo de pines (simulación Wokwi vs físico ESP32-CAM)

| Función | Wokwi (ESP32 DevKit) | Físico (ESP32-CAM) |
|---|---|---|
| HC-SR04 Trig / Echo | 5 / 18 | — (nodo aparte) |
| WS2812B DIN | 4 | — |
| MQ-2 AO | 34 | — |
| Buzzer | 25 | — |
| Botón provisioning | 13 | — |
| **Servo barrera** | 26 | **14** |
| **IR entrada** | 14 | **13** |
| **IR salida** | 27 | **15** |

> En el ESP32-CAM físico la cámara ocupa la mayoría de los GPIO; solo quedan libres 12-15 (con microSD deshabilitada). Por eso el mapeo físico difiere del de simulación.

## Notas

- El firmware apunta a `http://<IP-de-la-laptop>:8080` — cambiar `API_BASE` por la IP real. No usar `localhost` desde el ESP32.
- Para la barrera sin cámara se usa `POST /api/v1/parking-sessions` con placa fija. Con ESP32-CAM se puede activar el ALPR real vía `POST /api/v1/access/entries`.
