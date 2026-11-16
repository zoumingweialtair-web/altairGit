# Repository collaboration rules

This repository contains the Little Elsewhere Godot game in `LittleElsewhere/`.
Before game work, read `LittleElsewhere/AGENTS.md`, `LittleElsewhere/docs/HANDOFF.md`, and `LittleElsewhere/docs/DEVELOPMENT_LOG.md`.
Follow `LittleElsewhere/docs/CROSS_DEVICE_WORKFLOW.md` for setup and cross-device continuation.

Every commit changing files under `LittleElsewhere/` (except the context files themselves) must include an updated `LittleElsewhere/docs/HANDOFF.md`. Also append a concise entry to DEVELOPMENT_LOG.md for meaningful work. Record user requirements, decisions, actual changes, validation, known issues, and next steps. Never claim tests passed unless run.

On each new clone, inspect `git config --get core.hooksPath` and any existing hooks. If none are configured, run `git config --local core.hooksPath .githooks` from the repository root. If other hooks exist, integrate rather than replace them silently.

Preserve unrelated working changes and staging. Stage explicit paths or hunks; do not use blanket `git add -A` when unrelated edits exist. Do not push or rewrite history unless authorized. A local commit alone is not cross-device synchronization.

Store a curated, portable work context, not raw Codex session databases or private account data. Never commit credentials, tokens, `.codex` session directories, machine configuration, personal chat unrelated to the game, or game saves. This workflow does not recreate the app's original chat history.
