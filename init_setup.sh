#!/bin/bash

#############################################################################
# AI Evolution Engine - Initialization Script
# Version: 1.0.0
# Description: Sets up your repository for autonomous AI-driven evolution
#############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration defaults
REPO_NAME="${REPO_NAME:-ai-evolution-engine}"
AI_PROVIDER="${AI_PROVIDER:-openai}"
EVOLUTION_STRATEGY="${EVOLUTION_STRATEGY:-balanced}"
INSTALL_MODE="${1:-interactive}"
SKIP_DEPS="${SKIP_DEPS:-false}"
DRY_RUN="${DRY_RUN:-false}"

# ASCII Art Banner
show_banner() {
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║       🌱  AI EVOLUTION ENGINE - INITIALIZATION  🌱            ║
    ║                                                               ║
    ║          "Where Code Writes Itself & Grows"                   ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${MAGENTA}==>${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_os() {
    case "$OSTYPE" in
        linux*)   OS="linux" ;;
        darwin*)  OS="macos" ;;
        msys*)    OS="windows" ;;
        cygwin*)  OS="windows" ;;
        *)        OS="unknown" ;;
    esac
    log_info "Detected OS: $OS"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Required tools
    local required_tools=("git" "curl" "jq")
    
    # Optional but recommended tools
    local optional_tools=("gh" "docker")
    
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_deps+=("$tool")
            log_error "$tool is required but not installed"
        else
            log_success "$tool is installed"
        fi
    done
    
    for tool in "${optional_tools[@]}"; do
        if ! command_exists "$tool"; then
            log_warning "$tool is recommended but not installed"
        else
            log_success "$tool is installed"
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ] && [ "$SKIP_DEPS" != "true" ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        
        if [ "$INSTALL_MODE" == "interactive" ]; then
            read -p "Would you like to install missing dependencies? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_dependencies "${missing_deps[@]}"
            else
                exit 1
            fi
        else
            exit 1
        fi
    fi
}

# Install missing dependencies
install_dependencies() {
    log_step "Installing dependencies..."
    
    case "$OS" in
        linux)
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y "$@"
            elif command_exists yum; then
                sudo yum install -y "$@"
            elif command_exists pacman; then
                sudo pacman -S --noconfirm "$@"
            fi
            ;;
        macos)
            if ! command_exists brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install "$@"
            ;;
        windows)
            log_warning "Please install dependencies manually on Windows"
            log_info "Recommended: Use WSL2 or install via Chocolatey/Scoop"
            ;;
    esac
}

# Interactive configuration
configure_interactively() {
    log_step "Interactive Configuration"
    
    echo -e "\n${CYAN}Let's configure your AI Evolution Engine:${NC}\n"
    
    # Repository name
    read -p "Repository name [$REPO_NAME]: " input_repo
    REPO_NAME="${input_repo:-$REPO_NAME}"
    
    # AI Provider selection
    echo -e "\n${CYAN}Select AI Provider:${NC}"
    echo "1) OpenAI (GPT-4)"
    echo "2) Anthropic (Claude)"
    echo "3) Google (Gemini) - Coming Soon"
    echo "4) Local Model - Coming Soon"
    read -p "Choice [1]: " provider_choice
    
    case "${provider_choice:-1}" in
        1) AI_PROVIDER="openai" ;;
        2) AI_PROVIDER="anthropic" ;;
        3) log_warning "Google Gemini support coming soon, defaulting to OpenAI"
           AI_PROVIDER="openai" ;;
        4) log_warning "Local model support coming soon, defaulting to OpenAI"
           AI_PROVIDER="openai" ;;
    esac
    
    # API Key
    echo -e "\n${CYAN}API Configuration:${NC}"
    read -sp "Enter your $AI_PROVIDER API key: " api_key
    echo
    
    if [ -z "$api_key" ]; then
        log_warning "No API key provided. You'll need to set it later."
    else
        export AI_API_KEY="$api_key"
    fi
    
    # GitHub token
    if ! command_exists gh || ! gh auth status >/dev/null 2>&1; then
        echo -e "\n${CYAN}GitHub Authentication:${NC}"
        read -sp "Enter your GitHub Personal Access Token: " github_token
        echo
        
        if [ -n "$github_token" ]; then
            export GITHUB_TOKEN="$github_token"
        fi
    else
        log_success "GitHub CLI already authenticated"
    fi
    
    # Evolution strategy
    echo -e "\n${CYAN}Default Evolution Strategy:${NC}"
    echo "1) Conservative - Minimal, safe changes"
    echo "2) Balanced - Standard evolution mode (recommended)"
    echo "3) Experimental - Allow breaking changes"
    echo "4) Refactor - Focus on code quality"
    read -p "Choice [2]: " strategy_choice
    
    case "${strategy_choice:-2}" in
        1) EVOLUTION_STRATEGY="conservative" ;;
        2) EVOLUTION_STRATEGY="balanced" ;;
        3) EVOLUTION_STRATEGY="experimental" ;;
        4) EVOLUTION_STRATEGY="refactor" ;;
    esac
}

