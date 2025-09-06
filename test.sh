#!/bin/bash
#AASSSSSSAAAAAAAAA
# Color setup
if [ -t 1 ] && [ -n "$(tput colors)" ] && [ "$(tput colors)" -ge 8 ]; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    CYAN=$(tput setaf 6)
    NC=$(tput sgr0)
else
    BOLD=""
    RED=""
    GREEN=""
    YELLOW=""
    CYAN=""
    NC=""
fi

# Paths
SWARM_DIR="$HOME/rl-swarm"
CONFIG_FILE="$SWARM_DIR/.swarm_config"
LOG_FILE="$HOME/swarm_log.txt"
SWAP_FILE="/swapfile"
REPO_URL="https://github.com/gensyn-ai/rl-swarm.git"
TEMP_DATA_DIR="$SWARM_DIR/modal-login/temp-data"

# Global Variables
KEEP_TEMP_DATA=true

# Logging
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
    case "$level" in
        ERROR) echo -e "${RED}$msg${NC}" ;;
        WARN) echo -e "${YELLOW}$msg${NC}" ;;
        INFO) echo -e "${CYAN}$msg${NC}" ;;
    esac
}

# Initialize
init() {
    touch "$LOG_FILE"
    log "INFO" "=== HUSTLE AIRDROPS RL-SWARM MANAGER STARTED ==="
}

# Install unzip if not present
install_unzip() {
    if ! command -v unzip &> /dev/null; then
        log "INFO" "⚠️ 'unzip' not found, installing..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y unzip
        elif command -v yum &> /dev/null; then
            sudo yum install -y unzip
        elif command -v apk &> /dev/null; then
            sudo apk add unzip
        else
            log "ERROR" "❌ Could not install 'unzip' (unknown package manager)."
            exit 1
        fi
    fi
}

# Find and unzip ZIP file from HOME
unzip_files() {
    # Find the first ZIP file in $HOME
    ZIP_FILE=$(find "$HOME" -maxdepth 1 -type f -name "*.zip" | head -n 1)
    
    if [ -n "$ZIP_FILE" ]; then
        log "INFO" "📂 Found ZIP file: $ZIP_FILE, unzipping..."
        install_unzip
        mkdir -p "$TEMP_DATA_DIR" "$SWARM_DIR"
        
        # Extract files to temporary directory
        unzip -o "$ZIP_FILE" -d /tmp/rl_swarm_extracted >/dev/null 2>&1
        
        # Move specific files to their destinations
        [ -f "/tmp/rl_swarm_extracted/swarm.pem" ] && {
            sudo mv "/tmp/rl_swarm_extracted/swarm.pem" "$SWARM_DIR/swarm.pem"
            sudo chmod 600 "$SWARM_DIR/swarm.pem"
            log "INFO" "✅ Moved swarm.pem to $SWARM_DIR"
        }
        [ -f "/tmp/rl_swarm_extracted/userData.json" ] && {
            sudo mv "/tmp/rl_swarm_extracted/userData.json" "$TEMP_DATA_DIR/"
            log "INFO" "✅ Moved userData.json to $TEMP_DATA_DIR"
        }
        [ -f "/tmp/rl_swarm_extracted/userApiKey.json" ] && {
            sudo mv "/tmp/rl_swarm_extracted/userApiKey.json" "$TEMP_DATA_DIR/"
            log "INFO" "✅ Moved userApiKey.json to $TEMP_DATA_DIR"
        }
        
        # Clean up extracted directory
        rm -rf /tmp/rl_swarm_extracted
        log "INFO" "🧹 Cleaned up temporary extracted files"
        
        # Verify at least one file was extracted
        if [ -f "$SWARM_DIR/swarm.pem" ] || [ -f "$TEMP_DATA_DIR/userData.json" ] || [ -f "$TEMP_DATA_DIR/userApiKey.json" ]; then
            log "INFO" "✅ Successfully extracted files from $ZIP_FILE"
        else
            log "WARN" "⚠️ No expected files (swarm.pem, userData.json, userApiKey.json) found in $ZIP_FILE"
        fi
    else
        log "WARN" "⚠️ No ZIP file found in $HOME, proceeding without unzipping"
    fi
}

# Dependencies
install_deps() {
    log "INFO" "🔄 Updating package list..."
    sudo apt update -y
    sudo apt install -y python3 python3-venv python3-pip curl wget screen git lsof ufw jq perl gnupg
    log "INFO" "🟢 Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    log "INFO" "🧵 Installing Yarn..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/yarn.gpg
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update -y
    sudo apt install -y yarn
    log "INFO" "🛡️ Setting up firewall..."
    sudo ufw allow 22
    sudo ufw allow 3000/tcp
    sudo ufw enable
    log "INFO" "🌩️ Installing Cloudflared..."
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt install -f
    rm -f cloudflared-linux-amd64.deb
    log "INFO" "✅ All dependencies installed successfully!"
}

