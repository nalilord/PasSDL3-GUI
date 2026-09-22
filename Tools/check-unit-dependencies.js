#!/usr/bin/env node

'use strict';

const fs = require('fs');
const path = require('path');

const SOURCE_DIR = 'Source';
const TARGETS = ['delphi', 'fpc'];
const AGGREGATES = new Set(['pasSDL3.gui'.toLowerCase(), 'pasSDL3.gui.controls'.toLowerCase()]);
const FOUNDATION_UNITS = new Set([
  'pasSDL3.gui.core',
  'pasSDL3.gui.types',
  'pasSDL3.gui.text',
  'pasSDL3.gui.grapheme',
  'pasSDL3.gui.statestrings',
  'pasSDL3.gui.renderer.canvas',
  'pasSDL3.gui.clipboard',
  'pasSDL3.gui.resources'
].map(name => name.toLowerCase()));
const EXTRACTED_CATEGORIES = new Set([
  'pasSDL3.gui.controls.containers',
  'pasSDL3.gui.controls.text',
  'pasSDL3.gui.controls.buttons',
  'pasSDL3.gui.controls.lists',
  'pasSDL3.gui.controls.pages',
  'pasSDL3.gui.controls.menus',
  'pasSDL3.gui.controls.bars',
  'pasSDL3.gui.controls.dialogs',
  'pasSDL3.gui.controls.range',
  'pasSDL3.gui.controls.images',
  'pasSDL3.gui.controls.progress',
  'pasSDL3.gui.controls.charts'
].map(name => name.toLowerCase()));
const INTEGRATION_UNITS = new Set([
  'pasSDL3.gui',
  'pasSDL3.gui.host.sdl3',
  'pasSDL3.gui.input.sdl3',
  'pasSDL3.gui.loader.xml',
  'pasSDL3.gui.renderer.sdl3',
  'pasSDL3.gui.theme',
  'pasSDL3.gui.theme.files'
].map(name => name.toLowerCase()));

function preprocess(source, target) {
  const active = [true];
  const conditions = [];
  const fpc = target === 'fpc';
  const lines = source.split(/\r?\n/);
  const output = [];

  for (const line of lines) {
    const directive = line.match(/^\s*\{\$\s*(IFDEF|IFNDEF|ELSE|ENDIF)\s*([A-Za-z0-9_]*)\s*\}\s*$/i);
    if (directive) {
      const kind = directive[1].toUpperCase();
      const symbol = directive[2].toUpperCase();
      if (kind === 'IFDEF' || kind === 'IFNDEF') {
        let condition = symbol === 'FPC' ? fpc : false;
        if (kind === 'IFNDEF') {
          condition = !condition;
        }
        conditions.push(condition);
        active.push(active[active.length - 1] && condition);
      } else if (kind === 'ELSE') {
        if (conditions.length === 0) {
          throw new Error('Unmatched {$ELSE}');
        }
        const parentActive = active[active.length - 2];
        conditions[conditions.length - 1] = !conditions[conditions.length - 1];
        active[active.length - 1] = parentActive && conditions[conditions.length - 1];
      } else {
        if (conditions.length === 0) {
          throw new Error('Unmatched {$ENDIF}');
        }
        conditions.pop();
        active.pop();
      }
      output.push('');
    } else {
      output.push(active[active.length - 1] ? line : '');
    }
  }

  if (conditions.length !== 0) {
    throw new Error('Unclosed conditional directive');
  }
  return output.join('\n');
}

function stripCommentsAndStrings(source) {
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
        index++;
        state = 'code';
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

  return output.join('');
}

function parseUnit(source, target, file = '<memory>') {
  const activeSource = preprocess(source, target);
  const clean = stripCommentsAndStrings(activeSource);
  const unitMatch = clean.match(/^\s*unit\s+([A-Za-z0-9_.]+)\s*;/im);
  if (!unitMatch) {
    throw new Error(`${file}: missing unit declaration`);
  }
  const implementationMatch = /^\s*implementation\b/im.exec(clean);
  if (!implementationMatch) {
    throw new Error(`${file}: missing implementation section`);
  }
  const interfaceText = clean.slice(0, implementationMatch.index);
  const implementationText = clean.slice(implementationMatch.index);

  function parseUses(section) {
    const match = /\buses\b([\s\S]*?);/i.exec(section);
    if (!match) {
      return [];
    }
    return match[1]
      .split(',')
      .map(item => item.trim().match(/^([A-Za-z0-9_.]+)/))
      .filter(Boolean)
      .map(item => item[1]);
  }

  return {
    file,
    name: unitMatch[1],
    key: unitMatch[1].toLowerCase(),
    interfaceUses: parseUses(interfaceText),
    implementationUses: parseUses(implementationText)
  };
}

function loadUnits(target) {
  const units = [];
  for (const name of fs.readdirSync(SOURCE_DIR).sort()) {
    if (!name.toLowerCase().endsWith('.pas')) {
      continue;
    }
    const file = path.join(SOURCE_DIR, name);
    units.push(parseUnit(fs.readFileSync(file, 'utf8'), target, file));
  }
  return units;
}

function isCategory(key) {
  return key.startsWith('pasSDL3.gui.controls.'.toLowerCase());
}

