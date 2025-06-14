# Development Setup Guide

This guide covers setting up the development environment using `mise` for task running and `pre-commit` for code quality checks.

## 🚀 Quick Start

```bash
# 1. Install mise (if not already installed)
curl https://mise.run | sh

# 2. Install development tools
mise install

# 3. Set up the project
mise run setup

# 4. Install pre-commit
pip install pre-commit
pre-commit install

# 5. Run development workflow
mise run dev
```

## 📋 Available Mise Tasks

### Essential Tasks

| Task | Description | Usage |
|------|-------------|-------|
| `setup` | Initialize development environment | `mise run setup` |
| `test` | Run the full test suite | `mise run test` |
| `lint` | Lint all shell scripts | `mise run lint` |
| `format` | Format all shell scripts | `mise run format` |
| `check` | Run all checks (lint, format, test, validate) | `mise run check` |

### Development Tasks

| Task | Description | Usage |
|------|-------------|-------|
| `start` | Start the MCP server | `mise run start` |
| `start-debug` | Start server with debug logging | `mise run start-debug` |
| `demo` | Run a quick functionality demo | `mise run demo` |
| `dev` | Complete development setup | `mise run dev` |

### Utility Tasks

| Task | Description | Usage |
|------|-------------|-------|
| `clean` | Clean up logs and temp files | `mise run clean` |
| `logs` | Show recent logs | `mise run logs` |
| `logs-follow` | Follow logs in real-time | `mise run logs-follow` |
| `install-deps` | Check/install dependencies | `mise run install-deps` |

### Testing Tasks

| Task | Description | Usage |
|------|-------------|-------|
| `test-verbose` | Run tests with verbose output | `mise run test-verbose` |
| `template-test` | Test template accessibility | `mise run template-test` |
| `validate-json` | Validate JSON configuration files | `mise run validate-json` |

### CI/CD Tasks

| Task | Description | Usage |
|------|-------------|-------|
| `ci` | Run complete CI pipeline | `mise run ci` |
| `pre-commit` | Run pre-commit checks | `mise run pre-commit` |
| `format-check` | Check formatting without fixing | `mise run format-check` |

## 🔧 Pre-commit Hooks

### Installation

```bash
# Install pre-commit
pip install pre-commit

# Install the git hook scripts
pre-commit install

# Install commit message hook
pre-commit install --hook-type commit-msg
```

### Hook Categories

#### **JSON/YAML Validation**
- `check-json` - Validates JSON syntax
- `prettier` - Formats JSON files consistently  
- `check-yaml` - Validates YAML syntax

#### **Security**
- `detect-secrets` - Prevents committing secrets

#### **Project-Specific**
- `validate-mcp-config` - Validates MCP configuration files
- `check-script-permissions` - Ensures main scripts are executable
- `run-tests` - Runs test suite before commit

### Manual Hook Execution

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hooks
pre-commit run check-json
pre-commit run detect-secrets
pre-commit run validate-mcp-config

# Run hooks on specific files
pre-commit run --files assets/cc_python_config.json

# Skip hooks for a commit (use sparingly)
git commit -m "message" --no-verify
```

## 🛠️ Development Workflow

### Daily Development

```bash
# 1. Start your work
mise run setup

# 2. Make changes to code
# ... edit files ...

# 3. Run checks frequently
mise run lint
mise run test

# 4. Format code
mise run format

# 5. Final check before commit
mise run check

# 6. Commit (pre-commit hooks run automatically)
git add .
git commit -m "feat: add new feature"
```

### Before Pull Request

```bash
# Run complete CI pipeline (includes linting and formatting)
mise run ci

# Clean up
mise run clean

# Check logs for any issues
mise run logs
```

> **Shell Script Quality**: While not enforced by pre-commit hooks, shell script linting and formatting are available via mise tasks. The `mise run ci` and `mise run check` tasks include these quality checks.

## 🔍 Troubleshooting

### Common Issues

**JSON Validation Failures:**
```bash
# Check JSON syntax
mise run validate-json

# Debug specific files
jq . assets/cc_python_config.json
```

**Secret Detection Issues:**
```bash
# Create/update secrets baseline
detect-secrets scan --baseline .secrets.baseline

# Audit detected secrets
detect-secrets audit .secrets.baseline
```

**Pre-commit Hook Failures:**
```bash
# Update hooks
pre-commit autoupdate

# Clean hook cache
pre-commit clean

# Reinstall hooks
pre-commit uninstall
pre-commit install
```

**Permission Issues:**
```bash
# Fix script permissions
chmod +x *.sh

# Run setup again
mise run setup
```

### Environment Variables

Set these in your shell profile or `.envrc` file:

```bash
# Enable debug mode
export DEBUG_MODE=1

# Set log level
export MCP_LOG_LEVEL=DEBUG

# Keep test logs
export KEEP_LOGS=true
```

## 📊 Code Quality Standards

### Shell Scripts
- **Permissions**: Executable scripts must have execute permissions  
- **Testing**: All tests must pass before commit
- **Quality**: Use `mise run lint` for shellcheck and `mise run format` for consistent formatting (optional)

### JSON Files
- **Syntax**: Must be valid JSON
- **Formatting**: 2-space indentation (via prettier)
- **Structure**: Follow project schema

### Security
- **No secrets**: Code must pass secret detection scans
- **Clean baseline**: Maintain updated secrets baseline file

### Git Commits
- **Testing**: All tests must pass
- **Validation**: All JSON configs must be valid

## 🎯 Best Practices

1. **Run `mise run check` before committing** (includes linting & formatting)
2. **Use `mise run dev` when starting work**
3. **Keep commits focused and atomic**
4. **Test changes with `mise run demo`**
5. **Clean up with `mise run clean` periodically**
6. **Monitor logs with `mise run logs`**
7. **Use `mise run lint` and `mise run format` for shell script quality** (not in pre-commit)

> **Note**: Shell script linting (shellcheck) and formatting (shfmt) are available via mise tasks but not enforced in pre-commit hooks. Run `mise run lint` and `mise run format` manually for code quality.

## 🔄 CI/CD Integration

The `mise run ci` task is designed for CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run CI Pipeline
  run: |
    mise install
    mise run ci
```

This ensures consistent quality checks across all environments.

---

**Happy coding! 🎉**

For more information, see:
- [mise documentation](https://mise.jdx.dev/)
- [pre-commit documentation](https://pre-commit.com/)
- [shellcheck documentation](https://www.shellcheck.net/)
