# PROJECTMAP — Rparams-dat

## Purpose

A two-part toolchain for creating, editing, and reading binary parameter (`.dat`) files that are byte-compatible with C structs packed by a MATLAB Simulink Bus. The tool removes the need to recompile an embedded model just to change parameter values.

---

## Architecture Overview

```
MATLAB (offline authoring)               Browser (field editing)
─────────────────────────────            ────────────────────────────────
ExtParamsNg.m                            index.html
  └─ define ExtParams struct         ──► Load JSON schema
                                         Edit parameter values in table
CreateBusFormat.m                        Load existing .dat  (optional)
  └─ walk struct + bus + pragma      ──► Download modified .dat
  └─ insert padding entries
                                    ◄──  .dat written in the same binary
ExportParamsJson.m                        layout as MATLAB / C
  └─ emit JSON (meta + format[])
```

---

## File Reference

### Root

| File | Role |
|---|---|
| [index.html](index.html) | Single-page web app — fixed topnav, editable params table, status bar. All JS is inline. |
| [NG_Test_Params.json](NG_Test_Params.json) | Sample exported JSON schema for `BusAimingAlgExtParams` (pragma 8) |
| [README.md](README.md) | User-facing quick-start guide |
| [PROJECTMAP.md](PROJECTMAP.md) | This file — developer architecture map |
| [.gitignore](.gitignore) | Ignores OS artefacts and generated `.dat` files |

### css/

| File | Role |
|---|---|
| [css/style.css](css/style.css) | All styles — CSS variables (light + dark theme), topnav, table, inputs, status bar |

### images/

| File | Role |
|---|---|
| `images/RafLogo.svg` | Rafael logo — top-left of the topnav |
| `images/logo-title.svg` | Project logo — top-right of the topnav |

### vendor/ and fonts/

| File | Role |
|---|---|
| `vendor/font-awesome.min.css` | Font Awesome 4 icons (offline, no CDN dependency) |
| `fonts/fontawesome-webfont.*` | Font Awesome webfont files referenced by the CSS |

### js/ *(reference only — not linked from index.html)*

The `js/` folder contains the **original ES-module version** written before the UI was built. The code is functionally equivalent to the inline script in `index.html` but does not include the theme toggle, search filter, or topnav height tracker. It is kept as a clean modular reference.

| File | Role |
|---|---|
| [js/app.js](js/app.js) | UI controller — wires file inputs and download button to the two library modules |
| [js/binary-format.js](js/binary-format.js) | Pure library — `typeSize`, `normalizeDims`, `resolveOffsets`, `totalBytes`, `entryBytes` |
| [js/dat-io.js](js/dat-io.js) | Pure library — `readDat` (ArrayBuffer → values map), `writeDat` (values map → ArrayBuffer) |

### m-files/

| File | Role |
|---|---|
| [m-files/ExtParamsNg.m](m-files/ExtParamsNg.m) | Example params script — populates `ExtParams` struct with default values |
| [m-files/ExportParamsJson.m](m-files/ExportParamsJson.m) | **Main entry point** — calls `CreateBusFormat` then serialises layout + values to JSON |
| [m-files/Create_Params.m](m-files/Create_Params.m) | Writes the `.dat` file directly from MATLAB (uses same `CreateBusFormat` pipeline) |
| [m-files/CreateBusFormat.m](m-files/CreateBusFormat.m) | Orchestrator — calls `ReadBinaryPragma` recursively to build the flat `BusFormat` cell array |
| [m-files/ReadBinaryPragma.m](m-files/ReadBinaryPragma.m) | Recursive walker — visits every field of a nested struct, inserts padding via `PaddingBeginStruct`/`PaddingEndStruct` |
| [m-files/CreateBinaryParamsFile.m](m-files/CreateBinaryParamsFile.m) | Low-level writer — iterates `BusFormat` and calls `fwrite` with little-endian byte order |
| [m-files/Padding.m](m-files/Padding.m) | Padding utility — computes how many filler bytes are needed to reach next alignment boundary |
| [m-files/PaddingBeginStruct.m](m-files/PaddingBeginStruct.m) | Inserts padding before a struct starts (to align to its largest member) |
| [m-files/PaddingEndStruct.m](m-files/PaddingEndStruct.m) | Inserts tail padding after a struct ends (so array-of-structs stays aligned) |
| [m-files/StructMaxMemberByts.m](m-files/StructMaxMemberByts.m) | Returns the byte size of the largest primitive member in a struct (used to compute alignment) |
| [m-files/SizeOf_Matlab.m](m-files/SizeOf_Matlab.m) | Returns the total byte size and format of a Bus type — used to validate `.dat` size |
| [m-files/TypeSize.m](m-files/TypeSize.m) | Maps a MATLAB type name (`'single'`, `'uint16'`, …) to its byte size — mirrors `typeSize()` in JS |
| [m-files/CheckBytsSize.m](m-files/CheckBytsSize.m) | Asserts that the file size on disk matches the expected size |