# Create directory structure
create_directory_structure() {
    log_step "Creating directory structure..."
    
    directories=(
        ".github/workflows"
        ".github/ISSUE_TEMPLATE"
        "scripts"
        "prompts/templates"
        "prompts/examples"
        "src"
        "tests"
        "docs"
        "config"
    )
    
    for dir in "${directories[@]}"; do
        if [ "$DRY_RUN" == "true" ]; then
            log_info "[DRY RUN] Would create directory: $dir"
        else
            mkdir -p "$dir"
            log_success "Created $dir"
        fi
    done
}

# Create configuration files
create_config_files() {
    log_step "Creating configuration files..."
    
    # .evolution.yml
    cat > .evolution.yml << EOF
version: 1.0
evolution:
  default_strategy: $EVOLUTION_STRATEGY
  max_tokens_per_evolution: 100000
  require_tests: true
  auto_merge_threshold: 0.95
  
ai:
  providers:
    - name: $AI_PROVIDER
      model: ${AI_MODEL:-gpt-4}
      temperature: 0.7
      max_retries: 3
      
security:
  scan_on_evolution: true
  block_on_vulnerabilities: true
  
notifications:
  slack_webhook: \${SLACK_WEBHOOK}
  email: \${NOTIFICATION_EMAIL}
  
monitoring:
  track_metrics: true
  report_frequency: weekly
EOF
    log_success "Created .evolution.yml"
    
    # .gptignore
    cat > .gptignore << 'EOF'
# Dependencies
node_modules/
vendor/
venv/
.env/

# Build outputs
dist/
build/
*.pyc
*.pyo
__pycache__/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Sensitive files
.env
.env.*
secrets/
*.key
*.pem

# Large files
*.log
*.sql
*.csv
data/

# Version control
.git/
.svn/

# OS files
.DS_Store
Thumbs.db
EOF
    log_success "Created .gptignore"
    
    # .github/CODEOWNERS
    cat > .github/CODEOWNERS << EOF
# Default code owners
* @$USER

# Evolution engine core
/.github/ @$USER
/scripts/ @$USER
.evolution.yml @$USER
EOF
    log_success "Created .github/CODEOWNERS"
    
    # evolution-metrics.json
    cat > evolution-metrics.json << EOF
{
  "total_evolutions": 0,
  "successful_evolutions": 0,
  "failed_evolutions": 0,
  "average_evolution_time": 0,
  "total_cost": 0,
  "evolutions": []
}
EOF
    log_success "Created evolution-metrics.json"
}

