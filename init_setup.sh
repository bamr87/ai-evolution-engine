#!/bin/bash

# 🧬 AI Evolution Engine - Advanced Setup Script
# The "Genesis Scroll" v2.0 - Initializes your repository for autonomous evolution

set -e  # Exit on error

# Script configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Emoji indicators
CHECK="✓"
CROSS="✗"
ARROW="→"
ROCKET="🚀"
BRAIN="🧠"
GEAR="⚙️"
LOCK="🔒"
SPARKLE="✨"

# Default values
DEFAULT_EVOLUTION_STRATEGY="balanced"
DEFAULT_AI_PROVIDER="openai"
DEFAULT_REPO_NAME="ai-evolution-engine"
SILENT_MODE=false
DRY_RUN=false
QUICK_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --silent)
            SILENT_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Function to display help
show_help() {
    cat << EOF
${CYAN}AI Evolution Engine Setup Script v${SCRIPT_VERSION}${NC}

Usage: ./init_setup.sh [OPTIONS]

Options:
    --silent        Run in non-interactive mode (requires environment variables)
    --dry-run       Preview actions without making changes
    --quick         Quick setup with minimal prompts
    --help, -h      Show this help message

Environment variables for silent mode:
    GITHUB_USERNAME     GitHub username
    GITHUB_REPO         Repository name
    GITHUB_TOKEN        GitHub Personal Access Token
    AI_API_KEY          AI provider API key
    AI_PROVIDER         AI provider (openai, anthropic, google, local)
    AI_ENDPOINT         AI API endpoint URL

Example:
    ${GREEN}# Interactive mode${NC}
    ./init_setup.sh

    ${GREEN}# Silent mode${NC}
    export GITHUB_TOKEN="ghp_..."
    export AI_API_KEY="sk-..."
    ./init_setup.sh --silent

    ${GREEN}# Dry run${NC}
    ./init_setup.sh --dry-run
EOF
}

# Function to print section headers
print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo ""
    echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
    echo -e "${BLUE}║$(printf ' %.0s' $(seq 1 $padding))${WHITE}$title${NC}$(printf ' %.0s' $(seq 1 $((width - padding - ${#title}))))${BLUE}║${NC}"
    echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
}

# Function to print status
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "success")
            echo -e "${GREEN}${CHECK}${NC} $message"
            ;;
        "error")
            echo -e "${RED}${CROSS}${NC} $message"
            ;;
        "warning")
            echo -e "${YELLOW}!${NC} $message"
            ;;
        "info")
            echo -e "${CYAN}${ARROW}${NC} $message"
            ;;
        "working")
            echo -e "${MAGENTA}${GEAR}${NC} $message"
            ;;
    esac
}

# Function to check dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    local deps=(git curl jq)
    local optional_deps=(gh docker)
    local missing_deps=()
    local missing_optional=()
    
    # Check required dependencies
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            print_status "success" "$dep is installed"
        else
            print_status "error" "$dep is not installed"
            missing_deps+=("$dep")
        fi
    done
    
    # Check optional dependencies
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            print_status "success" "$dep is installed (optional)"
        else
            print_status "warning" "$dep is not installed (optional)"
            missing_optional+=("$dep")
        fi
    done
    
    # Report results
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        print_status "error" "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install missing dependencies:"
        
        # Detect OS and provide installation commands
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install ${missing_deps[*]}"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "  sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
        fi
        
        if ! $DRY_RUN; then
            exit 1
        fi
    fi
    
    # Check Git version
    local git_version=$(git --version | awk '{print $3}')
    local required_git_version="2.25.0"
    
    if [ "$(printf '%s\n' "$required_git_version" "$git_version" | sort -V | head -n1)" = "$required_git_version" ]; then
        print_status "success" "Git version $git_version meets requirements"
    else
        print_status "warning" "Git version $git_version is older than recommended $required_git_version"
    fi
}