function findCycles(units, includeImplementation) {
  const map = new Map(units.map(unit => [unit.key, unit]));
  const visiting = new Set();
  const visited = new Set();
  const stack = [];
  const cycles = [];
  const keys = [...map.keys()].sort();

  function visit(key) {
    if (visiting.has(key)) {
      const start = stack.indexOf(key);
      cycles.push([...stack.slice(start), key]);
      return;
    }
    if (visited.has(key)) {
      return;
    }

    visiting.add(key);
    stack.push(key);
    const unit = map.get(key);
    const imports = unit.interfaceUses.concat(includeImplementation ? unit.implementationUses : []);
    for (const imported of imports.map(name => name.toLowerCase()).sort()) {
      if (map.has(imported)) {
        visit(imported);
      }
    }
    stack.pop();
    visiting.delete(key);
    visited.add(key);
  }

  for (const key of keys) {
    visit(key);
  }
  return cycles;
}

function inspect(units, target) {
  const violations = [];

  for (const unit of units) {
    const imports = [
      ...unit.interfaceUses.map(name => ({ section: 'interface', name, key: name.toLowerCase() })),
      ...unit.implementationUses.map(name => ({ section: 'implementation', name, key: name.toLowerCase() }))
    ];

    for (const imported of imports) {
      if (isCategory(unit.key) && AGGREGATES.has(imported.key)) {
        violations.push(`${target}: ${unit.name} ${imported.section} imports aggregate ${imported.name}`);
      }
      if (FOUNDATION_UNITS.has(unit.key) &&
          (isCategory(imported.key) || AGGREGATES.has(imported.key) ||
           imported.key === 'pasSDL3.gui.context'.toLowerCase())) {
        violations.push(`${target}: foundation ${unit.name} ${imported.section} imports ${imported.name}`);
      }
      if (isCategory(unit.key) && INTEGRATION_UNITS.has(imported.key)) {
        violations.push(`${target}: category ${unit.name} ${imported.section} imports integration unit ${imported.name}`);
      }
    }
  }

  for (const cycle of findCycles(units, false)) {
    violations.push(`${target}: interface dependency cycle: ${cycle.join(' -> ')}`);
  }
  for (const cycle of findCycles(units, true)) {
    violations.push(`${target}: combined dependency cycle: ${cycle.join(' -> ')}`);
  }

  return violations;
}

function runSelfTest() {
  const sample = `unit Fixture.Sample;
{$IFDEF FPC}
interface
uses Fixture.FpcOnly;
{$ELSE}
interface
uses Fixture.DelphiOnly;
{$ENDIF}
implementation
uses Fixture.Shared;
end.`;
  const fpc = parseUnit(sample, 'fpc');
  const delphi = parseUnit(sample, 'delphi');
  if (fpc.interfaceUses.join(',') !== 'Fixture.FpcOnly' ||
      delphi.interfaceUses.join(',') !== 'Fixture.DelphiOnly' ||
      fpc.implementationUses.join(',') !== 'Fixture.Shared' ||
      delphi.implementationUses.join(',') !== 'Fixture.Shared') {
    process.stderr.write('Dependency parser conditional/import self-test failed.\n');
    return 1;
  }

  const cycleA = parseUnit(
    'unit Fixture.A;\ninterface\nuses Fixture.B;\nimplementation\nend.', 'delphi'
  );
  const cycleB = parseUnit(
    'unit Fixture.B;\ninterface\nuses Fixture.A;\nimplementation\nend.', 'delphi'
  );
  if (findCycles([cycleA, cycleB], false).length === 0) {
    process.stderr.write('Dependency parser cycle self-test failed.\n');
    return 1;
  }

  process.stdout.write('PASS: dependency parser conditional, section, and cycle fixtures\n');
  return 0;
}

function printGraph(units, target) {
  for (const unit of units) {
    process.stdout.write(
      `${target}\t${unit.name}\tinterface=[${unit.interfaceUses.join(', ')}]` +
      `\timplementation=[${unit.implementationUses.join(', ')}]\n`
    );
  }
}

function main() {
  const args = process.argv.slice(2);
  const selfTest = args.includes('--self-test');
  const showGraph = args.includes('--graph');
  const unknown = args.filter(arg => !['--self-test', '--graph', '--help', '-h'].includes(arg));
  if (args.includes('--help') || args.includes('-h')) {
    process.stderr.write('Usage: node Tools/check-unit-dependencies.js [--self-test] [--graph]\n');
    return 0;
  }
  if (unknown.length > 0) {
    throw new Error(`Unknown option: ${unknown[0]}`);
  }
  if (selfTest) {
    return runSelfTest();
  }

  const violations = [];
  for (const target of TARGETS) {
    const units = loadUnits(target);
    if (showGraph) {
      printGraph(units, target);
    }
    violations.push(...inspect(units, target));
  }

  if (violations.length > 0) {
    for (const violation of violations) {
      process.stderr.write(`${violation}\n`);
    }
    process.stderr.write(`Dependency check failed: ${violations.length} violation(s).\n`);
    return 1;
  }
  process.stdout.write('PASS: Delphi/FPC unit dependencies satisfy current layering rules\n');
  return 0;
}

try {
  process.exitCode = main();
} catch (error) {
  process.stderr.write(`ERROR: ${error.message}\n`);
  process.exitCode = 2;
}
