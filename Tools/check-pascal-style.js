#!/usr/bin/env node

'use strict';

const fs = require('fs');
const path = require('path');

const MAX_LINE_LENGTH = 160;
const OPERATOR_KEYWORDS = new Set([
  'and', 'or', 'not', 'xor', 'shl', 'shr', 'div', 'mod', 'in', 'is', 'as'
]);
const PASCAL_EXTENSIONS = new Set(['.pas', '.dpr', '.dpk', '.lpr']);
const DEFAULT_ROOTS = ['Source', 'Tests', 'Examples'];
const DEFAULT_EXCLUDED_PARTS = new Set([
  'Bin', 'Lib', 'Unicode', 'StyleFixtures', 'DependencyFixtures'
]);

function usage() {
  process.stderr.write(
    'Usage: node Tools/check-pascal-style.js [--report-only] [--self-test] [path ...]\n'
  );
}

function collectFiles(entry, result) {
  if (!fs.existsSync(entry)) {
    throw new Error(`Path does not exist: ${entry}`);
  }

  const stat = fs.statSync(entry);
  if (stat.isDirectory()) {
    for (const name of fs.readdirSync(entry).sort()) {
      if (DEFAULT_EXCLUDED_PARTS.has(name)) {
        continue;
      }
      collectFiles(path.join(entry, name), result);
    }
    return;
  }

  if (PASCAL_EXTENSIONS.has(path.extname(entry).toLowerCase())) {
    result.push(entry);
  }
}

function tokenize(source) {
  const tokens = [];
  let index = 0;
  let line = 1;
  let column = 1;

  function advance(count) {
    for (let offset = 0; offset < count; offset++) {
      if (source[index] === '\n') {
        line++;
        column = 1;
      } else {
        column++;
      }
      index++;
    }
  }

  function skipLineComment() {
    while ((index < source.length) && (source[index] !== '\n')) {
      advance(1);
    }
  }

  function skipBraceComment() {
    advance(1);
    while (index < source.length) {
      if (source[index] === '}') {
        advance(1);
        return;
      }
      advance(1);
    }
  }

  function skipParenComment() {
    advance(2);
    while (index < source.length) {
      if ((source[index] === '*') && (source[index + 1] === ')')) {
        advance(2);
        return;
      }
      advance(1);
    }
  }

  function skipString() {
    advance(1);
    while (index < source.length) {
      if (source[index] === "'") {
        if (source[index + 1] === "'") {
          advance(2);
        } else {
          advance(1);
          return;
        }
      } else {
        advance(1);
      }
    }
  }

  while (index < source.length) {
    const char = source[index];

    if (/\s/.test(char)) {
      advance(1);
      continue;
    }
    if ((char === '/') && (source[index + 1] === '/')) {
      skipLineComment();
      continue;
    }
    if (char === '{') {
      skipBraceComment();
      continue;
    }
    if ((char === '(') && (source[index + 1] === '*')) {
      skipParenComment();
      continue;
    }
    if (char === "'") {
      skipString();
      continue;
    }

    const start = index;
    const tokenLine = line;
    const tokenColumn = column;

    if (/[A-Za-z_]/.test(char)) {
      advance(1);
      while ((index < source.length) && /[A-Za-z0-9_]/.test(source[index])) {
        advance(1);
      }
      tokens.push({
        kind: 'identifier',
        value: source.slice(start, index),
        lower: source.slice(start, index).toLowerCase(),
        start,
        end: index,
        line: tokenLine,
        column: tokenColumn
      });
      continue;
    }

    if (/[0-9]/.test(char)) {
      advance(1);
      while ((index < source.length) && /[A-Za-z0-9_.]/.test(source[index])) {
        advance(1);
      }
      tokens.push({
        kind: 'number',
        value: source.slice(start, index),
        lower: source.slice(start, index).toLowerCase(),
        start,
        end: index,
        line: tokenLine,
        column: tokenColumn
      });
      continue;
    }

    const pair = source.slice(index, index + 2);
    if ([':=', '<=', '>=', '<>', '..', '+=', '-='].includes(pair)) {
      advance(2);
      tokens.push({
        kind: 'symbol', value: pair, lower: pair, start, end: index,
        line: tokenLine, column: tokenColumn
      });
      continue;
    }

    advance(1);
    tokens.push({
      kind: 'symbol', value: char, lower: char, start, end: index,
      line: tokenLine, column: tokenColumn
    });
  }

  return tokens;
}

