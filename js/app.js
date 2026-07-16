/**
 * app.js
 *
 * Wires UI events to the schema / binary-format / dat-io modules.
 */

import { resolveOffsets, totalBytes, normalizeDims } from './binary-format.js';
import { readDat, writeDat } from './dat-io.js';

let formatList    = null;  // format entries enriched with byteOffset
let currentValues = {};    // live editable state: path → value

// ---------------------------------------------------------------------------
// File loading
// ---------------------------------------------------------------------------

document.getElementById('jsonFileInput').addEventListener('change', e => {
    const file = e.target.files[0];
    if (!file) return;

    readAsText(file).then(text => {
        try {
            const parsed = JSON.parse(text);
            if (!parsed.meta || !Array.isArray(parsed.format)) {
                throw new Error('JSON is missing "meta" or "format" keys');
            }

            formatList    = resolveOffsets(parsed.format);
            currentValues = {};

            for (const entry of formatList) {
                if (!entry.isJunk) currentValues[entry.path] = entry.value;
            }

            // Pre-fill output name from the loaded filename
            document.getElementById('outputName').value =
                file.name.replace(/\.json$/i, '');

            renderTable();
            setStatus(
                `Loaded: ${file.name}  ·  bus: ${parsed.meta.busName}` +
                `  ·  pragma: ${parsed.meta.pragma}  ·  ${totalBytes(formatList)} bytes`
            );
        } catch (err) {
            setStatus(`JSON error: ${err.message}`, true);
        }
    });
});

document.getElementById('datFileInput').addEventListener('change', e => {
    const file = e.target.files[0];
    if (!file) return;
    if (!formatList) { setStatus('Load a JSON schema first.', true); return; }

    readAsArrayBuffer(file).then(buf => {
        try {
            const loaded = readDat(buf, formatList);
            Object.assign(currentValues, loaded);
            updateTableValues();
            setStatus(`Loaded .dat: ${file.name}  ·  ${buf.byteLength} bytes`);
        } catch (err) {
            setStatus(`.dat read error: ${err.message}`, true);
        }
    });
});

document.getElementById('downloadBtn').addEventListener('click', () => {
    if (!formatList) { setStatus('Load a JSON schema first.', true); return; }

    syncValuesFromTable();
    const bytes  = totalBytes(formatList);
    const buffer = writeDat(currentValues, formatList, bytes);

    let name = document.getElementById('outputName').value.trim() || 'params';
    if (!name.endsWith('.dat')) name += '.dat';

    downloadBuffer(buffer, name);
    setStatus(`Downloaded: ${name}  ·  ${bytes} bytes`);
});

// ---------------------------------------------------------------------------
// Table rendering
// ---------------------------------------------------------------------------

function renderTable() {
    const tbody = document.querySelector('#paramsTable tbody');
    tbody.innerHTML = '';
    if (!formatList) return;

    for (const entry of formatList) {
        if (entry.isJunk) continue;

        const [rows, cols] = normalizeDims(entry.dims);
        const count  = rows * cols;
        const isBool = entry.type === 'logical' || entry.type === 'boolean';

        const tr = document.createElement('tr');

        // Path
        const tdPath = document.createElement('td');
        tdPath.className = 'path';
        tdPath.textContent = entry.path;
        tr.appendChild(tdPath);

        // Type
        appendText(tr, 'td', entry.type);

        // Dims
        appendText(tr, 'td', `${rows}×${cols}`);

        // Value (editable)
        const tdVal = document.createElement('td');
        tdVal.className = 'val-cell';
        tdVal.appendChild(makeInput(entry, count, isBool, currentValues[entry.path]));
        tr.appendChild(tdVal);

        // Units
        appendText(tr, 'td', entry.units || '');

        tbody.appendChild(tr);
    }
}

function makeInput(entry, count, isBool, value) {
    const inp = document.createElement('input');
    inp.dataset.path = entry.path;

    if (isBool) {
        inp.type    = 'checkbox';
        inp.checked = Array.isArray(value) ? !!value[0] : !!value;
    } else if (count === 1) {
        inp.type  = 'number';
        inp.step  = 'any';
        inp.value = Array.isArray(value) ? (value[0] ?? '') : (value ?? '');
    } else {
        inp.type  = 'text';
        inp.title = `${count} elements  –  column-major order`;
        inp.value = (Array.isArray(value) ? value : [value]).join(', ');
    }

    return inp;
}

/** Refresh input values in the existing table without a full re-render. */
function updateTableValues() {
    for (const entry of formatList) {
        if (entry.isJunk) continue;

        const inp = inputFor(entry.path);
        if (!inp) continue;

        const val    = currentValues[entry.path];
        const isBool = entry.type === 'logical' || entry.type === 'boolean';
        const [r, c] = normalizeDims(entry.dims);
        const count  = r * c;

        if (isBool) {
            inp.checked = Array.isArray(val) ? !!val[0] : !!val;
        } else if (count === 1) {
            inp.value = Array.isArray(val) ? (val[0] ?? '') : (val ?? '');
        } else {
            inp.value = (Array.isArray(val) ? val : [val]).join(', ');
        }
    }
}

/** Read every input element back into currentValues. */
function syncValuesFromTable() {
    for (const entry of formatList) {
        if (entry.isJunk) continue;

        const inp = inputFor(entry.path);
        if (!inp) continue;

        const [r, c] = normalizeDims(entry.dims);
        const count  = r * c;
        const isBool = entry.type === 'logical' || entry.type === 'boolean';

        if (isBool) {
            currentValues[entry.path] = inp.checked ? 1 : 0;
        } else if (count === 1) {
            currentValues[entry.path] = parseFloat(inp.value) || 0;
        } else {
            currentValues[entry.path] = inp.value
                .split(',')
                .map(s => parseFloat(s.trim()) || 0);
        }
    }
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

/** Look up the input element for a given path using a data attribute. */
function inputFor(path) {
    // Paths contain only letters, digits, '.', '_', '(', ')' – safe in a
    // quoted CSS attribute value without escaping.
    return document.querySelector(`[data-path="${path}"]`);
}

function appendText(parent, tag, text) {
    const el = document.createElement(tag);
    el.textContent = text;
    parent.appendChild(el);
    return el;
}

function setStatus(msg, isError = false) {
    const bar = document.getElementById('statusBar');
    bar.textContent = msg;
    bar.style.color = isError ? '#c00' : '#444';
}

function readAsText(file) {
    return new Promise((resolve, reject) => {
        const r  = new FileReader();
        r.onload  = ev => resolve(ev.target.result);
        r.onerror = ()  => reject(new Error('Could not read file'));
        r.readAsText(file);
    });
}

function readAsArrayBuffer(file) {
    return new Promise((resolve, reject) => {
        const r  = new FileReader();
        r.onload  = ev => resolve(ev.target.result);
        r.onerror = ()  => reject(new Error('Could not read file'));
        r.readAsArrayBuffer(file);
    });
}

function downloadBuffer(buffer, filename) {
    const blob = new Blob([buffer], { type: 'application/octet-stream' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href     = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
}
