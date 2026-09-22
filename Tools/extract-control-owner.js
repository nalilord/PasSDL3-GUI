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

function extractDeclaration(source, className) {
  const expression = new RegExp(
    `^  ${escapeRegExp(className)} = class(?:\\([^\\n]+\\))?\\n[\\s\\S]*?^  end;`,
    'm'
  );
  const match = source.match(expression);
  if (!match) {
    fail(`declaration not found: ${className}`);
  }
  return match[0];
}

function routineEnd(source, start) {
  const expression = /^(?:constructor|destructor|procedure|function) [A-Za-z_]/gm;
  expression.lastIndex = start + 1;
  const next = expression.exec(source);
  return next ? next.index : source.length;
}

function extractMethods(source, classNames) {
  const methods = [];
  for (const className of classNames) {
    const expression = new RegExp(
      `^(?:constructor|destructor|procedure|function) ${escapeRegExp(className)}\\.`,
      'gm'
    );
    let match;
    while ((match = expression.exec(source)) !== null) {
      methods.push({
        start: match.index,
        text: source.slice(match.index, routineEnd(source, match.index)).trimEnd()
      });
    }
  }
  methods.sort((left, right) => left.start - right.start);
  return methods.map(method => method.text).join('\n\n');
}

function patchLines(prefix, value) {
  return value.split('\n').map(line => prefix + line).join('\n');
}

const [, , targetName, classList, importList] = process.argv;
if (!targetName || !classList || !importList) {
  fail('use: extract-control-owner.js <target.pas> <class,...> <import,...>');
}

const root = path.resolve(__dirname, '..');
const sourcePath = path.join(root, 'Source', 'PasSDL3.GUI.Core.pas');
const targetPath = path.resolve(root, targetName);
const source = fs.readFileSync(sourcePath, 'utf8').replace(/\r\n/g, '\n');
const previous = fs.readFileSync(targetPath, 'utf8').replace(/\r\n/g, '\n');
const classNames = classList.split(',').filter(Boolean);
const imports = importList.split(',').filter(Boolean);
const unitName = path.basename(targetPath, '.pas');
const declarations = classNames.map(name => extractDeclaration(source, name)).join('\n\n');
const methods = extractMethods(source, classNames);

const generated = [
  `unit ${unitName};`,
  '',
  '{$IFDEF FPC}',
  '  {$MODE DELPHI}',
  '{$ENDIF}',
  '',
  'interface',
  '',
  'uses',
  imports.map((name, index) => `  ${name}${index + 1 === imports.length ? ';' : ','}`).join('\n'),
  '',
  'type',
  declarations,
  '',
  'implementation',
  '',
  methods,
  '',
  'end.',
  ''
].join('\n');

process.stdout.write([
  '*** Begin Patch',
  `*** Update File: ${targetPath}`,
  '@@',
  patchLines('-', previous.replace(/\n$/, '')),
  patchLines('+', generated.replace(/\n$/, '')),
  '*** End Patch',
  ''
].join('\n'));
