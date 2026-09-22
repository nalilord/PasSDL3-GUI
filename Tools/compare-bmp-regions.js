#!/usr/bin/env node

'use strict';

const crypto = require('crypto');
const fs = require('fs');

function fail(message) {
  process.stderr.write(`ERROR: ${message}\n`);
  process.exit(1);
}

function load(fileName) {
  const data = fs.readFileSync(fileName);
  if (data.toString('ascii', 0, 2) !== 'BM') {
    fail(`${fileName}: not a BMP file`);
  }
  const offset = data.readUInt32LE(10);
  const width = data.readInt32LE(18);
  const signedHeight = data.readInt32LE(22);
  const bits = data.readUInt16LE(28);
  const compression = data.readUInt32LE(30);
  const standardBitfields = (bits === 32) && (compression === 3) &&
    (data.readUInt32LE(54) === 0x00ff0000) &&
    (data.readUInt32LE(58) === 0x0000ff00) &&
    (data.readUInt32LE(62) === 0x000000ff);
  if ((width <= 0) || (signedHeight === 0) ||
      ((bits !== 24) && (bits !== 32)) ||
      ((compression !== 0) && !standardBitfields)) {
    fail(`${fileName}: unsupported BMP format`);
  }
  const height = Math.abs(signedHeight);
  const bytes = bits / 8;
  const stride = Math.ceil(width * bytes / 4) * 4;
  return {data, offset, width, height, bytes, stride, bottomUp: signedHeight > 0};
}

function pixelOffset(bitmap, x, y) {
  const row = bitmap.bottomUp ? bitmap.height - 1 - y : y;
  return bitmap.offset + row * bitmap.stride + x * bitmap.bytes;
}

const [, , firstName, secondName, xText, yText, widthText, heightText] = process.argv;
if (!firstName || !secondName) {
  fail('use: compare-bmp-regions.js <first.bmp> <second.bmp> [x y width height]');
}

const first = load(firstName);
const second = load(secondName);
if ((first.width !== second.width) || (first.height !== second.height)) {
  fail('image dimensions differ');
}

const x = xText === undefined ? 0 : Number(xText);
const y = yText === undefined ? 0 : Number(yText);
const width = widthText === undefined ? first.width : Number(widthText);
const height = heightText === undefined ? first.height : Number(heightText);
if (![x, y, width, height].every(Number.isInteger) || (x < 0) || (y < 0) ||
    (width < 1) || (height < 1) || (x + width > first.width) ||
    (y + height > first.height)) {
  fail('invalid comparison rectangle');
}

const firstHash = crypto.createHash('md5');
const secondHash = crypto.createHash('md5');
let differences = 0;
let minX = first.width;
let minY = first.height;
let maxX = -1;
let maxY = -1;

for (let row = y; row < y + height; row++) {
  for (let column = x; column < x + width; column++) {
    const firstOffset = pixelOffset(first, column, row);
    const secondOffset = pixelOffset(second, column, row);
    const firstPixel = first.data.subarray(firstOffset, firstOffset + 3);
    const secondPixel = second.data.subarray(secondOffset, secondOffset + 3);
    firstHash.update(firstPixel);
    secondHash.update(secondPixel);
    if (!firstPixel.equals(secondPixel)) {
      differences++;
      minX = Math.min(minX, column);
      minY = Math.min(minY, row);
      maxX = Math.max(maxX, column);
      maxY = Math.max(maxY, row);
    }
  }
}

process.stdout.write(`first\t${firstHash.digest('hex')}\n`);
process.stdout.write(`second\t${secondHash.digest('hex')}\n`);
process.stdout.write(`different-pixels\t${differences}\n`);
if (differences > 0) {
  process.stdout.write(`difference-bounds\t${minX},${minY}-${maxX},${maxY}\n`);
}
