# Little Elsewhere agent instructions

Read these at the start of each new chat or device session:
1. `docs/HANDOFF.md` — current state, constraints, and immediate continuation steps.
2. `docs/DEVELOPMENT_LOG.md` — durable work history and decisions.
3. `docs/CROSS_DEVICE_WORKFLOW.md` — setup, Git workflow, and verification.
4. `game/README.md` — feature and test documentation.

Resolve paths relative to this file, never assume the repository is on D: or on Windows. Use `git rev-parse --show-toplevel` to find the actual Git root (currently the parent of this folder).

Before edits, inspect status and the latest commits. Treat pre-existing edits as work in progress; do not discard, stage, or commit them without task authorization. When another agent is working in the same checkout, coordinate or use isolated worktrees if authorized.

Before every game modification commit:
- Update HANDOFF.md with this task's requirements, decisions and reasons, changed areas, actual verification results, remaining issues, and a concrete next step.
- Append meaningful work to DEVELOPMENT_LOG.md. Use a date and subject; link to existing commits if known. Do not try to embed the current commit's own hash in itself.
- Keep current facts separate from proposals and unverified inherited descriptions.
- Commit context updates with the matching code/assets, using explicit paths/hunks.
- Never fabricate missing prior conversation. Record uncertainty and ask only when it blocks the work.

After a commit, report its hash, working-tree state, and whether it has actually been pushed. Do not equate local commits with cloud synchronization.

Keep Godot `.uid` and source `.import` settings. Ignore generated `.godot` caches. Tests and capture tools must not overwrite real user saves. Read the documented test invocation before running it. Machine-specific engine paths in launcher scripts may need local adjustment.

Do not place raw conversations, credentials, personal identifiers unrelated to the project, or local Codex session/state files in this repository. Record the game-relevant context as concise Markdown.
