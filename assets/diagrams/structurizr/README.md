# Structurizr — Diagramas C4 de SpotFinder

Este directorio contiene los diagramas C4 del sistema SpotFinder.

## Archivos

| Archivo | Tipo | Descripción |
|---|---|---|
| `workspace.dsl` | Fuente | DSL de Structurizr con los 4 niveles del C4: System Landscape, Context, Container y Deployment. |
| `*.png` | Render | Imágenes exportadas desde el DSL para incrustar en el `README.md` del reporte. |

## Cómo regenerar los PNG

1. Abrir [Structurizr Lite](https://structurizr.com/help/lite) o [Structurizr DSL Online](https://structurizr.com/dsl).
2. Importar `workspace.dsl`.
3. Para cada vista (`SystemLandscape`, `SystemContext`, `Containers`, `Deployment`) → exportar como PNG.
4. Reemplazar los archivos correspondientes en este directorio:
   - `SystemLandscape` → `../c4/System-Landscape.png`
   - `SystemContext` → `../c4/Context-Diagram.png`
   - `Containers` → `../c4/Container-Diagram.png`
   - `Deployment` → `../c4/Deployment-Diagrams.png`

## Notas importantes

- El motor de base de datos es **MySQL 8 (InnoDB)**, no PostgreSQL. El contenedor `Database` y el nodo `Database Infrastructure` reflejan esto.
- El esquema lógico de la BD se denomina **`spotfinder`** (todo en minúscula, snake-case-friendly).
- Los componentes por Bounded Context (Component Level Diagrams) se mantienen en los PNG individuales que están en este mismo directorio (`Access_Control_Diagram.png`, etc.).
