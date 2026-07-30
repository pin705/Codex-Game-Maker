#!/usr/bin/env ruby

# Rebind the visual-quality contract to current renderer captures and mark the
# prior verdict superseded. Run after a full recapture, before independent review.

require "json"
require "digest"

ROOT = File.expand_path("..", __dir__)
CONTRACT_PATH = File.join(ROOT, "production/reviews/visual-quality-contract.json")
MANIFEST_PATH = File.join(ROOT, "production/quality-command-manifest.json")
STYLE_LOCK_PATH = File.join(ROOT, "design/art/style-lock.json")

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
style_lock = JSON.parse(File.read(STYLE_LOCK_PATH))
contract["status"] = "pending_independent_review"
contract["review_state"] = "v4-captures-refreshed-pending-independent-review"
review_summary = contract.fetch("review_summary")
review_summary["historical_required_surfaces_verified"] ||= review_summary["required_surfaces_verified"]
review_summary["historical_required_surfaces_blocked"] ||= review_summary["required_surfaces_blocked"]
review_summary["verdict"] = "PENDING"
review_summary["required_surface_count"] = contract.fetch("surfaces").length
review_summary["required_surfaces_verified"] = 0
review_summary["required_surfaces_blocked"] = contract.fetch("surfaces").length
review_summary["reason"] = "The user-approved V4 master board has been implemented and the complete desktop/phone capture matrix refreshed. Independent clean-context review must bind the final verdict."
contract["style_lock"] = {
  "path" => "design/art/style-lock.json",
  "style_version" => style_lock.fetch("style_version"),
  "sha256" => style_lock.fetch("digest")
}
contract["build"] = "V4 local candidate; final project fingerprint pending refreshed quality run"
contract["required_viewports"] = [
  {
    "id" => "desktop-1600x900",
    "width" => 1600,
    "height" => 900,
    "device" => "Native desktop V4 reference canvas; matching served Chromium captures are recorded under production/evidence/platforms"
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
lookdev["status"] = "v4-approved-reference-runtime-candidate"
lookdev["representative_asset_ids"] = [
  "KEYART-001", "HUB-001-van-mong-sect", "HERO-001-idle-side",
  "UIKIT-002-scroll-talisman", "UIKIT-004-talisman-folios",
  "RitualSurface", "RasterButton", "VanMongComponentKit",
  "UIICON-001-relics", "SKILLICON-001-five-formation",
  "PREMIUM-001-cultivation-sigils"
]
lookdev["candidate_ids"] = ["lookdev-v4-user-commercial-reference", "lookdev-v4-approved-master-board", "lookdev-v4-runtime-desktop", "lookdev-v4-runtime-phone", "lookdev-v2-glossy-dashboard"]
lookdev["accepted_candidate_ids"] = ["lookdev-v4-user-commercial-reference", "lookdev-v4-approved-master-board"]
lookdev["pending_candidate_ids"] = ["lookdev-v4-runtime-desktop", "lookdev-v4-runtime-phone"]
lookdev["rejected_candidate_ids"] = ["lookdev-v2-glossy-dashboard"]
lookdev["candidate_evidence"] = [
  {
    "id" => "lookdev-v4-user-commercial-reference",
    "outcome" => "accepted",
    "path" => "design/art/lookdev/v4/user-commercial-ui-reference.png",
    "sha256" => digest_for("design/art/lookdev/v4/user-commercial-ui-reference.png")
  },
  {
    "id" => "lookdev-v4-approved-master-board",
    "outcome" => "accepted",
    "path" => "design/art/lookdev/v4/master-board-candidate-01.png",
    "sha256" => digest_for("design/art/lookdev/v4/master-board-candidate-01.png")
  },
  {
    "id" => "lookdev-v4-runtime-desktop",
    "outcome" => "pending-runtime-convergence",
    "path" => "production/playtests/frontend/contact-sheet-current-desktop.png",
    "sha256" => digest_for("production/playtests/frontend/contact-sheet-current-desktop.png")
  },
  {
    "id" => "lookdev-v4-runtime-phone",
    "outcome" => "pending-runtime-convergence",
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
  "design/art/lookdev/v4/user-commercial-ui-reference.png",
  "design/art/lookdev/v4/master-board-candidate-01.png"
]
lookdev["runtime_evidence_paths"] = [
  "production/playtests/frontend/contact-sheet-current-desktop.png",
  "production/playtests/frontend/contact-sheet-current-phone.png",
  "production/playtests/frontend/title.png",
  "production/playtests/frontend/hub.png",
  "production/playtests/frontend/inventory.png",
  "production/playtests/frontend/spirit-beast.png",
  "production/playtests/overhaul/gameplay-final.png",
  "production/playtests/overhaul/upgrade-final.png"
]
lookdev["decision_rationale"] = "The user approved the V4 master board as the complete hierarchy, material and responsive target. Current desktop/phone matrices are the runtime convergence candidates; the V2 composite remains rejected comparison evidence."
lookdev["evidence"] = lookdev["locked_reference_paths"] + lookdev["runtime_evidence_paths"]

surface_paths = {
  "title" => ["production/playtests/frontend/title.png", "production/playtests/frontend/title-phone.png"],
  "hub" => ["production/playtests/frontend/hub.png", "production/playtests/frontend/hub-phone.png"],
  "stages" => ["production/playtests/frontend/stages.png", "production/playtests/frontend/stages-phone.png"],
  "loadout" => ["production/playtests/frontend/loadout.png", "production/playtests/frontend/loadout-phone.png"],
  "inventory" => ["production/playtests/frontend/inventory.png", "production/playtests/frontend/inventory-phone.png"],
  "spirit-beast" => ["production/playtests/frontend/spirit-beast.png", "production/playtests/frontend/spirit-beast-phone.png"],
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