function sanitizedLines(source) {
  const output = source.split('');
  let index = 0;
  let state = 'code';

  function blank(position) {
    if (output[position] !== '\n' && output[position] !== '\r') {
      output[position] = ' ';
    }
  }

  while (index < source.length) {
    if (state === 'code') {
      if ((source[index] === '/') && (source[index + 1] === '/')) {
        blank(index++);
        blank(index++);
        state = 'line';
      } else if (source[index] === '{') {
        blank(index++);
        state = 'brace';
      } else if ((source[index] === '(') && (source[index + 1] === '*')) {
        blank(index++);
        blank(index++);
        state = 'paren';
      } else if (source[index] === "'") {
        blank(index++);
        state = 'string';
      } else {
        index++;
      }
    } else if (state === 'line') {
      if (source[index] === '\n') {
        state = 'code';
        index++;
      } else {
        blank(index++);
      }
    } else if (state === 'brace') {
      if (source[index] === '}') {
        blank(index++);
        state = 'code';
      } else {
        blank(index++);
      }
    } else if (state === 'paren') {
      if ((source[index] === '*') && (source[index + 1] === ')')) {
        blank(index++);
        blank(index++);
        state = 'code';
      } else {
        blank(index++);
      }
    } else if (state === 'string') {
      if (source[index] === "'") {
        blank(index++);
        if (source[index] === "'") {
          blank(index++);
        } else {
          state = 'code';
        }
      } else {
        blank(index++);
      }
    }
  }

  return output.join('').split(/\r?\n/);
}

function addViolation(violations, file, line, column, rule, message) {
  violations.push({ file, line, column, rule, message });
}

function inspectFile(file) {
  const source = fs.readFileSync(file, 'utf8');
  const physicalLines = source.split(/\r?\n/);
  const codeLines = sanitizedLines(source);
  const tokens = tokenize(source);
  const violations = [];

  for (let index = 0; index < physicalLines.length; index++) {
    if (physicalLines[index].length > MAX_LINE_LENGTH) {
      addViolation(
        violations, file, index + 1, MAX_LINE_LENGTH + 1, 'line-length',
        `line has ${physicalLines[index].length} characters; maximum is ${MAX_LINE_LENGTH}`
      );
    }
  }

  for (let index = 0; index < tokens.length; index++) {
    const token = tokens[index];

    if (token.kind === 'identifier' && OPERATOR_KEYWORDS.has(token.lower) &&
        token.value !== token.value.toUpperCase()) {
      addViolation(
        violations, file, token.line, token.column, 'operator-case',
        `${token.value} must be uppercase in code`
      );
    }

    if (token.value === ':=') {
      const before = source[token.start - 1] || '';
      const after = source[token.end] || '';
      if (/\s/.test(before) || /\s/.test(after)) {
        addViolation(
          violations, file, token.line, token.column, 'assignment-spacing',
          'do not place whitespace around :='
        );
      }
    }

    if ((token.value === '&') && tokens[index + 1] &&
        (tokens[index + 1].kind === 'identifier') &&
        (tokens[index + 1].start === token.end)) {
      addViolation(
        violations, file, token.line, token.column, 'escaped-identifier',
        'use a meaningful non-reserved identifier instead of &name'
      );
    }

    if ((token.kind === 'identifier') && ['goto', 'label'].includes(token.lower)) {
      addViolation(
        violations, file, token.line, token.column, 'label-or-goto',
        `${token.value} requires a documented measured hot-path exception`
      );
    }
  }

  let beginDepth = 0;
  const executableSemicolons = new Map();
  for (let index = 0; index < tokens.length; index++) {
    const token = tokens[index];
    const previous = tokens[index - 1];

    if ((token.kind === 'identifier') && (token.lower === 'end')) {
      beginDepth = Math.max(0, beginDepth - 1);
    }

    if ((token.kind === 'identifier') && (token.lower === 'var') &&
        ((beginDepth > 0) || (previous && previous.lower === 'for'))) {
      addViolation(
        violations, file, token.line, token.column, 'inline-var',
        'inline variable declarations are prohibited'
      );
    }

    if ((token.value === ';') && (beginDepth > 0) &&
        (!previous || previous.lower !== 'end')) {
      executableSemicolons.set(token.line, (executableSemicolons.get(token.line) || 0) + 1);
    }

    if ((token.kind === 'identifier') && (token.lower === 'begin')) {
      beginDepth++;
    }
  }

  for (const [line, count] of executableSemicolons.entries()) {
    if (count > 1) {
      addViolation(
        violations, file, line, 1, 'multiple-statements',
        `${count} executable statement terminators occur on one line`
      );
    }
  }

  const tokensByLine = new Map();
  for (const token of tokens) {
    if (!tokensByLine.has(token.line)) {
      tokensByLine.set(token.line, []);
    }
    tokensByLine.get(token.line).push(token);
  }
  for (const [line, lineTokens] of tokensByLine.entries()) {
    for (let index = 0; index < lineTokens.length; index++) {
      const token = lineTokens[index];
      if (token.lower === 'begin' && lineTokens.length !== 1) {
        addViolation(
          violations, file, line, token.column, 'block-layout',
          'begin must be on its own line'
        );
      }
      if (token.lower === 'end') {
        const allowed = lineTokens.filter((candidate, candidateIndex) => {
          if (candidateIndex === index) {
            return false;
          }
          return ![';', '.', 'else'].includes(candidate.lower);
        });
        if (allowed.length > 0) {
          addViolation(
            violations, file, line, token.column, 'block-layout',
            'end may share its line only with ;, ., or else'
          );
        }
      }
    }
  }

  let inConst = false;
  for (let index = 0; index < codeLines.length; index++) {
    const line = codeLines[index];
    const trimmed = line.trim();
    if (/^(?:private|protected|public|published)\s+const\b/i.test(trimmed) ||
        /^const\b/i.test(trimmed)) {
      inConst = true;
    } else if (/^(type|var|threadvar|resourcestring|procedure|function|constructor|destructor|implementation|begin)\b/i.test(trimmed)) {
      inConst = false;
    }

    if (inConst) {
      const match = line.match(/^\s*[A-Za-z_][A-Za-z0-9_]*(?:\s*:\s*[^=]+)?\s*=/);
      const equalIndex = match ? line.indexOf('=') : -1;
      if (match && ((equalIndex === 0) || !/\s/.test(line[equalIndex - 1]) ||
          !/\s/.test(line[equalIndex + 1] || ''))) {
        addViolation(
          violations, file, index + 1, equalIndex + 1,
          'constant-spacing', 'place spaces around = in constant declarations'
        );
      }
    }
  }

  const declarationStack = [];
  for (let index = 0; index < codeLines.length; index++) {
    const trimmed = codeLines[index].trim();
    const typeStart = trimmed.match(
      /^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:class(?:\([^)]*\))?|record)\s*$/i
    );
    if (typeStart) {
      declarationStack.push(typeStart[1]);
      continue;
    }
    if (declarationStack.length === 0) {
      continue;
    }
    if (/^end\s*;$/i.test(trimmed)) {
      declarationStack.pop();
      continue;
    }

    const field = trimmed.match(
      /^(?:class\s+var\s+)?([A-Za-z_][A-Za-z0-9_]*(?:\s*,\s*[A-Za-z_][A-Za-z0-9_]*)*)\s*:\s*(.+);$/i
    );
    if (!field || /[);]/.test(field[2])) {
      continue;
    }
    for (const name of field[1].split(/\s*,\s*/)) {
      if (!/^F[A-Z0-9_]/.test(name)) {
        addViolation(
          violations, file, index + 1, codeLines[index].indexOf(name) + 1,
          'field-prefix', `${name} is class/record storage and must use an F prefix`
        );
      }
    }
  }

  return violations;
}

