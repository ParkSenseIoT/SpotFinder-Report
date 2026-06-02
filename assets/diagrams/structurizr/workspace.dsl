workspace "SpotFinder" "C4 Model — Sistema IoT de gestión inteligente de estacionamientos." {

    !identifiers hierarchical

    model {
        # --- Personas ---
        driver = person "Driver" "Conductor que visita centros comerciales y usa la app móvil para encontrar espacio, pagar y localizar su vehículo." "Person"
        admin  = person "Parking Administrator" "Personal operativo del estacionamiento. Usa el dashboard web para monitorear, gestionar espacios y atender emergencias." "Person"

        # --- Sistema y contenedores ---
        spotfinder = softwareSystem "SpotFinder" "Plataforma IoT que monitorea ocupación de estacionamientos en tiempo real, automatiza accesos por ALPR y procesa pagos digitales." {
            mobileApp     = container "Mobile App"        "Aplicación móvil para conductores: mapa de ocupación, pagos, Find My Car, notificaciones."                       "Flutter / Dart"           "Mobile"
            webDashboard  = container "Web Dashboard"     "Dashboard administrativo: monitoreo en tiempo real, métricas, gestión de espacios y emergencias."                  "Angular + Angular Material" "WebBrowser"
            landingPage   = container "Landing Page"      "Sitio web estático con propuesta de valor, planes y CTAs hacia la app móvil y el dashboard."                       "HTML5 / CSS3 / JavaScript"  "WebBrowser"
            backendApi    = container "Backend API"       "Servicios RESTful: lógica de negocio de los 7 bounded contexts (IAM, Parking Monitoring, Access Control, Payment Processing, Emergency & Safety, Analytics & Reporting, Notification Management)." "Spring Boot 4 / Java 21"
            edgeServer    = container "Edge Server"       "Capa edge: recibe lecturas MQTT de los sensores, aplica debounce/umbrales y reenvía eventos al backend."           "Flask / Python / MQTT"     "Edge"
            database      = container "Database"          "Persistencia relacional del sistema. Esquema único `spotfinder` con tablas por bounded context."                   "MySQL 8 (InnoDB)"          "Database"
            iotNode       = container "Parking Spot Node" "Nodo IoT por espacio: ESP32 + HC-SR04 + LED WS2812B + MQ-2 + buzzer. Publica eventos vía MQTT."                    "ESP32 / C++ / MQTT"        "IoT"
        }

        # --- Sistemas externos ---
        culqi      = softwareSystem "Culqi Payment Gateway"  "Pasarela peruana para pagos con tarjeta y Yape."           "External"
        plateRecog = softwareSystem "Plate Recognizer API"    "Servicio externo de reconocimiento de placas (ALPR)."       "External"
        fcm        = softwareSystem "Firebase Cloud Messaging" "Servicio de notificaciones push (Android / iOS)."         "External"
        mallSys    = softwareSystem "Mall Systems"            "Sistemas operativos del centro comercial."                  "External"

        # --- Relaciones (Context) ---
        driver -> spotfinder "Consulta disponibilidad, paga y localiza su vehículo"
        admin  -> spotfinder "Monitorea ocupación, gestiona espacios y atiende emergencias"
        spotfinder -> culqi      "Procesa pagos digitales (HTTPS / REST)"
        spotfinder -> plateRecog "Envía imágenes de placas para ALPR (HTTPS / REST)"
        spotfinder -> fcm        "Envía notificaciones push (HTTPS / REST)"
        spotfinder -> mallSys    "Intercambia datos operativos del estacionamiento"

        # --- Relaciones (Container) ---
        driver -> spotfinder.mobileApp    "Usa la app móvil"
        driver -> spotfinder.landingPage  "Consulta el landing"
        admin  -> spotfinder.webDashboard "Usa el dashboard administrativo"
        admin  -> spotfinder.landingPage  "Consulta el landing"

        spotfinder.mobileApp    -> spotfinder.backendApi "Consume servicios REST (JSON/HTTPS, JWT)"
        spotfinder.webDashboard -> spotfinder.backendApi "Consume servicios REST (JSON/HTTPS, JWT)"
        spotfinder.landingPage  -> spotfinder.backendApi "Formulario de contacto (HTTPS)"

        spotfinder.backendApi -> spotfinder.database "Lee/escribe vía JPA"  "JDBC / MySQL 8"
        spotfinder.backendApi -> culqi      "Procesa pagos"
        spotfinder.backendApi -> plateRecog "ALPR (envía imagen, recibe placa)"
        spotfinder.backendApi -> fcm        "Envía notificaciones push"
        spotfinder.backendApi -> mallSys    "Intercambia datos operativos"

        spotfinder.iotNode    -> spotfinder.edgeServer "Publica lecturas y eventos (MQTT)"
        spotfinder.edgeServer -> spotfinder.backendApi "Reenvía eventos consolidados (HTTPS / REST)"
        spotfinder.backendApi -> spotfinder.webDashboard "Push de actualizaciones en tiempo real (WebSocket)"

        # --- Deployment: ambiente productivo ---
        production = deploymentEnvironment "Production" {
            userDevice = deploymentNode "User Device (iOS / Android)" "Smartphone del conductor" "iOS / Android" {
                liveMobileApp = containerInstance spotfinder.mobileApp
            }

            adminWorkstation = deploymentNode "Admin Workstation" "PC/Tablet del administrador" "Browser" {
                liveWebDashboard = containerInstance spotfinder.webDashboard
                liveLandingPageBrowser = containerInstance spotfinder.landingPage
            }

            frontendHosting = deploymentNode "Frontend Hosting (Vercel + Netlify)" "CDN para landing y dashboard" "Vercel / Netlify CDN" {
                hostedLanding = containerInstance spotfinder.landingPage
                hostedDashboard = containerInstance spotfinder.webDashboard
            }

            apiHosting = deploymentNode "API Hosting Platform" "Plataforma cloud que ejecuta el backend" "Render (Spring Boot Runtime)" {
                hostedBackend = containerInstance spotfinder.backendApi
            }

            dbHosting = deploymentNode "Database Infrastructure" "Servicio gestionado de base de datos" "Managed MySQL Service (Railway / Aiven for MySQL)" {
                hostedDatabase = containerInstance spotfinder.database
            }

            edgeNode = deploymentNode "IoT Processing Layer" "Servidor edge en el estacionamiento" "Edge Gateway Node (Linux + MQTT Broker)" {
                hostedEdge = containerInstance spotfinder.edgeServer
            }

            parkingFloor = deploymentNode "Parking Floor" "Espacios físicos del estacionamiento" "Centro comercial" {
                hostedIotNode = containerInstance spotfinder.iotNode
            }
        }
    }

    views {
        systemLandscape "SystemLandscape" "Vista de System Landscape del ecosistema SpotFinder." {
            include *
            autoLayout
        }

        systemContext spotfinder "SystemContext" "Vista de contexto: SpotFinder y sus actores/sistemas externos." {
            include *
            autoLayout
        }

        container spotfinder "Containers" "Vista de contenedores del sistema SpotFinder." {
            include *
            autoLayout
        }

        deployment spotfinder "Production" "Deployment" "Vista de despliegue en producción." {
            include *
            autoLayout
        }

        styles {
            element "Person"     { background "#1A82FF" color "#FFFFFF" shape Person }
            element "External"   { background "#999999" color "#FFFFFF" }
            element "Mobile"     { shape MobileDevicePortrait }
            element "WebBrowser" { shape WebBrowser }
            element "Database"   { shape Cylinder background "#10B981" color "#FFFFFF" }
            element "Edge"       { background "#FF9100" color "#FFFFFF" }
            element "IoT"        { shape RoundedBox background "#EF4444" color "#FFFFFF" }
        }
    }
}
