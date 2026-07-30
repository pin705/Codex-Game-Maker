#!/usr/bin/env ruby

# Rebind the visual-quality contract to the current renderer captures without
# changing review verdicts. Run from the project root after a full recapture.

require "json"
require "digest"

ROOT = File.expand_path("..", __dir__)
CONTRACT_PATH = File.join(ROOT, "production/reviews/visual-quality-contract.json")
MANIFEST_PATH = File.join(ROOT, "production/quality-command-manifest.json")

def digest_for(relative_path)
  absolute = File.join(ROOT, relative_path)
  raise "Missing visual evidence: #{relative_path}" unless File.file?(absolute)
  Digest::SHA256.file(absolute).hexdigest
end

def viewport_for(path)
  return "phone-844x390-simulated" if path.end_with?("-phone.png")
  return "phone-portrait-guard" if path.end_with?("portrait-overlay.png")
  return "ultrawide-simulated" if path.include?("/responsive/")
  "desktop-1600x900"
end

manifest = JSON.parse(File.read(MANIFEST_PATH))
visual_command = manifest.fetch("commands").find { |row| row["id"] == "visual_smoke" }
raise "visual_smoke command missing" unless visual_command
expected_paths = visual_command.fetch("expected_artifacts")
expected_paths.each { |path| digest_for(path) }

contract = JSON.parse(File.read(CONTRACT_PATH))
contract["build"] = "local ignored showcase output; final project fingerprint pending refreshed quality run"
contract["required_viewports"] = [
  {
    "id" => "desktop-1600x900",
    "width" => 1600,
    "height" => 900,
    "device" => "Native desktop reference canvas; served Web rendering still pending"
  },
  {
    "id" => "phone-844x390-simulated",
    "width" => 844,
    "height" => 390,
    "device" => "Renderer-backed device-space phone layout; physical-device sign-off still pending"
  }
]
contract["auxiliary_viewports"] = [
  {"id" => "phone-portrait-guard", "width" => 900, "height" => 1600, "device" => "Simulated portrait guard"},
  {"id" => "ultrawide-simulated", "width" => 2100, "height" => 900, "device" => "Simulated ultra-wide layout"}
]

lookdev = contract.fetch("lookdev")
lookdev["representative_asset_ids"] = [
  "KEYART-001", "HUB-001-van-mong-sect", "HERO-001-idle-side",
  "UIKIT-002-scroll-talisman", "UIKIT-004-talisman-folios",
  "UIKIT-005-restrained-controls", "PREMIUM-001-cultivation-sigils"
]
lookdev["candidate_ids"] = ["lookdev-v3-restrained-runtime", "lookdev-v3-phone-device-space", "lookdev-v2-glossy-dashboard"]
lookdev["accepted_candidate_ids"] = ["lookdev-v3-restrained-runtime", "lookdev-v3-phone-device-space"]
lookdev["rejected_candidate_ids"] = ["lookdev-v2-glossy-dashboard"]
lookdev["candidate_evidence"] = [
  {
    "id" => "lookdev-v3-restrained-runtime",
    "outcome" => "accepted",
    "path" => "production/playtests/frontend/contact-sheet-current-desktop.png",
    "sha256" => digest_for("production/playtests/frontend/contact-sheet-current-desktop.png")
  },
  {
    "id" => "lookdev-v3-phone-device-space",
    "outcome" => "accepted",
    "path" => "production/playtests/frontend/contact-sheet-current-phone.png",
    "sha256" => digest_for("production/playtests/frontend/contact-sheet-current-phone.png")
  },
  {
    "id" => "lookdev-v2-glossy-dashboard",
    "outcome" => "rejected",
    "path" => "production/playtests/frontend/contact-sheet-redesign.png",
    "sha256" => digest_for("production/playtests/frontend/contact-sheet-redesign.png")
  }
]
lookdev["locked_reference_paths"] = [
  "production/playtests/frontend/contact-sheet-current-desktop.png",
  "production/playtests/frontend/contact-sheet-current-phone.png",
  "production/playtests/frontend/title.png",
  "production/playtests/frontend/hub.png",
  "production/playtests/overhaul/gameplay-final.png",
  "production/playtests/overhaul/upgrade-final.png"
]
lookdev["decision_rationale"] = "V3 replaces glossy repeated chrome and the desktop-dashboard hub with restrained matte lacquer, open editorial hierarchy and a dedicated 844x390 device-space composition. The V2 composite is retained only as rejected/superseded comparison evidence."
lookdev["evidence"] = lookdev["locked_reference_paths"]

