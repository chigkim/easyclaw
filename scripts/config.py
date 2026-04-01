from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    print("Error: This script requires Python 3.11+ for tomllib.", file=sys.stderr)
    raise SystemExit(1)


def require(mapping: dict, key: str, path: str):
    if key not in mapping:
        raise ValueError(f"Missing required key: {path}.{key}")
    return mapping[key]


def require_str(mapping: dict, key: str, path: str) -> str:
    value = require(mapping, key, path)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"Expected non-empty string at: {path}.{key}")
    return value


def require_int(mapping: dict, key: str, path: str) -> int:
    value = require(mapping, key, path)
    if not isinstance(value, int):
        raise ValueError(f"Expected integer at: {path}.{key}")
    return value


def load_toml(path: Path) -> dict:
    with path.open("rb") as f:
        return tomllib.load(f)


def build_config(data: dict) -> dict:
    models = require(data, "models", "root")
    providers = require(models, "providers", "models")

    if "ollama" in providers:
        provider_type = "ollama"
        provider = providers["ollama"]
    else:
        provider_type = "oai"
        provider = require(providers, "oai", "models.providers")

    base_url = require_str(provider, "baseUrl", f"models.providers.{provider_type}")
    api_key = require_str(provider, "apiKey", f"models.providers.{provider_type}")

    raw_models = require(provider, "models", f"models.providers.{provider_type}")
    if not isinstance(raw_models, list) or not raw_models:
        raise ValueError(f"Expected non-empty array at: models.providers.{provider_type}.models")

    first_model = raw_models[0]
    if not isinstance(first_model, dict):
        raise ValueError(f"Expected object entries in: models.providers.{provider_type}.models")

    model_id = require_str(first_model, "id", "models.providers.oai.models[0]")
    model_name = require_str(first_model, "name", "models.providers.oai.models[0]")
    model_input = require(first_model, "input", "models.providers.oai.models[0]")
    context_window = require_int(first_model, "contextWindow", "models.providers.oai.models[0]")
    max_tokens = require_int(first_model, "maxTokens", "models.providers.oai.models[0]")

    if not isinstance(model_input, list) or not all(isinstance(x, str) for x in model_input):
        raise ValueError("Expected string array at: models.providers.oai.models[0].input")

    agents = require(data, "agents", "root")
    defaults = require(agents, "defaults", "agents")
    timeout_seconds = require_int(defaults, "timeoutSeconds", "agents.defaults")
    max_concurrent = require_int(defaults, "maxConcurrent", "agents.defaults")

    subagents = require(defaults, "subagents", "agents.defaults")
    sub_max_concurrent = require_int(subagents, "maxConcurrent", "agents.defaults.subagents")

    channels = require(data, "channels", "root")
    discord = require(channels, "discord", "channels")
    discord_enabled = discord.get("enabled", True)
    token = require_str(discord, "token", "channels.discord")
    server_id = require_str(discord, "server_id", "channels.discord")

    api_type = "ollama" if provider_type == "ollama" else "openai-responses"

    return {
        "models": {
            "providers": {
                provider_type: {
                    "baseUrl": base_url,
                    "apiKey": api_key,
                    "api": api_type,
                    "models": [
                        {
                            "id": model_id,
                            "name": model_name,
                            "input": model_input,
                            "contextWindow": context_window,
                            "maxTokens": max_tokens,
                        }
                    ],
                }
            }
        },
        "commands": {
            "native": True,
            "text": True,
            "useAccessGroups": False,
        },
        "agents": {
            "defaults": {
                "model": {
                    "primary": f"{provider_type}/{model_name}",
                },
                "compaction": {
                    "mode": "safeguard",
                },
                "timeoutSeconds": timeout_seconds,
                "maxConcurrent": max_concurrent,
                "subagents": {
                    "maxConcurrent": sub_max_concurrent,
                },
                "workspace": "/home/node/.openclaw/workspace",
            }
        },
        "channels": {
            "discord": {
                "enabled": discord_enabled,
                "token": token,
                "groupPolicy": "open",
                "commands": {
                    "native": True,
                },
                "streaming": "off",
                "guilds": {
                    server_id: {
                        "requireMention": False,
                    }
                },
            }
        },
        "gateway": {
            "bind": "custom",
            "customBindHost": "0.0.0.0",
            "controlUi": {
                "allowedOrigins": ["*"],
            },
        },
        "browser": {
            "enabled": True,
            "defaultProfile": "openclaw",
            "headless": True,
            "noSandbox": True,
            "executablePath": "/usr/bin/chromium",
        },
        "mcp": {
            "servers": {
                "markitdown": {
                    "command": "uvx",
                    "args": [
                        "markitdown-mcp"
                    ]
                }
            }
        },
        "plugins": {
            "entries": {
                "browser": {
                    "enabled": True,
                }
            }
        },
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert OpenClaw TOML input into final JSON config."
    )
    parser.add_argument(
        "-c",
        "--config",
        required=False,
        type=Path,
        default=Path("claw.toml"),
        help="Path to input TOML config file.",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("openclaw.json"),
        help="Path to output JSON file. Default: openclaw.json",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config_path: Path = args.config
    output_path: Path = args.output

    if not config_path.is_file():
        print(f"Error: Config file not found: {config_path}", file=sys.stderr)
        return 1

    try:
        data = load_toml(config_path)
        config = build_config(data)
        output_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    print(f"Created {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
