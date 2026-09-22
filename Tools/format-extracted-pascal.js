#!/usr/bin/env node

'use strict';

const fs = require('fs');

const OPERATOR_KEYWORDS = new Set([
  'and', 'or', 'not', 'xor', 'shl', 'shr', 'div', 'mod', 'in', 'is', 'as'
]);
const BLOCK_KEYWORDS = new Set(['begin', 'try', 'finally', 'except']);

function tokenize(source) {
  const tokens = [];
  let index = 0;
  let line = 1;

  function advance(count) {
    for (let offset = 0; offset < count; offset++) {
      if (source[index] === '\n') {
        line++;
      }
      index++;
    }
  }

  while (index < source.length) {
    const character = source[index];
    if (/\s/.test(character)) {
      advance(1);
    } else if ((character === '/') && (source[index + 1] === '/')) {
      while ((index < source.length) && (source[index] !== '\n')) {
        advance(1);
      }
    } else if (character === '{') {
      advance(1);
      while ((index < source.length) && (source[index] !== '}')) {
        advance(1);
      }
      if (index < source.length) {
        advance(1);
      }
    } else if ((character === '(') && (source[index + 1] === '*')) {
      advance(2);
      while ((index < source.length) &&
        !((source[index] === '*') && (source[index + 1] === ')'))) {
        advance(1);
      }
      if (index < source.length) {
        advance(2);
      }
    } else if (character === "'") {
      advance(1);
      while (index < source.length) {
        if (source[index] !== "'") {
          advance(1);
        } else if (source[index + 1] === "'") {
          advance(2);
        } else {
          advance(1);
          break;
        }
      }
    } else {
      const start = index;
      const tokenLine = line;
      if (/[A-Za-z_]/.test(character)) {
        advance(1);
        while ((index < source.length) && /[A-Za-z0-9_]/.test(source[index])) {
          advance(1);
        }
      } else if (source.slice(index, index + 2) === ':=') {
        advance(2);
      } else {
        advance(1);
      }
      const value = source.slice(start, index);
      tokens.push({
        start,
        end: index,
        line: tokenLine,
        value,
        lower: value.toLowerCase()
      });
    }
  }
  return tokens;
}

function applyReplacements(source, replacements) {
  replacements.sort((left, right) => right.start - left.start);
  for (const replacement of replacements) {
    source = source.slice(0, replacement.start) + replacement.value +
      source.slice(replacement.end);
  }
  return source;
}

function normalizeTokens(source) {
  const replacements = [];
  for (const token of tokenize(source)) {
    if (OPERATOR_KEYWORDS.has(token.lower) && (token.value !== token.value.toUpperCase())) {
      replacements.push({
        start: token.start,
        end: token.end,
        value: token.value.toUpperCase()
      });
    } else if (token.value === ':=') {
      let start = token.start;
      let end = token.end;
      while ((start > 0) && ((source[start - 1] === ' ') || (source[start - 1] === '\t'))) {
        start--;
      }
      while ((end < source.length) && ((source[end] === ' ') || (source[end] === '\t'))) {
        end++;
      }
      replacements.push({start, end, value: ':='});
    }
  }
  return applyReplacements(source, replacements);
}

function lineIndent(source, position) {
  const start = source.lastIndexOf('\n', position - 1) + 1;
  const match = source.slice(start, position).match(/^[ \t]*/);
  return match ? match[0].replace(/\t/g, '  ') : '';
}

function splitCompactBlocks(source) {
  const tokens = tokenize(source);
  const changes = new Map();
  let parenthesisDepth = 0;
  const implementationPosition = source.toLowerCase().indexOf('\nimplementation');

  function replaceGap(start, end, value) {
    const gap = source.slice(start, end);
    if ((start === end) || /^\s*$/.test(gap)) {
      changes.set(`${start}:${end}`, {start, end, value});
    }
  }

  for (let index = 0; index < tokens.length; index++) {
    const token = tokens[index];
    const previous = index > 0 ? tokens[index - 1] : null;
    const next = index + 1 < tokens.length ? tokens[index + 1] : null;
    if (token.value === '(' || token.value === '[') {
      parenthesisDepth++;
    } else if (token.value === ')' || token.value === ']') {
      parenthesisDepth=Math.max(0, parenthesisDepth - 1);
    }

    const indent = lineIndent(source, token.start);
    if (BLOCK_KEYWORDS.has(token.lower)) {
      if (previous && (previous.line === token.line)) {
        replaceGap(previous.end, token.start, `\n${indent}`);
      }
      if (next && (next.line === token.line)) {
        replaceGap(token.end, next.start, `\n${indent}  `);
      }
    } else if (token.lower === 'end') {
      if (previous && (previous.line === token.line)) {
        replaceGap(previous.end, token.start, `\n${indent}`);
      }
      if (next && (next.line === token.line) &&
        ![';', '.', 'else'].includes(next.lower)) {
        replaceGap(token.end, next.start, `\n${indent}`);
      }
    } else if ((token.value === ';') && (token.start > implementationPosition) &&
      (parenthesisDepth === 0) && next && (next.line === token.line)) {
      const lineStart = source.lastIndexOf('\n', token.start - 1) + 1;
      const lineBefore = source.slice(lineStart, token.start).toLowerCase();
      const extra = /\b(begin|try|finally|except)\b/.test(lineBefore) ? '  ' : '';
      replaceGap(token.end, next.start, `\n${indent}${extra}`);
    }
  }

  return applyReplacements(source, [...changes.values()]);
}

function cleanLines(source) {
  return source.split('\n')
    .map(line => line.replace(/[ \t]+$/g, ''))
    .join('\n')
    .replace(/\n{3,}/g, '\n\n');
}

const files = process.argv.slice(2);
if (files.length === 0) {
  process.stderr.write('Use: format-extracted-pascal.js <file.pas> [...]\n');
  process.exit(1);
}

for (const file of files) {
  let source = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
  source = normalizeTokens(source);
  source = splitCompactBlocks(source);
  source = cleanLines(source);
  fs.writeFileSync(file, source.endsWith('\n') ? source : source + '\n');
}