# Function to read secure input
read_secure() {
    local prompt="$1"
    local var_name="$2"
    local value=""
    
    echo -n "$prompt"
    read -s value
    echo ""
    
    eval "$var_name='$value'"
}

# Function to validate GitHub token
validate_github_token() {
    local token="$1"
    
    print_status "working" "Validating GitHub token..."
    
    local response=$(curl -s -H "Authorization: token $token" https://api.github.com/user)
    
    if echo "$response" | jq -e '.login' &> /dev/null; then
        local username=$(echo "$response" | jq -r '.login')
        print_status "success" "Token valid for user: $username"
        return 0
    else
        print_status "error" "Invalid GitHub token"
        return 1
    fi
}

# Function to test AI API connection
test_ai_api() {
    local api_key="$1"
    local endpoint="$2"
    local provider="$3"
    
    print_status "working" "Testing AI API connection..."
    
    # Different test payloads for different providers
    case "$provider" in
        "openai")
            local test_payload='{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"Hi"}],"max_tokens":5}'
            local auth_header="Authorization: Bearer $api_key"
            ;;
        "anthropic")
            local test_payload='{"model":"claude-3-haiku-20240307","messages":[{"role":"user","content":"Hi"}],"max_tokens":5}'
            local auth_header="x-api-key: $api_key"
            ;;
        *)
            print_status "warning" "Unknown provider, skipping API test"
            return 0
            ;;
    esac
    
    if $DRY_RUN; then
        print_status "info" "Dry run: Would test API connection to $endpoint"
        return 0
    fi
    
    local response=$(curl -s -X POST "$endpoint" \
        -H "Content-Type: application/json" \
        -H "$auth_header" \
        -d "$test_payload" \
        -w "\n%{http_code}")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        print_status "success" "AI API connection successful"
        return 0
    else
        print_status "error" "AI API connection failed (HTTP $http_code)"
        return 1
    fi
}

# Function to create directory structure
create_directory_structure() {
    print_header "Creating Directory Structure"
    
    local dirs=(
        ".github/workflows"
        ".github/ISSUE_TEMPLATE"
        "prompts/templates"
        "prompts/examples"
        "prompts/community"
        "scripts"
        "docs/providers"
        "docs/tutorials"
        "tests/integration"
        "tests/unit"
        "models"
        "config"
    )
    
    for dir in "${dirs[@]}"; do
        if $DRY_RUN; then
            print_status "info" "Would create directory: $dir"
        else
            mkdir -p "$dir"
            print_status "success" "Created directory: $dir"
        fi
    done
}

