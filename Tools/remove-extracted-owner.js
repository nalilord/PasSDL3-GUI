#!/usr/bin/env node

'use strict';

const fs = require('fs');
const path = require('path');

function fail(message) {
  process.stderr.write(`ERROR: ${message}\n`);
  process.exit(1);
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function routineEnd(source, start) {
  const expression = /^(?:constructor|destructor|procedure|function) [A-Za-z_]/gm;
  expression.lastIndex = start + 1;
  const next = expression.exec(source);
  return next ? next.index : source.length;
}

const [, , sourceName, ownerName, classList] = process.argv;
if (!sourceName || !ownerName || !classList) {
  fail('use: remove-extracted-owner.js <source.pas> <owner-unit> <class,...>');
}

const root = path.resolve(__dirname, '..');
const sourcePath = path.resolve(root, sourceName);
let source = fs.readFileSync(sourcePath, 'utf8').replace(/\r\n/g, '\n');
const classNames = classList.split(',').filter(Boolean);

for (const className of classNames) {
  const declaration = new RegExp(
    `^  ${escapeRegExp(className)} = class(?:\\([^\\n]+\\))?\\n[\\s\\S]*?^  end;`,
    'm'
  );
  if (!declaration.test(source)) {
    fail(`declaration not found: ${className}`);
  }
  source = source.replace(
    declaration,
    `  ${className} = ${ownerName}.${className};`
  );
}

const ranges = [];
for (const className of classNames) {
  const expression = new RegExp(
    `^(?:constructor|destructor|procedure|function) ${escapeRegExp(className)}\\.`,
    'gm'
  );
  let match;
  while ((match = expression.exec(source)) !== null) {
    ranges.push({start: match.index, end: routineEnd(source, match.index)});
  }
}

ranges.sort((left, right) => right.start - left.start);
for (const range of ranges) {
  source = source.slice(0, range.start) + source.slice(range.end);
}

fs.writeFileSync(sourcePath, source);
process.stdout.write(
  `Replaced ${classNames.length} declarations and removed ${ranges.length} routines from ${sourceName}.\n`
);