surface_paths = {
  "title" => ["production/playtests/frontend/title.png", "production/playtests/frontend/title-phone.png"],
  "hub" => ["production/playtests/frontend/hub.png", "production/playtests/frontend/hub-phone.png"],
  "stages" => ["production/playtests/frontend/stages.png", "production/playtests/frontend/stages-phone.png"],
  "loadout" => ["production/playtests/frontend/loadout.png", "production/playtests/frontend/loadout-phone.png"],
  "techniques" => ["production/playtests/frontend/techniques.png", "production/playtests/frontend/techniques-phone.png"],
  "rank-ascension" => ["production/playtests/frontend/technique-upgrade.png", "production/playtests/frontend/technique-upgrade-phone.png"],
  "codex" => ["production/playtests/frontend/codex.png", "production/playtests/frontend/codex-phone.png"],
  "achievements" => ["production/playtests/frontend/achievements.png", "production/playtests/frontend/achievements-phone.png"],
  "settings" => ["production/playtests/frontend/settings.png", "production/playtests/frontend/settings-phone.png"],
  "reset-confirmation" => ["production/playtests/frontend/reset.png", "production/playtests/frontend/reset-phone.png"],
  "combat" => ["production/playtests/overhaul/gameplay-final.png", "production/playtests/mobile-support/combat-phone.png"],
  "combat-upgrade" => ["production/playtests/overhaul/upgrade-final.png", "production/playtests/mobile-support/breakthrough-phone.png"],
  "combat-paused" => ["production/playtests/overhaul/pause-final.png", "production/playtests/mobile-support/pause-phone.png"],
  "results-victory" => ["production/playtests/frontend/results.png", "production/playtests/frontend/results-phone.png"],
  "results-defeat" => ["production/playtests/frontend/results-defeat.png", "production/playtests/frontend/results-defeat-phone.png"]
}

bound = []
contract.fetch("surfaces").each do |surface|
  paths = surface_paths.fetch(surface.fetch("id"))
  surface["captures"] = paths.map do |path|
    bound << path
    {"viewport_id" => viewport_for(path), "path" => path, "sha256" => digest_for(path)}
  end
  if surface["id"] == "combat"
    surface["condition_captures"] = [
      {"condition" => "boss-and-full-danger-radius", "viewport_id" => "desktop-1600x900", "path" => "production/playtests/overhaul/boss-final.png", "sha256" => digest_for("production/playtests/overhaul/boss-final.png")},
      {"condition" => "boss-and-full-danger-radius", "viewport_id" => "phone-844x390-simulated", "path" => "production/playtests/mobile-support/boss-phone.png", "sha256" => digest_for("production/playtests/mobile-support/boss-phone.png")}
    ]
    bound.concat(surface["condition_captures"].map { |row| row["path"] })
  else
    surface.delete("condition_captures")
  end
end

contract["auxiliary_capture_evidence"] = expected_paths.reject { |path| bound.include?(path) }.map do |path|
  {
    "id" => path.sub(%r{^production/playtests/}, "").sub(/\.png$/, "").tr("/_", "--"),
    "viewport_id" => viewport_for(path),
    "path" => path,
    "sha256" => digest_for(path)
  }
end

verification = contract.fetch("verification_commands").find { |row| row["command_id"] == "visual_smoke" }
raise "visual contract verification command missing" unless verification
verification["expected_artifacts"] = expected_paths

File.write(CONTRACT_PATH, JSON.pretty_generate(contract) + "\n")
puts "Bound #{expected_paths.length} visual artifacts to #{CONTRACT_PATH.sub(ROOT + "/", "")}"