# Function to create configuration files
create_config_files() {
    print_header "Creating Configuration Files"
    
    # Create .evolution.yml
    if $DRY_RUN; then
        print_status "info" "Would create .evolution.yml"
    else
        cat > .evolution.yml << 'EOF'
version: 1.0

# Evolution configuration
evolution:
  default_strategy: balanced        # conservative | balanced | experimental | refactor | performance | security
  max_tokens_per_evolution: 100000  # Maximum tokens to use per evolution
  require_tests: true               # Require tests for new code
  auto_merge_threshold: 0.95        # Confidence threshold for auto-merge (0-1)
  branch_protection: true           # Enable branch protection rules
  
# AI provider configuration  
ai:
  primary_provider: ${AI_PROVIDER}
  fallback_provider: null
  retry_on_error: true
  providers:
    - name: openai
      enabled: true
      model: gpt-4-turbo-preview
      temperature: 0.7
      max_retries: 3
      timeout: 300
    - name: anthropic
      enabled: false
      model: claude-3-opus-20240229
      temperature: 0.6
      max_retries: 2
      timeout: 300
      
# Quality assurance configuration
quality:
  min_test_coverage: 80             # Minimum test coverage percentage
  require_documentation: true       # Require documentation updates
  code_style: automatic            # strict | automatic | preserve
  run_linters: true
  security_scan: true
  
# Monitoring and metrics
monitoring:
  track_costs: true
  cost_alert_threshold: 10.00      # USD
  metrics_dashboard: enabled
  webhook_notifications: false
  webhook_url: ""
  
# Advanced features
advanced:
  use_caching: true                # Cache similar prompts
  incremental_mode: true           # Only send changed files for large repos
  parallel_processing: false       # Process multiple files in parallel
  custom_models_path: "./models"   # Path to custom model implementations
EOF
        print_status "success" "Created .evolution.yml"
    fi
    
    # Create .gptignore
    if $DRY_RUN; then
        print_status "info" "Would create .gptignore"
    else
        cat > .gptignore << 'EOF'
# Files and directories to exclude from AI context

# Dependencies
node_modules/
vendor/
venv/
.venv/
env/
*.egg-info/

# Build outputs
dist/
build/
out/
target/
*.pyc
__pycache__/

# Large files
*.pdf
*.zip
*.tar.gz
*.rar
*.7z
*.dmg
*.iso
*.jar

# Media files
*.mp4
*.mp3
*.wav
*.avi
*.mov
*.jpg
*.jpeg
*.png
*.gif
*.ico
*.svg

# Logs and databases
*.log
*.sql
*.sqlite
*.db

# IDE and OS files
.idea/
.vscode/
*.swp
.DS_Store
Thumbs.db

# Secrets and credentials
.env
.env.*
*_secret*
*_private*
*.pem
*.key

# Test coverage
coverage/
.coverage
htmlcov/
*.cover

# Documentation builds
docs/_build/
site/

# Custom exclusions
# Add your own patterns below
EOF
        print_status "success" "Created .gptignore"
    fi
    
    # Create evolution-metrics.json
    if $DRY_RUN; then
        print_status "info" "Would create evolution-metrics.json"
    else
        cat > evolution-metrics.json << EOF
{
  "version": "1.0.0",
  "metrics": {
    "total_evolutions": 0,
    "successful_evolutions": 0,
    "failed_evolutions": 0,
    "average_evolution_time": 0,
    "total_tokens_used": 0,
    "total_cost_usd": 0.00,
    "last_evolution": null
  },
  "evolutions": []
}
EOF
        print_status "success" "Created evolution-metrics.json"
    fi
}

# Function to create example files
create_example_files() {
    print_header "Creating Example Files"
    
    # Create example prompts
    local example_files=(
        "prompts/templates/feature_request.md"
        "prompts/templates/bug_fix.md"
        "prompts/templates/refactor.md"
        "prompts/templates/documentation.md"
        "prompts/examples/add_api_endpoint.md"
        "prompts/examples/implement_caching.md"
    )
    
    if $DRY_RUN; then
        for file in "${example_files[@]}"; do
            print_status "info" "Would create: $file"
        done
    else
        # Feature request template
        cat > prompts/templates/feature_request.md << 'EOF'
## Goal: [Feature Name]

**Context:**
[Explain why this feature is needed and current limitations]

**Requirements:**
1. [Specific requirement]
2. [Another requirement]
3. [Performance requirement]

**User Stories:**
- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

**Acceptance Criteria:**
- [ ] [Measurable criterion]
- [ ] [Another criterion]
- [ ] [Test coverage > 80%]

**Technical Considerations:**
- [API compatibility]
- [Database changes]
- [Security implications]

**Examples:**

**Out of Scope:**
- [What this feature will NOT do]
EOF
        print_status "success" "Created feature request template"
        
        # Bug fix template
        cat > prompts/templates/bug_fix.md << 'EOF'
## Goal: Fix [Bug Description]

**Bug Report:**
- **Severity:** [Critical/High/Medium/Low]
- **Affected Component:** [Component name]
- **First Observed:** [Date/Version]

**Current Behavior:**
[Describe what happens currently]

**Expected Behavior:**
[Describe what should happen]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Observe error]

