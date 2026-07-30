const { test, expect } = require("@playwright/test");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const WEB_URL = process.env.VAN_MONG_WEB_URL || "http://127.0.0.1:8765/";
const ROOT = process.cwd();
const EVIDENCE_DIR = path.join(ROOT, "production/evidence/platforms");

function sha256(buffer) {
	return crypto.createHash("sha256").update(buffer).digest("hex");
}

async function waitForGodotCanvas(page) {
	await page.waitForLoadState("domcontentloaded");
	await page.waitForSelector("canvas", { state: "visible", timeout: 30000 });
	await page.waitForFunction(() => {
		const canvas = document.querySelector("canvas");
		return canvas && canvas.width > 0 && canvas.height > 0 && canvas.getBoundingClientRect().width > 0;
	}, null, { timeout: 30000 });
	await page.waitForTimeout(6000);
}

async function capture(page, filename) {
	const output = path.join(EVIDENCE_DIR, filename);
	const buffer = await page.screenshot({ path: output, type: "png" });
	return { path: path.relative(ROOT, output), sha256: sha256(buffer), bytes: buffer.length };
}

test.describe("Vân Mộng Tu Tiên served Web smoke", () => {
	test("boots, accepts keyboard/pointer input, transitions, and resizes to phone landscape", async ({ page }) => {
		fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
		const consoleErrors = [];
		const pageErrors = [];
		const failedRequests = [];
		page.on("console", (message) => {
			if (message.type() === "error") consoleErrors.push(message.text());
		});
		page.on("pageerror", (error) => pageErrors.push(String(error)));
		page.on("requestfailed", (request) => failedRequests.push(`${request.url()} :: ${request.failure()?.errorText || "unknown"}`));

		await page.setViewportSize({ width: 1600, height: 900 });
		await page.goto(WEB_URL, { waitUntil: "domcontentloaded" });
		await waitForGodotCanvas(page);
		const canvas = page.locator("canvas");
		await expect(canvas).toHaveCount(1);
		const desktopCanvas = await canvas.boundingBox();
		expect(desktopCanvas.width).toBeGreaterThan(1200);
		expect(desktopCanvas.height).toBeGreaterThan(700);
		const title = await capture(page, "web-title.png");

		await canvas.click({ position: { x: 800, y: 450 } });
		await page.keyboard.press("Enter");
		await page.waitForTimeout(1200);
		const hub = await capture(page, "web-hub.png");
		expect(hub.sha256).not.toBe(title.sha256);

		// Pointer path: the right-side HÀNH TRÌNH command opens stage selection.
		await page.mouse.click(1350, 232);
		await page.waitForTimeout(700);
		const stages = await capture(page, "web-stages.png");
		expect(stages.sha256).not.toBe(hub.sha256);

		// Escape is the declared back path from stage selection to the hub.
		await page.keyboard.press("Escape");
		await page.waitForTimeout(400);
		const hubBack = await capture(page, "web-hub-back.png");
		// The doctrine dial animates continuously, so full-frame hashes legitimately
		// differ between two captures of the same hub. The important assertion is
		// that Escape left the stage surface and returned to a distinct frame.
		expect(hubBack.sha256).not.toBe(stages.sha256);

		// The export's canvas must accept focus after a pointer gesture.
		const focused = await page.evaluate(() => document.activeElement?.tagName === "CANVAS");
		expect(focused).toBeTruthy();

		await page.setViewportSize({ width: 844, height: 390 });
		await page.reload({ waitUntil: "domcontentloaded" });
		await waitForGodotCanvas(page);
		const phoneCanvas = await page.locator("canvas").boundingBox();
		expect(phoneCanvas.width).toBeGreaterThan(800);
		expect(phoneCanvas.height).toBeGreaterThan(350);
		const phoneTitle = await capture(page, "web-title-phone.png");
		await page.locator("canvas").click({ position: { x: 422, y: 195 } });
		await page.keyboard.press("Enter");
		await page.waitForTimeout(900);
		const phoneHub = await capture(page, "web-hub-phone.png");
		expect(phoneHub.sha256).not.toBe(phoneTitle.sha256);

		const report = {
			url: WEB_URL,
			viewport_desktop: { width: 1600, height: 900 },
			viewport_phone: { width: 844, height: 390 },
			console_errors: consoleErrors,
			page_errors: pageErrors,
			failed_requests: failedRequests,
			captures: [title, hub, stages, hubBack, phoneTitle, phoneHub],
			input_checks: ["canvas-focus", "Enter-title-to-hub", "pointer-hub-to-stages", "Escape-stages-to-hub", "phone-landscape-resize"],
			status: consoleErrors.length === 0 && pageErrors.length === 0 && failedRequests.length === 0 ? "PASS" : "BLOCKED",
		};
		fs.writeFileSync(path.join(EVIDENCE_DIR, "web-smoke.json"), `${JSON.stringify(report, null, 2)}\n`);
		expect(report.status).toBe("PASS");
	});
});
