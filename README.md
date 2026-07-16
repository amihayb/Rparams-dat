# Rparams-dat — Parameters File Editor

A browser-based tool for creating, editing, and reading binary parameter (`.dat`) files that are byte-compatible with C structs packed by a MATLAB Simulink Bus.  
Developed by Blau Robotics, it bridges MATLAB model parameters and embedded deployment — because at Blau Robotics, **we do it best.**  
No server, no build step — open `index.html` directly in any modern browser.

---

## Screenshot

> Load a JSON schema → edit values in the table → download the updated `.dat`

---

## Features

- **Load JSON schema** exported from MATLAB to display all parameters with their types, dimensions, and units
- **Load existing `.dat`** file to pre-fill values from a previously saved configuration
- **Editable table** — scalar number inputs, multi-element comma-separated text inputs, and checkbox inputs for boolean fields
- **Filter parameters** — search box to narrow the table by parameter name
- **Download `.dat`** — writes a byte-exact binary file using the same little-endian, column-major layout MATLAB produces
- **Light / dark theme** — toggle persists across sessions via `localStorage`
- **Responsive** — logos and title stay fixed at the top; controls wrap cleanly on narrow screens

---

## Quick Start

### 1 — Generate the JSON schema in MATLAB

```matlab
% Run your parameter script to populate the struct
ExtParamsNg;

% Export schema + default values
ExportParamsJson('NG_Test_Params', ExtParams, 'BusAimingAlgExtParams', 8);
```

### 2 — Edit in the browser

1. Open `index.html` in Chrome, Edge, or Firefox.
2. Click **JSON schema** and select the `.json` file produced above.
3. *(Optional)* Click **Load .dat** to read an existing binary file.
4. Edit values in the table.
5. Set the output filename and click **↓ Download .dat**.

### 3 — Write `.dat` directly from MATLAB (no browser needed)

```matlab
ExtParamsNg;
Create_Params('MyParams', ExtParams, 'BusAimingAlgExtParams', 8);
```

---

## Project Layout

```
index.html              Single-page app (HTML + inline JS)
css/style.css           All styles — CSS variables, topnav, table, dark theme
images/                 RafLogo.svg, logo-title.svg
vendor/                 font-awesome.min.css (offline, no CDN dependency)
fonts/                  Font Awesome webfonts
js/                     Original modular ES-module version (reference only)
m-files/                MATLAB source files
  ExportParamsJson.m    ← Main entry point: struct → JSON schema
  Create_Params.m       ← Write .dat directly from MATLAB
  CreateBusFormat.m     Builds the flat field/padding layout table
  ReadBinaryPragma.m    Recursive struct walker + padding insertion
  CreateBinaryParamsFile.m  Low-level fwrite loop
  ... (see PROJECTMAP.md for full reference)
NG_Test_Params.json     Sample schema for BusAimingAlgExtParams (pragma 8)
PROJECTMAP.md           Developer map — architecture, concepts, data formats
```

---

## Binary Format

| Property | Value |
|---|---|
| Byte order | Little-endian |
| Array layout | Column-major (MATLAB convention) |
| Padding | C `#pragma pack(N)` semantics (`N` = 4 or 8) |
| Supported types | `single`, `double`, `int8/16/32/64`, `uint8/16/32/64`, `logical` |
| Unsupported types | Fall back to `int32` (enums) |

Padding (`Junk`) entries in the JSON schema are written as zero bytes and are not shown in the editor.

---

## Requirements

### Browser
Any modern browser (Chrome 89+, Edge 89+, Firefox 90+).  
`file://` access is sufficient — no web server required.

### MATLAB (for schema export / direct `.dat` write)
- MATLAB R2016b or later (`jsonencode` required; `PrettyPrint` option needs R2020b)
- Simulink (Bus objects must be defined in the base workspace)

---

## Contributing

See [PROJECTMAP.md](PROJECTMAP.md) for a full description of the architecture and all key concepts.

---

## Contact

Amihay Blau  
mail: amihay@blaurobotics.co.il  
Phone: +972-54-6668902