**Root Cause Analysis:**
[If known, describe the likely cause]

**Proposed Solution:**
[High-level approach to fix]

**Test Cases:**
- [ ] [Test to verify fix]
- [ ] [Regression test]
- [ ] [Edge case test]

**Impact Assessment:**
- **Users Affected:** [Number/percentage]
- **Workaround Available:** [Yes/No - describe if yes]
EOF
        print_status "success" "Created bug fix template"
        
        # Example: Add API endpoint
        cat > prompts/examples/add_api_endpoint.md << 'EOF'
## Goal: Add User Profile API Endpoints

**Context:**
The application currently lacks API endpoints for user profile management. Users need to be able to view and update their profile information through our REST API.

**Requirements:**
1. Create RESTful endpoints for user profile operations
2. Implement proper authentication and authorization
3. Add input validation and sanitization
4. Include rate limiting for security
5. Generate OpenAPI documentation
6. Add comprehensive test coverage

**API Specifications:**

### GET /api/v1/users/{userId}/profile
- **Authentication:** Required (Bearer token)
- **Authorization:** Users can only access their own profile unless admin
- **Response:** User profile object
- **Status Codes:** 200, 401, 403, 404

### PUT /api/v1/users/{userId}/profile
- **Authentication:** Required (Bearer token)
- **Authorization:** Users can only update their own profile unless admin
- **Request Body:** Partial user profile object
- **Validation:** Email format, username uniqueness
- **Response:** Updated user profile object
- **Status Codes:** 200, 400, 401, 403, 404, 422

### POST /api/v1/users/{userId}/avatar
- **Authentication:** Required (Bearer token)
- **Authorization:** Users can only update their own avatar
- **Request:** Multipart form data with image file
- **Validation:** File type (jpg, png), size limit (5MB)
- **Response:** Avatar URL
- **Status Codes:** 201, 400, 401, 403, 413

**Technical Considerations:**
- Use existing authentication middleware
- Implement DTO pattern for request/response
- Add database migrations if needed
- Update API documentation
- Consider caching strategy for profile data

**Success Criteria:**
- [ ] All endpoints implemented and working
- [ ] Authentication and authorization properly enforced
- [ ] Input validation prevents invalid data
- [ ] Rate limiting configured (100 requests per hour)
- [ ] OpenAPI spec updated
- [ ] Test coverage > 90%
- [ ] Response time < 200ms for GET requests
EOF
        print_status "success" "Created API endpoint example"
    fi
}

# Function to setup GitHub secrets
setup_github_secrets() {
    print_header "Configuring GitHub Secrets"
    
    if command -v gh &> /dev/null; then
        print_status "success" "GitHub CLI detected"
        
        if $DRY_RUN; then
            print_status "info" "Would set GitHub secrets:"
            print_status "info" "  - GH_PAT_REPO_WORKFLOW"
            print_status "info" "  - AI_API_KEY"
            print_status "info" "  - AI_MODEL_ENDPOINT"
        else
            print_status "working" "Setting GitHub secrets..."
            
            # Set secrets using GitHub CLI
            echo "$GITHUB_PAT" | gh secret set GH_PAT_REPO_WORKFLOW --repo "$GITHUB_USERNAME/$REPO_NAME" 2>/dev/null || {
                print_status "warning" "Could not set GH_PAT_REPO_WORKFLOW secret"
            }
            
            echo "$AI_API_KEY" | gh secret set AI_API_KEY --repo "$GITHUB_USERNAME/$REPO_NAME" 2>/dev/null || {
                print_status "warning" "Could not set AI_API_KEY secret"
            }
            
            echo "$AI_ENDPOINT" | gh secret set AI_MODEL_ENDPOINT --repo "$GITHUB_USERNAME/$REPO_NAME" 2>/dev/null || {
                print_status "warning" "Could not set AI_MODEL_ENDPOINT secret"
            }
            
            print_status "success" "GitHub secrets configuration attempted"
        fi
    else
        print_status "warning" "GitHub CLI not found. Manual configuration required:"
        echo ""
        echo "  1. Go to: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions"
        echo "  2. Add these repository secrets:"
        echo "     - GH_PAT_REPO_WORKFLOW = [Your GitHub PAT]"
        echo "     - AI_API_KEY = [Your AI API Key]"
        echo "     - AI_MODEL_ENDPOINT = $AI_ENDPOINT"
        echo ""
        
        if ! $SILENT_MODE; then
            read -p "Press Enter when you've added the secrets..."
        fi
    fi
}