# Create prompt templates
create_prompt_templates() {
    log_step "Creating prompt templates..."
    
    # Feature request template
    cat > prompts/templates/feature_request.md << 'EOF'
# Feature Request Evolution Template

## Feature Name
${FEATURE_NAME}

## Description
${DESCRIPTION}

## Requirements
${REQUIREMENTS}

## Success Criteria
- [ ] Feature is implemented
- [ ] Tests are written with ${TEST_COVERAGE}% coverage
- [ ] Documentation is updated
- [ ] No breaking changes (unless specified)

## Additional Context
${CONTEXT}
EOF
    
    # Bug fix template
    cat > prompts/templates/bug_fix.md << 'EOF'
# Bug Fix Evolution Template

## Issue
Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}

## Description
${DESCRIPTION}

## Reproduction Steps
${REPRODUCTION_STEPS}

## Expected Behavior
${EXPECTED_BEHAVIOR}

## Success Criteria
- [ ] Bug is fixed
- [ ] Regression test added
- [ ] Related tests pass
- [ ] Documentation updated if needed
EOF
    
    # Refactor template
    cat > prompts/templates/refactor.md << 'EOF'
# Refactoring Evolution Template

## Refactoring Goal
${GOAL}

## Areas to Refactor
${AREAS}

## Constraints
- Maintain all existing functionality
- Preserve public API contracts
- Improve code metrics by at least ${IMPROVEMENT_TARGET}%

## Success Criteria
- [ ] Code is refactored
- [ ] All tests pass
- [ ] Performance is maintained or improved
- [ ] Code complexity reduced
EOF
    
    log_success "Created prompt templates"
}

# Create example files
create_example_files() {
    log_step "Creating example files..."
    
    # Example Python file
    cat > src/hello_evolution.py << 'EOF'
#!/usr/bin/env python3
"""
AI Evolution Engine - Example Module
This file demonstrates the starting point for evolution.
"""

def greet(name: str = "World") -> str:
    """
    A simple greeting function ready for AI evolution.
    
    Args:
        name: The name to greet
        
    Returns:
        A greeting message
    """
    return f"Hello, {name}! I'm ready to evolve!"


if __name__ == "__main__":
    print(greet("AI Evolution Engine"))
    print("This codebase is now ready for autonomous evolution!")
EOF
    chmod +x src/hello_evolution.py
    
    # Example test file
    cat > tests/test_hello_evolution.py << 'EOF'
import pytest
from src.hello_evolution import greet


def test_greet_default():
    """Test greeting with default parameter."""
    assert greet() == "Hello, World! I'm ready to evolve!"


def test_greet_custom():
    """Test greeting with custom name."""
    assert greet("AI") == "Hello, AI! I'm ready to evolve!"


def test_greet_type():
    """Test greeting return type."""
    assert isinstance(greet(), str)
EOF
    
    log_success "Created example files"
}

