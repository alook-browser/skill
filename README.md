# Alook Browser Skill

Control live pages in Alook Browser from AI agents that support Agent Skills.

## Capabilities

- Open, find, select, navigate, reload, and close tabs.
- Create, focus, inspect, and close browser windows and splits.
- Read page content and structure, inspect elements, and capture screenshots.
- Click, type, scroll, drag, send keys, upload files, and handle JavaScript dialogs.
- Search bookmarks and history, then open the selected result.
- Group browser resources with an optional task label for cleanup.

## Requirements

- macOS 12 or later.
- Alook Browser 1.0 or later with AI Control enabled.
- `bash` and `curl`.

The first browser command starts an authorization challenge. Confirm the displayed code in Alook to grant the agent access.

## Install

### Ask your AI agent

Copy and send this request to your AI agent:

> Install the official Alook Browser Skill in this AI agent's user-level Skill directory: https://github.com/alook-browser/skill. Follow the repository README for the appropriate installation method, then verify that the alook-browser Skill is available.

### Automatic installation

Requires Node.js 22.20.0 or later. The Agent Skills CLI detects supported agents and prompts for the installation targets.

```bash
npx skills add alook-browser/skill -g
```

### Manual Git installation

Use this path when Node.js is unavailable. Install one copy in the directory used by your agent.

### Codex and Cursor

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/alook-browser/skill.git ~/.agents/skills/alook-browser
```

### Claude Code

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/alook-browser/skill.git ~/.claude/skills/alook-browser
```

### OpenCode

```bash
mkdir -p ~/.config/opencode/skills
git clone https://github.com/alook-browser/skill.git ~/.config/opencode/skills/alook-browser
```

OpenCode also scans `.agents/skills` and `.claude/skills`. Keep only one `alook-browser` installation in its discovery scope.

### OpenClaw

```bash
openclaw skills install git:alook-browser/skill@main
```

## Use

Ask the agent to use Alook for a browser task, or continue working with the current Alook page, tab, window, or login session. Supporting agents can select the Skill automatically from its description; explicit invocation is `$alook-browser` or `/alook-browser` on hosts that expose Skill commands.

## License

Apache License 2.0. See [LICENSE](LICENSE).