---

## Key Concepts

### BusFormat cell array
The central data structure produced by `CreateBusFormat`. Each row describes one field or padding slot:

| Column | Content |
|---|---|
| 1 | Type string (`'single'`, `'uint8'`, `'int32'`, …) |
| 2 | Size `[rows, cols]` |
| 3 | Dot-path string (e.g. `.KFParams.TcParamIn`) or `'JunkN'` for padding |
| 4 | Unit string (may be empty) |

### JSON schema (`*.json`)
Exported by `ExportParamsJson`. Top-level keys:

```json
{
  "meta":   { "busName": "BusAimingAlgExtParams", "pragma": 8 },
  "format": [ ... ]
}
```

Each `format` entry is either a **data entry**:
```json
{ "type": "single", "path": ".KFParams.TcParamIn", "isJunk": false,
  "dims": [1,1], "units": "", "value": 0.003 }
```
or a **padding entry**:
```json
{ "type": "uint8", "path": "Junk3", "isJunk": true, "elemCount": 4 }
```

### Binary layout
- **Byte order**: little-endian (`fwrite(...,'l')` in MATLAB; `DataView` with `littleEndian=true` in JS).
- **Array element order**: column-major (MATLAB default — the JS reader/writer preserve this).
- **Padding**: C `#pragma pack(N)` semantics, where `N` is the `pragma` argument (typically 4 or 8). `ReadBinaryPragma` computes and injects `Junk` entries to reproduce the exact same memory layout a C compiler would produce.

### Offset resolution (JS only)
`resolveOffsets()` in `binary-format.js` walks the format list sequentially, accumulating a running `byteOffset` on each entry. This replaces the MATLAB address-tracking that happens during `ReadBinaryPragma`.

---

## Typical Workflows

### 1 — First-time JSON export (MATLAB)
```matlab
ExtParamsNg;   % define ExtParams struct and Bus in the base workspace
ExportParamsJson('NG_Test_Params', ExtParams, 'BusAimingAlgExtParams', 8);
```

### 2 — Edit parameters in the browser
1. Open `index.html` in Chrome, Edge, or Firefox (`file://` access — no server needed).
2. Load the `.json` schema.
3. Optionally load an existing `.dat` to pre-fill values.
4. Use the **Filter parameters** search box to narrow the table.
5. Edit values in the table.
6. Click **↓ Download .dat**.

### 3 — Write `.dat` directly from MATLAB
```matlab
ExtParamsNg;
Create_Params('MyParams', ExtParams, 'BusAimingAlgExtParams', 8);
```

---

## Design Notes

- **All JS is inline** in `index.html` — no module bundler, no build step, no external JS dependencies. Open the file directly in any modern browser.
- The `js/` folder contains the original ES-module version (not linked); it is kept as a modular reference.
- **Theme** — light/dark toggle with CSS custom properties (`--color-*`). The anti-flash script in `<head>` reads `localStorage` before first paint to avoid FOUC.
- **Topnav height** — a `ResizeObserver` on `#topnav` writes `--topnav-h` to `:root` so `body padding-top` and the sticky `thead` always clear the nav bar, even when controls wrap on narrow screens.
- **Logos row** — `.topnav-top` uses `justify-content: space-between` so the Rafael logo (left) and project logo (right) are always pinned to the top row regardless of window width.
- **Parameter search** — `filterTable()` shows/hides `<tr>` rows by matching the `.path` cell content; it runs on every `input` event and also immediately after `renderTable()` so an active filter applies when a new JSON is loaded.
- `typeSize()` in the inline JS and `TypeSize.m` in MATLAB must stay in sync; both map the same type names to the same byte widths.
- Unsupported MATLAB types (e.g. enums) fall back to `int32` in both the MATLAB writer and the JS reader/writer.
- `isJunk` padding entries are **written as zeros** by both MATLAB (`zeros(n,'uint8')`) and the JS writer (zero-initialised `ArrayBuffer`).
