module.exports = {
	testDir: "tests",
	testMatch: "web_smoke.spec.js",
	webServer: {
		command: "python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web",
		url: "http://127.0.0.1:8765/",
		reuseExistingServer: true,
		timeout: 120000,
	},
	use: {
		headless: true,
	},
};