# Create utility scripts
create_utility_scripts() {
    log_step "Creating utility scripts..."
    
    # Cost estimation script
    cat > scripts/estimate-cost.sh << 'EOF'
#!/bin/bash
# Estimate the cost of an evolution

PROMPT="$1"
PROVIDER="${AI_PROVIDER:-openai}"

# Rough token estimation (4 chars ≈ 1 token)
PROMPT_TOKENS=$((${#PROMPT} / 4))
CONTEXT_TOKENS=50000  # Rough estimate
RESPONSE_TOKENS=10000  # Rough estimate
TOTAL_TOKENS=$((PROMPT_TOKENS + CONTEXT_TOKENS + RESPONSE_TOKENS))

# Cost calculation (example rates)
case "$PROVIDER" in
    openai)
        RATE_PER_1K=0.03  # GPT-4 example rate
        ;;
    anthropic)
        RATE_PER_1K=0.025  # Claude example rate
        ;;
    *)
        RATE_PER_1K=0.03
        ;;
esac

COST=$(echo "scale=2; $TOTAL_TOKENS * $RATE_PER_1K / 1000" | bc)

echo "Evolution Cost Estimate"
echo "======================"
echo "Provider: $PROVIDER"
echo "Estimated tokens: $TOTAL_TOKENS"
echo "Rate per 1K tokens: \$$RATE_PER_1K"
echo "Estimated cost: \$$COST"
EOF
    chmod +x scripts/estimate-cost.sh
    
    # Rollback script
    cat > scripts/rollback-evolution.sh << 'EOF'
#!/bin/bash
# Rollback to previous evolution

set -euo pipefail

TO_VERSION="${1:-}"
PRESERVE="${2:-false}"

if [ -z "$TO_VERSION" ]; then
    # Get the previous version
    TO_VERSION=$(git tag | grep "^v" | sort -V | tail -2 | head -1)
fi

echo "Rolling back to version: $TO_VERSION"

if [ "$PRESERVE" == "--preserve-branch" ]; then
    BRANCH_NAME="rollback/to-$TO_VERSION-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BRANCH_NAME"
fi

git reset --hard "$TO_VERSION"
echo "Rollback complete!"
EOF
    chmod +x scripts/rollback-evolution.sh
    
    # Health check script
    cat > scripts/health-check.sh << 'EOF'
#!/bin/bash
# Check the health of the evolution engine

echo "AI Evolution Engine Health Check"
echo "================================"

# Check Git
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✓ Git repository initialized"
else
    echo "✗ Not a git repository"
fi

# Check AI configuration
if [ -f ".evolution.yml" ]; then
    echo "✓ Evolution configuration found"
else
    echo "✗ Evolution configuration missing"
fi

# Check GitHub Actions
if [ -f ".github/workflows/ai_evolver.yml" ]; then
    echo "✓ AI Evolver workflow found"
else
    echo "✗ AI Evolver workflow missing"
fi

# Check API keys
if [ -n "${AI_API_KEY:-}" ]; then
    echo "✓ AI API key configured"
else
    echo "✗ AI API key not configured"
fi

# Check metrics
if [ -f "evolution-metrics.json" ]; then
    evolutions=$(jq '.total_evolutions' evolution-metrics.json)
    echo "✓ Evolution metrics: $evolutions total evolutions"
else
    echo "✗ Evolution metrics not found"
fi
EOF
    chmod +x scripts/health-check.sh
    
    log_success "Created utility scripts"
}

# Setup Git hooks
setup_git_hooks() {
    log_step "Setting up Git hooks..."
    
    # Pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for AI Evolution Engine

# Run tests if they exist
if [ -d "tests" ] && command -v pytest >/dev/null 2>&1; then
    echo "Running tests..."
    pytest tests/ || exit 1
fi

# Check for large files
find . -type f -size +10M | grep -v "^./.git" | while read -r file; do
    echo "Warning: Large file detected: $file"
    echo "Consider adding to .gptignore"
done

exit 0
EOF
    chmod +x .git/hooks/pre-commit
    
    log_success "Created Git hooks"
}

# Initialize Git repository
init_git_repo() {
    log_step "Initializing Git repository..."
    
    if [ "$DRY_RUN" == "true" ]; then
        log_info "[DRY RUN] Would initialize Git repository"
        return
    fi
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        git init
        log_success "Initialized Git repository"
    else
        log_info "Git repository already initialized"
    fi
    
    # Initial commit
    git add .
    git commit -m "🌱 Initial seed: AI Evolution Engine initialized

- Created directory structure
- Added configuration files
- Set up prompt templates
- Created example files
- Configured workflows
- Ready for first evolution!

[skip ci]" || true
    
    # Create initial tag
    git tag -a "v0.1.0" -m "Initial seed version" || true
}

