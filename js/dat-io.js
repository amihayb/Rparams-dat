/**
 * dat-io.js
 *
 * Binary .dat file reader and writer.
 * Uses a resolved format list (entries with byteOffset) produced by
 * resolveOffsets() from binary-format.js.
 *
 * Binary convention: little-endian, matches MATLAB fwrite(..., 'l').
 * Array elements are stored in column-major order (matches MATLAB value(:)).
 */

import { typeSize, normalizeDims } from './binary-format.js';

/**
 * Decode an ArrayBuffer into a map of { path: value }.
 *
 * Scalar fields  → a single number (or boolean for logical/boolean types).
 * Array  fields  → a number[] in column-major order.
 *
 * @param {ArrayBuffer} buffer
 * @param {Object[]} formatList  entries with byteOffset (from resolveOffsets)
 * @returns {Object}
 */
export function readDat(buffer, formatList) {
    const view   = new DataView(buffer);
    const values = {};

    for (const entry of formatList) {
        if (entry.isJunk) continue;

        const [rows, cols] = normalizeDims(entry.dims);
        const count        = rows * cols;
        const step         = typeSize(entry.type);
        const result       = [];
        let   bytePos      = entry.byteOffset;

        for (let i = 0; i < count; i++) {
            result.push(readScalar(view, bytePos, entry.type));
            bytePos += step;
        }

        values[entry.path] = count === 1 ? result[0] : result;
    }

    return values;
}

/**
 * Encode a map of { path: value } into an ArrayBuffer.
 *
 * Junk/padding entries are left as zero (ArrayBuffer is zero-initialised).
 * Missing paths fall back to the default value stored in the format entry.
 *
 * @param {Object}   values      map of path → value
 * @param {Object[]} formatList  entries with byteOffset (from resolveOffsets)
 * @param {number}   byteCount   total buffer size (from totalBytes)
 * @returns {ArrayBuffer}
 */
export function writeDat(values, formatList, byteCount) {
    const buffer = new ArrayBuffer(byteCount); // zero-initialised (junk = 0)
    const view   = new DataView(buffer);

    for (const entry of formatList) {
        if (entry.isJunk) continue; // zeros already written

        const [rows, cols] = normalizeDims(entry.dims);
        const count        = rows * cols;
        const raw          = values[entry.path] ?? entry.value;
        const step         = typeSize(entry.type);
        let   bytePos      = entry.byteOffset;

        for (let i = 0; i < count; i++) {
            const v = Array.isArray(raw) ? (raw[i] ?? 0) : (i === 0 ? raw : 0);
            writeScalar(view, bytePos, entry.type, v);
            bytePos += step;
        }
    }

    return buffer;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function readScalar(view, offset, type) {
    switch (type) {
        case 'double':  return view.getFloat64(offset, true);
        case 'single':  return view.getFloat32(offset, true);
        case 'int8':    return view.getInt8(offset);
        case 'int16':   return view.getInt16(offset, true);
        case 'int32':   return view.getInt32(offset, true);
        case 'int64':   return Number(view.getBigInt64(offset, true));
        case 'uint8':   return view.getUint8(offset);
        case 'uint16':  return view.getUint16(offset, true);
        case 'uint32':  return view.getUint32(offset, true);
        case 'uint64':  return Number(view.getBigUint64(offset, true));
        case 'logical':
        case 'boolean': return view.getUint8(offset) !== 0;
        default:        return view.getInt32(offset, true); // enum / unknown
    }
}

function writeScalar(view, offset, type, value) {
    const n = Number(value);
    switch (type) {
        case 'double':  view.setFloat64(offset, n, true);                          break;
        case 'single':  view.setFloat32(offset, n, true);                          break;
        case 'int8':    view.setInt8(offset, n);                                   break;
        case 'int16':   view.setInt16(offset, n, true);                            break;
        case 'int32':   view.setInt32(offset, n, true);                            break;
        case 'int64':   view.setBigInt64(offset, BigInt(Math.trunc(n)), true);     break;
        case 'uint8':   view.setUint8(offset, n);                                  break;
        case 'uint16':  view.setUint16(offset, n, true);                           break;
        case 'uint32':  view.setUint32(offset, n, true);                           break;
        case 'uint64':  view.setBigUint64(
                            offset,
                            BigInt(Math.trunc(Math.max(0, n))),
                            true);                                                  break;
        case 'logical':
        case 'boolean': view.setUint8(offset, n ? 1 : 0);                         break;
        default:        view.setInt32(offset, n, true);                            break; // enum
    }
}