# Function to create local environment files
create_local_env() {
    print_header "Creating Local Environment"
    
    # Create .env file
    if $DRY_RUN; then
        print_status "info" "Would create .env file"
    else
        cat > .env << EOF
# AI Evolution Engine Configuration
# DO NOT COMMIT THIS FILE!

# AI Configuration
AI_API_KEY=$AI_API_KEY
AI_MODEL_ENDPOINT=$AI_ENDPOINT
AI_PROVIDER=$AI_PROVIDER

# GitHub Configuration
GITHUB_USERNAME=$GITHUB_USERNAME
GITHUB_REPO=$REPO_NAME

# Evolution Settings
DEFAULT_EVOLUTION_STRATEGY=$DEFAULT_EVOLUTION_STRATEGY
MAX_EVOLUTION_COST=10.00
AUTO_MERGE_ENABLED=false

# Monitoring
METRICS_ENABLED=true
WEBHOOK_URL=

# Development
DEBUG_MODE=false
EOF
        chmod 600 .env
        print_status "success" "Created .env file (secured with 600 permissions)"
    fi
    
    # Create comprehensive .gitignore
    if $DRY_RUN; then
        print_status "info" "Would create .gitignore"
    else
        cat > .gitignore << 'EOF'
# Environment variables
.env
.env.*
!.env.example

# Secrets and credentials
*.pem
*.key
*.p12
*.pfx
*_rsa
*_dsa
*_ed25519
*.ppk
credentials/
secrets/

# OS-specific files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
desktop.ini
*.lnk

# IDE and editor files
.vscode/
.idea/
*.swp
*.swo
*.swn
*~
.project
.classpath
.settings/
*.sublime-workspace
*.sublime-project
.atom/
.brackets.json
*.code-workspace

# Language-specific
## Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
.pytest_cache/
.coverage
htmlcov/
.tox/
.mypy_cache/
.dmypy.json
dmypy.json
.pyre/
venv/
.venv/
env/
ENV/

## Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.npm
.yarn-integrity
.next/
out/
.nuxt/
dist/

## Ruby
*.gem
*.rbc
/.config
/coverage/
/InstalledFiles
/pkg/
/spec/reports/
/test/tmp/
/test/version_tmp/
/tmp/
.bundle/
vendor/bundle
.ruby-version
.ruby-gemset

## Java
*.class
*.jar
*.war
*.ear
*.nar
.mtj.tmp/
hs_err_pid*

## Go
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out
vendor/
go.sum

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Testing
coverage/
.nyc_output/
test-results/
playwright-report/
test-artifacts/

# Temporary files
*.tmp
*.temp
*.cache
.temp/
.tmp/
.cache/

# Backup files
*.bak
*.backup
*.old
*~
*.orig

# Database
*.sqlite
*.sqlite3
*.db
*.db-journal
*.db-wal

# Docker
.docker/

# Evolution-specific
evolution-metrics.json
.evolution-cache/
evolution-reports/

# Custom patterns (add your own below)
EOF
        print_status "success" "Created comprehensive .gitignore"
    fi
}

