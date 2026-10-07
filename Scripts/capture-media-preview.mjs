/**
 * Capture design-faithful UI previews + short walkthrough GIF for docs/media/.
 * Uses Playwright from career-ops (same path as RuralTouch capture script).
 */
import { createRequire } from "module";
import { mkdir, copyFile } from "fs/promises";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { spawnSync } from "child_process";

const require = createRequire(import.meta.url);
const { chromium } = require(
  "E:/项目/.demo/简历制作/JD求职工具/career-ops/node_modules/playwright"
);

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const OUT = join(ROOT, "docs", "media");
const HTML = join(OUT, "preview.html");
const FFMPEG =
  process.env.FFMPEG ||
  "C:/Users/hexinying/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-8.1.1-full_build/bin/ffmpeg.exe";

async function shot(page, name, screen) {
  await page.goto(`file://${HTML.replace(/\\/g, "/")}?screen=${screen}`, {
    waitUntil: "networkidle",
  });
  await page.setViewportSize({ width: 460, height: 920 });
  const phone = page.locator(`#${screen}`);
  await phone.waitFor({ state: "visible" });
  await phone.screenshot({ path: join(OUT, name) });
  console.log("saved", name);
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await shot(page, "dashboard.png", "dashboard");
  await shot(page, "chat-modes.png", "chat");
  await shot(page, "page-generated.png", "page");

  // Copy brand icon as optional asset
  const icon = join(
    ROOT,
    "Modules/iOS_Profile/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"
  );
  try {
    await copyFile(icon, join(OUT, "app-icon.png"));
    console.log("saved app-icon.png");
  } catch {
    console.log("skip app-icon.png");
  }

  await browser.close();

  // ~4.5s looping GIF via concat demuxer
  const { writeFileSync } = require("fs");
  const listPath = join(OUT, "gif-list.txt");
  writeFileSync(
    listPath,
    [
      "file 'dashboard.png'",
      "duration 1.5",
      "file 'chat-modes.png'",
      "duration 1.5",
      "file 'page-generated.png'",
      "duration 1.5",
      "file 'page-generated.png'",
      "",
    ].join("\n")
  );
  const gif = join(OUT, "walkthrough.gif");
  const args = [
    "-y",
    "-f",
    "concat",
    "-safe",
    "0",
    "-i",
    listPath,
    "-vf",
    "fps=8,scale=390:-1:flags=lanczos",
    "-loop",
    "0",
    gif,
  ];
  const r = spawnSync(FFMPEG, args, { encoding: "utf8", cwd: OUT });
  if (r.status === 0) console.log("saved walkthrough.gif");
  else {
    console.error(r.stderr || r.stdout || "ffmpeg failed");
    process.exitCode = 1;
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
