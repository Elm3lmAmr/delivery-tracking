'use strict';

// Escape a cell value for CSV
function escape(val) {
  if (val === null || val === undefined) return '';
  const s = String(val);
  if (s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r')) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

function toCsv(rows, columns) {
  const header = columns.map((c) => escape(c.label)).join(',');
  const lines = rows.map((row) =>
    columns.map((c) => {
      let v = row[c.key];
      if (v instanceof Date) v = v.toISOString();
      return escape(v);
    }).join(',')
  );
  return [header, ...lines].join('\r\n');
}

module.exports = { toCsv, escape };