# Swap Management
manage_swap() {
    if [ ! -f "$SWAP_FILE" ]; then
        log "INFO" "Creating 1G swap file..."
        sudo fallocate -l 1G "$SWAP_FILE" >/dev/null 2>&1
        sudo chmod 600 "$SWAP_FILE" >/dev/null 2>&1
        sudo mkswap "$SWAP_FILE" >/dev/null 2>&1
        sudo swapon "$SWAP_FILE" >/dev/null 2>&1
        echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null 2>&1
        log "INFO" "✅ Swap file created and enabled"
    fi
}

# Modify run script
modify_run_script() {
    local run_script="$SWARM_DIR/run_rl_swarm.sh"
    if [ -f "$run_script" ]; then
        awk '
        NR==1 && $0 ~ /^#!\/bin\/bash/ { print; next }
        $0 !~ /^\s*: "\$\{KEEP_TEMP_DATA:=.*\}"/ { print }
        ' "$run_script" > "$run_script.tmp" && mv "$run_script.tmp" "$run_script"
        sed -i '1a : "${KEEP_TEMP_DATA:='"$KEEP_TEMP_DATA"'}"' "$run_script"
        if grep -q 'rm -r \$ROOT_DIR/modal-login/temp-data/\*\.json' "$run_script" && \
           ! grep -q 'if \[ "\$KEEP_TEMP_DATA" != "true" \]; then' "$run_script"; then
            perl -i -pe '
                s#rm -r \$ROOT_DIR/modal-login/temp-data/\*\.json 2> /dev/null \|\| true#
if [ "\$KEEP_TEMP_DATA" != "true" ]; then
    rm -r \$ROOT_DIR/modal-login/temp-data/*.json 2> /dev/null || true
fi#' "$run_script"
        fi
        log "INFO" "✅ Modified run_rl_swarm.sh to respect KEEP_TEMP_DATA"
    fi
}

# Fix kill command in run script
fix_kill_command() {
    local run_script="$SWARM_DIR/run_rl_swarm.sh"
    if [ -f "$run_script" ]; then
        if grep -q 'kill -- -\$\$ || true' "$run_script"; then
            perl -i -pe 's#kill -- -\$\$ \|\| true#kill -TERM -- -\$\$ 2>/dev/null || true#' "$run_script"
            log "INFO" "✅ Fixed kill command in $run_script to suppress errors"
        else
            log "INFO" "ℹ️ Kill command already updated or not found"
        fi
    else
        log "ERROR" "❌ run_rl_swarm.sh not found at $run_script"
    fi
}

# Clone Repository
clone_repo() {
    sudo rm -rf "$SWARM_DIR" 2>/dev/null
    log "INFO" "📥 Cloning repository..."
    git clone "$REPO_URL" "$SWARM_DIR" >/dev/null 2>&1
    cd "$SWARM_DIR"
    log "INFO" "✅ Repository cloned to $SWARM_DIR"
}

# Create default config
create_default_config() {
    log "INFO" "Creating default config at $CONFIG_FILE"
    mkdir -p "$SWARM_DIR"
    cat <<EOF > "$CONFIG_FILE"
PUSH=N
EOF
    chmod 600 "$CONFIG_FILE"
    log "INFO" "✅ Default config created"
}

# Fix swarm.pem permissions
fix_swarm_pem_permissions() {
    local pem_file="$SWARM_DIR/swarm.pem"
    if [ -f "$pem_file" ]; then
        sudo chown "$(whoami)":"$(whoami)" "$pem_file"
        sudo chmod 600 "$pem_file"
        log "INFO" "✅ swarm.pem permissions fixed"
    else
        log "WARN" "⚠️ swarm.pem not found at $pem_file"
    fi
}

# Auto-enter inputs
auto_enter_inputs() {
    HF_TOKEN=${HF_TOKEN:-""}
    if [ -n "${HF_TOKEN}" ]; then
        HUGGINGFACE_ACCESS_TOKEN=${HF_TOKEN}
    else
        HUGGINGFACE_ACCESS_TOKEN="None"
        echo -e "${GREEN}>> Would you like to push models you train in the RL swarm to the Hugging Face Hub? [y/N] N${NC}"
        echo -e "${GREEN}>>> No answer was given, so NO models will be pushed to Hugging Face Hub${NC}"
    fi
    MODEL_NAME=""
    echo -e "${GREEN}>> Enter the name of the model you want to use in huggingface repo/name format, or press [Enter] to use the default model.${NC}"
    echo -e "${GREEN}>> Using default model from config${NC}"
    : "${PARTICIPATE_AI_MARKET:=Y}"
    echo -e "${GREEN}>> Would you like your model to participate in the AI Prediction Market? [Y/n] $PARTICIPATE_AI_MARKET${NC}"
}

# Install Python packages
install_python_packages() {
    log "INFO" "📦 Checking and installing Python packages..."
    TRANSFORMERS_VERSION=$(pip show transformers 2>/dev/null | grep ^Version: | awk '{print $2}')
    TRL_VERSION=$(pip show trl 2>/dev/null | grep ^Version: | awk '{print $2}')
    if [ "$TRANSFORMERS_VERSION" != "4.51.3" ] || [ "$TRL_VERSION" != "0.19.1" ]; then
        pip install --force-reinstall transformers==4.51.3 trl==0.19.1
        log "INFO" "✅ Installed transformers==4.51.3 and trl==0.19.1"
    else
        log "INFO" "ℹ️ Required Python packages already installed"
    fi
    pip freeze | grep -E '^(transformers|trl)=='
}

# Install node
install_node() {
    set +m
    echo -e "${CYAN}${BOLD}INSTALLATION${NC}"
    echo -e "${YELLOW}===============================================================================${NC}"
    KEEP_TEMP_DATA=true
    export KEEP_TEMP_DATA

    # Unzip and extract files
    unzip_files

    # Handle swarm.pem
    if [ -f "$SWARM_DIR/swarm.pem" ]; then
        echo -e "\n${YELLOW}⚠️ Existing swarm.pem detected in SWARM_DIR!${NC}"
        echo "1. Keep and use existing Swarm.pem"
        echo "2. Delete and generate new Swarm.pem"
        read -p "${BOLD}➡️ Choose action [1-2]: ${NC}" pem_choice
        case $pem_choice in
            1)
                sudo cp "$SWARM_DIR/swarm.pem" "$HOME/swarm.pem"
                log "INFO" "PEM copied from SWARM_DIR to HOME"
                ;;
            2)
                sudo rm -rf "$HOME/swarm.pem" "$SWARM_DIR/swarm.pem"
                log "INFO" "Old PEM deleted from SWARM_DIR and HOME"
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Continuing with existing PEM.${NC}"
                ;;
        esac
    fi

    # Spinner function
    spinner() {
        local pid=$1
        local msg="$2"
        local spinstr="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        while kill -0 "$pid" 2>/dev/null; do
            for (( i=0; i<${#spinstr}; i++ )); do
                printf "\r$msg ${spinstr:$i:1} "
                sleep 0.15
            done
        done
        printf "\r$msg ✅ Done"; tput el; echo
    }

    ( install_deps ) & spinner $! "📦 Installing dependencies"
    ( clone_repo ) & spinner $! "📥 Cloning repo"
    ( modify_run_script ) & spinner $! "🧠 Modifying run script"

    # Copy swarm.pem back to SWARM_DIR if it exists in HOME
    if [ -f "$HOME/swarm.pem" ]; then
        sudo cp "$HOME/swarm.pem" "$SWARM_DIR/swarm.pem"
        sudo chmod 600 "$SWARM_DIR/swarm.pem"
        log "INFO" "✅ Copied swarm.pem from HOME to SWARM_DIR"
    fi

    # Ensure TEMP_DATA_DIR exists
    sudo mkdir -p "$TEMP_DATA_DIR"

    echo -e "\n${GREEN}✅ Installation completed!${NC}"
    echo -e "Auto-login: ${GREEN}ENABLED${NC}"
}

# Run node
run_node() {
    if [ ! -f "$SWARM_DIR/swarm.pem" ]; then
        if [ -f "$HOME/swarm.pem" ]; then
            sudo cp "$HOME/swarm.pem" "$SWARM_DIR/swarm.pem"
            sudo chmod 600 "$SWARM_DIR/swarm.pem"
            log "INFO" "✅ Copied swarm.pem from HOME to SWARM_DIR"
        else
            log "WARN" "⚠️ swarm.pem not found in HOME directory. Proceeding without it..."
        fi
    fi
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        log "WARN" "❗ No config found. Creating default..."
        create_default_config
        source "$CONFIG_FILE"
    fi
    auto_enter_inputs
    : "${KEEP_TEMP_DATA:=true}"
    export KEEP_TEMP_DATA
    modify_run_script
    sudo chmod +x "$SWARM_DIR/run_rl_swarm.sh"
    fix_kill_command
    log "INFO" "Starting node in auto-restart mode"
    cd "$SWARM_DIR"
    fix_swarm_pem_permissions
    manage_swap
    python3 -m venv .venv
    source .venv/bin/activate
    install_python_packages
    : "${PARTICIPATE_AI_MARKET:=Y}"
    while true; do
        KEEP_TEMP_DATA="$KEEP_TEMP_DATA" ./run_rl_swarm.sh <<EOF
$PUSH
$MODEL_NAME
$PARTICIPATE_AI_MARKET
EOF
        log "WARN" "Node crashed, restarting in 5 seconds..."
        echo -e "${YELLOW}⚠️ Node crashed. Restarting in 5 seconds...${NC}"
        sleep 5
    done
}

# Check if installed and execute
init
trap "echo -e '\n${GREEN}✅ Stopped gracefully${NC}'; exit 0" SIGINT
if [ -d "$SWARM_DIR" ] && [ -f "$SWARM_DIR/run_rl_swarm.sh" ]; then
    echo -e "${GREEN}✅ Node already installed, proceeding to unzip files and run...${NC}"
    unzip_files
    run_node
else
    echo -e "${YELLOW}⚠️ Node not installed, performing installation...${NC}"
    install_node
    run_node
fi