# Function to generate final setup report
generate_setup_report() {
    print_header "Setup Complete! ${ROCKET}"
    
    echo ""
    echo -e "${GREEN}${SPARKLE} Your AI Evolution Engine is ready! ${SPARKLE}${NC}"
    echo ""
    
    # Summary table
    echo -e "${CYAN}Configuration Summary:${NC}"
    echo "┌─────────────────────────┬──────────────────────────────────┐"
    echo "│ Setting                 │ Value                            │"
    echo "├─────────────────────────┼──────────────────────────────────┤"
    printf "│ %-23s │ %-32s │\n" "Repository" "$GITHUB_USERNAME/$REPO_NAME"
    printf "│ %-23s │ %-32s │\n" "AI Provider" "$AI_PROVIDER"
    printf "│ %-23s │ %-32s │\n" "Evolution Strategy" "$DEFAULT_EVOLUTION_STRATEGY"
    printf "│ %-23s │ %-32s │\n" "Setup Mode" "$([ $DRY_RUN = true ] && echo "Dry Run" || echo "Live")"
    echo "└─────────────────────────┴──────────────────────────────────┘"
    
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. ${ARROW} Review configuration files (.evolution.yml, .gptignore)"
    echo "2. ${ARROW} Commit and push all files:"
    echo ""
    echo "   git add ."
    echo "   git commit -m \"${ROCKET} Initialize AI Evolution Engine\""
    echo "   git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    echo "   git push -u origin main"
    echo ""
    echo "3. ${ARROW} Create your first evolution prompt:"
    echo "   echo '## Goal: Add Hello World endpoint' > prompts/first_evolution.md"
    echo ""
    echo "4. ${ARROW} Trigger your first evolution:"
    echo "   gh workflow run ai_evolver.yml"
    echo ""
    
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}Note: Install GitHub CLI for easier workflow management:${NC}"
        echo "  https://cli.github.com/"
        echo ""
    fi
    
    echo -e "${CYAN}Resources:${NC}"
    echo "  📚 Documentation: https://github.com/$GITHUB_USERNAME/$REPO_NAME#readme"
    echo "  💬 Community: https://discord.gg/ai-evolution"
    echo "  🐛 Issues: https://github.com/$GITHUB_USERNAME/$REPO_NAME/issues"
    echo "  📧 Support: support@ai-evolution.dev"
    echo ""
    
    echo -e "${GREEN}${BRAIN} Happy Evolving! ${BRAIN}${NC}"
}

