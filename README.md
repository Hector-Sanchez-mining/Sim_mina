# MineSim — Editor Operacional Minero

Simulador modular de actividades mineras. Fase 1: visor STL + editor de nodos.

## Estructura

```
Sim_mina/
├── minesim.html       ← Aplicación principal
├── export_stl.lsp     ← AutoLISP: exportar sólidos por layer desde AutoCAD
├── models/
│   ├── models.json    ← Índice de modelos STL (generado por el LISP)
│   ├── Obra01.stl
│   └── ...
├── .nojekyll          ← Necesario para que GitHub Pages sirva archivos binarios
└── README.md
```

## Flujo de uso

### 1. Exportar modelos desde AutoCAD

```
(load "export_stl.lsp")
EXPORTSTL
```

Selecciona la carpeta `models/` del repo. El LISP exporta un STL por layer con sólidos 3D y genera `models.json` con las unidades del dibujo.

### 2. Subir a GitHub

Sube los archivos STL y `models.json` a la carpeta `models/` del repositorio.

### 3. Abrir el simulador

```
https://hector-sanchez-mining.github.io/Sim_mina/minesim.html
```

## Controles

| Acción | Gesto |
|---|---|
| Rotar cámara | Clic izquierdo + arrastrar |
| Pan | Clic derecho · Clic medio + arrastrar |
| Zoom | Rueda del mouse |
| Centrar vista | Botón ⊙ Centrar vista |
| Colocar nodo | Seleccionar tipo en sidebar → clic en escena |
| Cancelar herramienta | ESC |
| Seleccionar nodo | Clic sobre nodo |
| Conectar nodos | Botón Conectar → clic A → clic B |
| Cancelar conexión | ESC |

## Tipos de nodo

| Tipo | Color | Parámetros |
|---|---|---|
| Source | Verde | TPH, material, turnos |
| Sink | Rojo | Capacidad |
| Stockpile | Naranja | Capacidad, material |
| Crusher | Violeta | TPH, P80 |
| Conveyor | Azul | Velocidad, ancho |
| Loading Bay | Naranja oscuro | Camiones/hr |
| Ventilación | Cyan | m³/s, Pa |
| Refugio | Verde claro | Personas, autonomía |

## Roadmap

- **Fase 1** ✓ — Visor STL por layer, editor de nodos, conexiones visuales, guardado JSON
- **Fase 2** — Parámetros avanzados, rutas con pathfinding, validación topológica
- **Fase 3** — Simulación temporal, KPIs, optimización de escenarios