# Test AI connection
test_ai_connection() {
    log_step "Testing AI provider connection..."
    
    if [ -z "${AI_API_KEY:-}" ]; then
        log_warning "No API key configured, skipping connection test"
        return
    fi
    
    case "$AI_PROVIDER" in
        openai)
            response=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "Authorization: Bearer $AI_API_KEY" \
                https://api.openai.com/v1/models)
            ;;
        anthropic)
            response=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "x-api-key: $AI_API_KEY" \
                -H "anthropic-version: 2023-06-01" \
                https://api.anthropic.com/v1/messages)
            ;;
        *)
            log_warning "Unknown provider, skipping test"
            return
            ;;
    esac
    
    if [ "$response" -eq 200 ] || [ "$response" -eq 401 ]; then
        log_success "AI provider connection successful"
    else
        log_error "AI provider connection failed (HTTP $response)"
    fi
}

# Generate setup report
generate_report() {
    log_step "Generating setup report..."
    
    cat > SETUP_REPORT.md << EOF
# AI Evolution Engine Setup Report

Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Configuration Summary

- **Repository Name**: $REPO_NAME
- **AI Provider**: $AI_PROVIDER
- **Evolution Strategy**: $EVOLUTION_STRATEGY
- **Operating System**: $OS

## Prerequisites Check

$(./scripts/health-check.sh 2>&1 || echo "Health check not available")

## Next Steps

1. **Configure Secrets in GitHub**:
   - Go to Settings → Secrets and variables → Actions
   - Add: \`AI_API_KEY\` with your $AI_PROVIDER API key
   - Add: \`GITHUB_TOKEN\` (if not using default)

2. **Test Your Setup**:
   \`\`\`bash
   gh workflow run ai_evolver.yml -f prompt="Add a simple calculator function"
   \`\`\`

3. **Monitor Evolution**:
   \`\`\`bash
   gh run watch
   \`\`\`

## Useful Commands

- Check health: \`./scripts/health-check.sh\`
- Estimate cost: \`./scripts/estimate-cost.sh "your prompt"\`
- Rollback: \`./scripts/rollback-evolution.sh\`

## Support

- Documentation: [README.md](README.md)
- Issues: [GitHub Issues](https://github.com/$USER/$REPO_NAME/issues)

---

Happy Evolving! 🌱
EOF
    
    log_success "Setup report generated: SETUP_REPORT.md"
}

# Main setup flow
main() {
    clear
    show_banner
    
    echo -e "\n${WHITE}Welcome to the AI Evolution Engine Setup!${NC}\n"
    
    # Detect OS
    detect_os
    
    # Check prerequisites
    check_prerequisites
    
    # Configure based on mode
    if [ "$INSTALL_MODE" == "interactive" ]; then
        configure_interactively
    else
        log_info "Using environment variables for configuration"
    fi
    
    # Create structure and files
    create_directory_structure
    create_config_files
    create_prompt_templates
    create_example_files
    create_utility_scripts
    
    # Setup Git
    if command_exists git; then
        setup_git_hooks
        init_git_repo
    fi
    
    # Test connections
    test_ai_connection
    
    # Generate report
    generate_report
    
    # Final summary
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    SETUP COMPLETE! 🎉                         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${CYAN}Your AI Evolution Engine is ready!${NC}"
    echo -e "\nNext steps:"
    echo -e "1. ${YELLOW}Configure secrets in GitHub${NC} (see SETUP_REPORT.md)"
    echo -e "2. ${YELLOW}Create the workflow file${NC} manually in .github/workflows/ai_evolver.yml"
    echo -e "3. ${YELLOW}Run your first evolution${NC}:"
    echo -e "   ${WHITE}gh workflow run ai_evolver.yml -f prompt=\"Your evolution prompt\"${NC}"
    
    echo -e "\n${GREEN}Happy evolving! 🌱${NC}\n"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --manual)
            INSTALL_MODE="manual"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --skip-deps)
            SKIP_DEPS="true"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --manual      Non-interactive mode"
            echo "  --dry-run     Show what would be done"
            echo "  --skip-deps   Skip dependency checks"
            echo "  --help        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main setup
main