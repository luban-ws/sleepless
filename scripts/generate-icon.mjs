#!/usr/bin/env node
/**
 * 生成 Sleepless 应用图标：1024×1024，无重复图案，适合 macOS AppIcon。
 * 设计：深色圆角底 + 月牙（保持清醒）+ 小星点，简洁易识别。
 */

import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import sharp from "sharp";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SIZE = 1024;
const OUT = path.join(__dirname, "..", "Resources", "icon_1024.png");

function setPixel(buf, x, y, r, g, b, a) {
  if (x < 0 || x >= SIZE || y < 0 || y >= SIZE) return;
  const i = (y * SIZE + x) * 4;
  buf[i] = r;
  buf[i + 1] = g;
  buf[i + 2] = b;
  buf[i + 3] = a;
}

function inCircle(x, y, cx, cy, r) {
  return (x - cx) ** 2 + (y - cy) ** 2 <= r * r;
}

function inRoundedRect(x, y, margin, radius) {
  const left = margin;
  const right = SIZE - margin;
  const top = margin;
  const bottom = SIZE - margin;
  const r = radius;
  const cx1 = left + r;
  const cy1 = top + r;
  const cx2 = right - r;
  const cy2 = top + r;
  const cx3 = right - r;
  const cy3 = bottom - r;
  const cx4 = left + r;
  const cy4 = bottom - r;
  if (x >= left + r && x <= right - r && y >= top && y <= bottom) return true;
  if (y >= top + r && y <= bottom - r && x >= left && x <= right) return true;
  if (inCircle(x, y, cx1, cy1, r)) return true;
  if (inCircle(x, y, cx2, cy2, r)) return true;
  if (inCircle(x, y, cx3, cy3, r)) return true;
  if (inCircle(x, y, cx4, cy4, r)) return true;
  return false;
}

async function main() {
  const buf = Buffer.alloc(SIZE * SIZE * 4);

  // 背景：深蓝灰圆角矩形（macOS 风格，无纹理）
  const margin = Math.floor(SIZE * 0.06);
  const radius = Math.floor(SIZE * 0.24);
  const bg = [28, 31, 45, 255]; // 略偏蓝的深色

  // 月牙：外白内裁，比例适合小尺寸辨认
  const cx = SIZE >> 1;
  const cy = SIZE >> 1;
  const rOuter = Math.floor(SIZE * 0.36);
  const rInner = Math.floor(SIZE * 0.28);
  const offX = Math.floor(SIZE * 0.07);
  const offY = Math.floor(SIZE * 0.05);
  const white = [255, 255, 255, 255];

  // 小星点（右上）：表示「清醒」，暖色
  const starCx = Math.floor(SIZE * 0.72);
  const starCy = Math.floor(SIZE * 0.26);
  const starR = Math.floor(SIZE * 0.065);
  const starColor = [255, 218, 120, 255];

  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      if (inRoundedRect(x, y, margin, radius)) {
        setPixel(buf, x, y, ...bg);
      }
      if (inCircle(x, y, cx, cy, rOuter)) {
        setPixel(buf, x, y, ...white);
      }
      if (inCircle(x, y, cx + offX, cy + offY, rInner)) {
        setPixel(buf, x, y, ...bg);
      }
      if (inCircle(x, y, starCx, starCy, starR)) {
        setPixel(buf, x, y, ...starColor);
      }
    }
  }

  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  await sharp(buf, { raw: { width: SIZE, height: SIZE, channels: 4 } })
    .png()
    .toFile(OUT);
  console.log("已生成:", OUT);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