# Function to collect interactive input
collect_interactive_input() {
    print_header "Interactive Setup ${BRAIN}"
    
    # GitHub configuration
    echo -e "${CYAN}GitHub Configuration:${NC}"
    echo ""
    
    if [ -z "$GITHUB_USERNAME" ]; then
        read -p "GitHub username: " GITHUB_USERNAME
    fi
    
    if [ -z "$REPO_NAME" ]; then
        read -p "Repository name [$DEFAULT_REPO_NAME]: " REPO_NAME
        REPO_NAME=${REPO_NAME:-$DEFAULT_REPO_NAME}
    fi
    
    if [ -z "$GITHUB_PAT" ]; then
        echo ""
        echo "Create a GitHub Personal Access Token with 'repo' and 'workflow' scopes:"
        echo "  https://github.com/settings/tokens/new"
        echo ""
        read_secure "GitHub PAT: " GITHUB_PAT
        
        # Validate token
        while ! validate_github_token "$GITHUB_PAT"; do
            read_secure "Please enter a valid GitHub PAT: " GITHUB_PAT
        done
    fi
    
    # AI configuration
    echo ""
    echo -e "${CYAN}AI Provider Configuration:${NC}"
    echo ""
    
    if [ -z "$AI_PROVIDER" ]; then
        echo "Select AI provider:"
        echo "  1) OpenAI (GPT-4)"
        echo "  2) Anthropic (Claude 3)"
        echo "  3) Google (Gemini)"
        echo "  4) Local Model"
        echo ""
        read -p "Choice [1]: " provider_choice
        
        case "${provider_choice:-1}" in
            1)
                AI_PROVIDER="openai"
                AI_ENDPOINT="https://api.openai.com/v1/chat/completions"
                ;;
            2)
                AI_PROVIDER="anthropic"
                AI_ENDPOINT="https://api.anthropic.com/v1/messages"
                ;;
            3)
                AI_PROVIDER="google"
                AI_ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
                ;;
            4)
                AI_PROVIDER="local"
                read -p "Local model endpoint: " AI_ENDPOINT
                ;;
        esac
    fi
    
    if [ -z "$AI_API_KEY" ]; then
        echo ""
        case "$AI_PROVIDER" in
            "openai")
                echo "Get your OpenAI API key from: https://platform.openai.com/api-keys"
                ;;
            "anthropic")
                echo "Get your Anthropic API key from: https://console.anthropic.com/settings/keys"
                ;;
            "google")
                echo "Get your Google AI key from: https://makersuite.google.com/app/apikey"
                ;;
        esac
        echo ""
        read_secure "AI API key: " AI_API_KEY
        
        # Test API connection
        if ! $QUICK_MODE; then
            while ! test_ai_api "$AI_API_KEY" "$AI_ENDPOINT" "$AI_PROVIDER"; do
                read_secure "Please enter a valid AI API key: " AI_API_KEY
            done
        fi
    fi
    
    # Evolution configuration
    echo ""
    echo -e "${CYAN}Evolution Configuration:${NC}"
    echo ""
    
    if [ -z "$DEFAULT_EVOLUTION_STRATEGY" ]; then
        echo "Select default evolution strategy:"
        echo "  1) Conservative - Minimal, safe changes"
        echo "  2) Balanced - Standard evolution mode (recommended)"
        echo "  3) Experimental - Allow breaking changes"
        echo "  4) Refactor - Focus on code quality"
        echo "  5) Performance - Optimize for speed"
        echo "  6) Security - Fix vulnerabilities"
        echo ""
        read -p "Choice [2]: " strategy_choice
        
        case "${strategy_choice:-2}" in
            1) DEFAULT_EVOLUTION_STRATEGY="conservative" ;;
            2) DEFAULT_EVOLUTION_STRATEGY="balanced" ;;
            3) DEFAULT_EVOLUTION_STRATEGY="experimental" ;;
            4) DEFAULT_EVOLUTION_STRATEGY="refactor" ;;
            5) DEFAULT_EVOLUTION_STRATEGY="performance" ;;
            6) DEFAULT_EVOLUTION_STRATEGY="security" ;;
        esac
    fi
}

# Main execution flow
main() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}         AI Evolution Engine Setup Script v${SCRIPT_VERSION}          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}           The Genesis of Self-Evolving Code              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    
    # Check dependencies first
    check_dependencies
    
    # Collect input based on mode
    if $SILENT_MODE; then
        # Validate required environment variables
        required_vars=(GITHUB_USERNAME GITHUB_PAT AI_API_KEY AI_PROVIDER)
        for var in "${required_vars[@]}"; do
            if [ -z "${!var}" ]; then
                print_status "error" "Missing required environment variable: $var"
                exit 1
            fi
        done
        
        # Set defaults for optional variables
        REPO_NAME=${GITHUB_REPO:-$DEFAULT_REPO_NAME}
        AI_ENDPOINT=${AI_ENDPOINT:-"https://api.openai.com/v1/chat/completions"}
    else
        collect_interactive_input
    fi
    
    # Create directory structure
    create_directory_structure
    
    # Create configuration files
    create_config_files
    
    # Create example files
    create_example_files
    
    # Create local environment
    create_local_env
    
    # Setup GitHub secrets (if not in dry run mode)
    if ! $DRY_RUN; then
        setup_github_secrets
    fi
    
    # Generate final report
    generate_setup_report
}

# Run main function
main