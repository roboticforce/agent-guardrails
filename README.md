# Agent Guardrails

Hard policy enforcement for AI coding agents. Prevent destructive commands from ever being executed - regardless of what the agent proposes or what a human approves in the moment.

Built for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), with patterns applicable to any AI agent that executes shell commands.

## Why this exists

AI coding agents are powerful but dangerous when given access to infrastructure tooling. A single `terraform destroy` or `DROP DATABASE` can wipe production in seconds. Human-in-the-loop approval is not sufficient - people approve destructive commands when they don't fully understand the scope.

This repo provides ready-to-use guardrails that **hard-block** dangerous commands at the tool level, before they ever reach a shell.

## Quick start

Copy the Claude Code configuration into your project:

```bash
# Copy deny rules and hooks into your project
cp -r claude-code/.claude /path/to/your/project/

# Make hook scripts executable
chmod +x /path/to/your/project/.claude/scripts/*.sh
```

Or install globally for all projects:

```bash
cp claude-code/settings.json ~/.claude/settings.json
cp claude-code/hooks.json ~/.claude/hooks.json
cp -r claude-code/scripts ~/.claude/scripts
chmod +x ~/.claude/scripts/*.sh
```

## What's included

### Deny rules (`settings.json`)

Pattern-based blocklist that prevents Claude Code from executing matching commands. These are **hard blocks** - the agent won't even attempt them.

### Hook scripts

Bash scripts that run before every command execution. They inspect the command and block anything matching dangerous patterns. Exit code 2 = blocked with a message shown to the user.

| Script | What it blocks |
|--------|---------------|
| `terraform-guard.sh` | `destroy`, `apply -auto-approve`, state manipulation |
| `database-guard.sh` | `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, destructive migrations |
| `kubernetes-guard.sh` | `delete namespace`, `delete -f`, `drain --force` |
| `cloud-guard.sh` | Instance termination, resource deletion across AWS/GCP/Azure/DO |
| `git-guard.sh` | Force push to main/master/production, `reset --hard`, branch deletion |

### Policies

Documentation explaining what each guardrail protects against and why. Link these in onboarding docs so your team understands the reasoning.

## How enforcement works

Three layers, from hardest to softest:

| Layer | Mechanism | Bypassable from agent? |
|-------|-----------|----------------------|
| `settings.json` deny rules | Pattern match on tool calls | No |
| Hooks (exit code 2) | Arbitrary script logic | No |
| `CLAUDE.md` instructions | LLM instruction following | Theoretically yes |

Use all three. Defense in depth.

## Customizing

Every team has different infrastructure. Fork this repo and:

1. Edit `settings.json` to add/remove deny patterns for your stack
2. Modify hook scripts to match your specific commands and naming conventions
3. Add project-specific rules to your `CLAUDE.md`

## Real incidents

See `examples/incidents/` for real-world stories of AI agents destroying production infrastructure. Each incident includes what happened, what failed, and what guardrails would have prevented it.

## Learn from real failures

Practice responding to production incidents in a safe environment at [YouBrokeProd.com](https://youbrokeprod.com). Break things, fix things, get better - without the 3am pages.

## Need help with AI safety for your team?

Contact [RoboticForce, Inc.](https://roboticforce.io) for help implementing guardrails, policies, and safe AI agent workflows for your organization.

## License

MIT
