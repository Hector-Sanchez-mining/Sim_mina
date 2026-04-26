# MineSim — Editor Operacional Minero

Simulador modular de actividades mineras. Fase 1: visor STL + editor de nodos drag-and-drop.

## Estructura

```
minesim/
├── minesim.html       ← Aplicación principal
├── launch.ps1         ← Servidor local PowerShell
├── export_stl.lsp     ← AutoLISP: exportar sólidos por layer desde AutoCAD
├── models/
│   ├── models.json    ← Índice de modelos STL
│   ├── RAMPAS.stl     ← (generado por export_stl.lsp)
│   └── ...
└── README.md
```

## Inicio rápido

### 1. Exportar modelos desde AutoCAD

```
(load "export_stl.lsp")
EXPORTSTL
```

Selecciona la carpeta `models/` del repositorio. El LISP exporta un STL por layer con sólidos 3D y genera `models.json` automáticamente.

### 2. Lanzar el simulador

```powershell
powershell -ExecutionPolicy Bypass -File launch.ps1
```

O doble clic en `launch.ps1` → "Ejecutar con PowerShell".

El servidor corre en `http://localhost:8765` y abre el browser automáticamente.

## Controles

| Acción | Gesto |
|---|---|
| Rotar cámara | Clic izquierdo + arrastrar |
| Pan | Clic derecho + arrastrar · Clic medio + arrastrar |
| Zoom | Rueda del mouse |
| Colocar nodo | Seleccionar tipo en sidebar → clic en escena |
| Cancelar herramienta | ESC |
| Seleccionar nodo | Clic izquierdo sobre nodo |
| Conectar nodos | Botón "Conectar nodos" → clic A → clic B |
| Cancelar conexión | ESC |

## Tipos de nodo

| Tipo | Color | Parámetros |
|---|---|---|
| Source | Verde | TPH, material, turnos |
| Sink | Rojo | Capacidad |
| Stockpile | Naranja | Capacidad, material |
| Crusher | Violeta | TPH, P80 |
| Conveyor | Azul claro | Velocidad, ancho |
| Loading Bay | Naranja oscuro | Camiones/hr |
| Ventilación | Cyan | m³/s, Pa |
| Refugio | Verde claro | Personas, autonomía |

## Roadmap

- **Fase 1** ✓ — Visor STL, editor de nodos, conexiones visuales, guardado JSON
- **Fase 2** — Parámetros avanzados, rutas con pathfinding, validación topológica
- **Fase 3** — Simulación temporal, KPIs, optimización de escenarios
