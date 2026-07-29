import json
import tempfile
import unittest
from pathlib import Path

from tests.validate_plugin_contract import validate


def create_plugin(root: Path, agent_yaml: str | None) -> None:
    manifest = {
        "name": "fixture-plugin",
        "version": "1.0.0",
        "description": "Fixture plugin",
        "author": {"name": "Fixture Author"},
        "skills": "./skills/",
        "interface": {
            "displayName": "Fixture Plugin",
            "shortDescription": "Fixture plugin contract",
            "longDescription": "Fixture plugin used to test validation behavior.",
            "developerName": "Fixture Author",
            "category": "Developer Tools",
            "defaultPrompt": ["Use the fixture skill."],
            "capabilities": ["Write"],
        },
    }
    manifest_path = root / ".codex-plugin" / "plugin.json"
    manifest_path.parent.mkdir(parents=True)
    manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
    skill = root / "skills" / "fixture-skill"
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(
        "---\nname: fixture-skill\ndescription: Validate a fixture skill.\n---\n",
        encoding="utf-8",
    )
    if agent_yaml is not None:
        agent_path = skill / "agents" / "openai.yaml"
        agent_path.parent.mkdir()
        agent_path.write_text(agent_yaml, encoding="utf-8")


class PluginContractValidatorTests(unittest.TestCase):
    def test_every_skill_requires_agent_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_plugin(root, None)
            errors = validate(root)
        self.assertIn("fixture-skill: agents/openai.yaml is required", errors)

    def test_agent_metadata_requires_default_prompt(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_plugin(
                root,
                "interface:\n"
                "  display_name: Fixture Skill\n"
                "  short_description: Validate the complete fixture\n",
            )
            errors = validate(root)
        self.assertIn("fixture-skill: interface.default_prompt must be non-empty", errors)

    def test_complete_agent_metadata_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_plugin(
                root,
                "interface:\n"
                "  display_name: Fixture Skill\n"
                "  short_description: Validate the complete fixture\n"
                "  default_prompt: Use $fixture-skill to validate the fixture.\n",
            )
            errors = validate(root)
        self.assertEqual(errors, [])

    def test_default_prompt_must_name_the_skill(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_plugin(
                root,
                "interface:\n"
                "  display_name: Fixture Skill\n"
                "  short_description: Validate the complete fixture\n"
                "  default_prompt: Validate this fixture without naming a skill.\n",
            )
            errors = validate(root)
        self.assertIn("fixture-skill: interface.default_prompt must mention $fixture-skill", errors)


if __name__ == "__main__":
    unittest.main()