function summarize(violations) {
  const result = new Map();
  for (const violation of violations) {
    result.set(violation.rule, (result.get(violation.rule) || 0) + 1);
  }
  return [...result.entries()].sort((left, right) => left[0].localeCompare(right[0]));
}

function runSelfTest() {
  const valid = path.join('Tests', 'StyleFixtures', 'valid.pas');
  const invalid = path.join('Tests', 'StyleFixtures', 'invalid.pas');
  const validViolations = inspectFile(valid);
  const invalidViolations = inspectFile(invalid);
  const required = new Set([
    'assignment-spacing', 'block-layout', 'constant-spacing',
    'escaped-identifier', 'field-prefix', 'inline-var', 'label-or-goto', 'line-length',
    'multiple-statements', 'operator-case'
  ]);
  const found = new Set(invalidViolations.map(violation => violation.rule));

  if (validViolations.length > 0) {
    process.stderr.write('Valid style fixture produced violations:\n');
    for (const violation of validViolations) {
      process.stderr.write(`${violation.file}:${violation.line}:${violation.column}: ${violation.rule}: ${violation.message}\n`);
    }
    return 1;
  }
  for (const rule of required) {
    if (!found.has(rule)) {
      process.stderr.write(`Invalid style fixture did not exercise ${rule}\n`);
      return 1;
    }
  }
  process.stdout.write(`PASS: style-check fixtures (${required.size} enforced rules)\n`);
  return 0;
}

function main() {
  const args = process.argv.slice(2);
  let reportOnly = false;
  let selfTest = false;
  const entries = [];

  for (const arg of args) {
    if (arg === '--report-only') {
      reportOnly = true;
    } else if (arg === '--self-test') {
      selfTest = true;
    } else if (arg === '--help' || arg === '-h') {
      usage();
      return 0;
    } else if (arg.startsWith('-')) {
      usage();
      throw new Error(`Unknown option: ${arg}`);
    } else {
      entries.push(arg);
    }
  }

  if (selfTest) {
    return runSelfTest();
  }

  const files = [];
  for (const entry of entries.length > 0 ? entries : DEFAULT_ROOTS) {
    collectFiles(entry, files);
  }
  const uniqueFiles = [...new Set(files)].sort();
  const violations = uniqueFiles.flatMap(inspectFile);

  for (const violation of violations) {
    process.stdout.write(
      `${violation.file}:${violation.line}:${violation.column}: ${violation.rule}: ${violation.message}\n`
    );
  }
  process.stdout.write(
    `Style check: ${uniqueFiles.length} files, ${violations.length} violations` +
    (reportOnly ? ' (report only)' : '') + '.\n'
  );
  for (const [rule, count] of summarize(violations)) {
    process.stdout.write(`  ${rule}: ${count}\n`);
  }

  if ((violations.length > 0) && !reportOnly) {
    return 1;
  }
  return 0;
}

try {
  process.exitCode = main();
} catch (error) {
  process.stderr.write(`ERROR: ${error.message}\n`);
  process.exitCode = 2;
}
