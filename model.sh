#!/bin/bash

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
    log "INFO" "=== MY GENSYN NODE SETUP LAUNCHER STARTED ==="
}

# Dependencies
install_deps() {
    echo "🔄 Updating package list..."
    sudo apt update -y
    sudo apt install -y python3 python3-venv python3-pip curl wget screen git lsof ufw jq perl gnupg
    echo "🟢 Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    echo "🧵 Installing Yarn..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/yarn.gpg
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update -y
    sudo apt install -y yarn
    echo "🛡️ Setting up firewall..."
    sudo ufw allow 22
    sudo ufw allow 3000/tcp
    sudo ufw enable
    echo "🌩️ Installing Cloudflared..."
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt install -f
    rm -f cloudflared-linux-amd64.deb
    echo "✅ All dependencies installed successfully!"
}

# Swap Management
manage_swap() {
    if [ ! -f "$SWAP_FILE" ]; then
        sudo fallocate -l 1G "$SWAP_FILE" >/dev/null 2>&1
        sudo chmod 600 "$SWAP_FILE" >/dev/null 2>&1
        sudo mkswap "$SWAP_FILE" >/dev/null 2>&1
        sudo swapon "$SWAP_FILE" >/dev/null 2>&1
        echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null 2>&1
    fi
}

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

# Unzip files from HOME
unzip_files() {
    ZIP_FILE=$(find "$HOME" -maxdepth 1 -type f -name "*.zip" | head -n 1)
    
    if [ -n "$ZIP_FILE" ]; then
        log "INFO" "📂 Found ZIP file: $ZIP_FILE, unzipping to $HOME ..."
        install_unzip
        unzip -o "$ZIP_FILE" -d "$HOME" >/dev/null 2>&1
      
        [ -f "$HOME/swarm.pem" ] && {
            sudo mv "$HOME/swarm.pem" "$SWARM_DIR/swarm.pem"
            sudo chmod 600 "$SWARM_DIR/swarm.pem"
            JUST_EXTRACTED_PEM=true
            log "INFO" "✅ Moved swarm.pem to $SWARM_DIR"
        }
        [ -f "$HOME/userData.json" ] && {
            sudo mv "$HOME/userData.json" "$TEMP_DATA_DIR/"
            log "INFO" "✅ Moved userData.json to $TEMP_DATA_DIR"
        }
        [ -f "$HOME/userApiKey.json" ] && {
            sudo mv "$HOME/userApiKey.json" "$TEMP_DATA_DIR/"
            log "INFO" "✅ Moved userApiKey.json to $TEMP_DATA_DIR"
        }

        ls -l "$HOME"
        if [ -f "$SWARM_DIR/swarm.pem" ] || [ -f "$TEMP_DATA_DIR/userData.json" ] || [ -f "$TEMP_DATA_DIR/userApiKey.json" ]; then
            log "INFO" "✅ Successfully extracted files from $ZIP_FILE"
        else
            log "WARN" "⚠️ No expected files (swarm.pem, userData.json, userApiKey.json) found in $ZIP_FILE"
        fi
    else
        log "WARN" "⚠️ No ZIP file found in $HOME, proceeding without unzipping"
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
    fi
}

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
    git clone "$REPO_URL" "$SWARM_DIR" >/dev/null 2>&1
    cd "$SWARM_DIR"
}

create_default_config() {
    log "INFO" "Creating default config at $CONFIG_FILE"
    mkdir -p "$SWARM_DIR"
    cat <<EOF > "$CONFIG_FILE"
PUSH=N
MODEL_NAME=nvidia/AceInstruct-1.5B
PARTICIPATE_AI_MARKET=Y
EOF
    chmod 600 "$CONFIG_FILE"
    log "INFO" "Default config created"
}

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

auto_enter_inputs() {
    HF_TOKEN=${HF_TOKEN:-""}
    if [ -n "${HF_TOKEN}" ]; then
        HUGGINGFACE_ACCESS_TOKEN=${HF_TOKEN}
    else
        HUGGINGFACE_ACCESS_TOKEN="None"
        echo -e "${GREEN}>> Would you like to push models you train in the RL swarm to the Hugging Face Hub? [y/N] N${NC}"
        echo -e "${GREEN}>>> No answer was given, so NO models will be pushed to Hugging Face Hub${NC}"
    fi
    # Use MODEL_NAME from config or default to nvidia/AceInstruct-1.5B
    MODEL_NAME=${MODEL_NAME:-"nvidia/AceInstruct-1.5B"}
    echo -e "${GREEN}>> Using model: $MODEL_NAME${NC}"
    log "INFO" "Using model: $MODEL_NAME"
    # Added: Automate the AI Prediction Market participation input to default to "Y"
    if [ -n "$PARTICIPATE_AI_MARKET" ]; then
        echo -e "${GREEN}>> Would you like your model to participate in the AI Prediction Market? [Y/n] $PARTICIPATE_AI_MARKET${NC}"
    else
        PARTICIPATE_AI_MARKET="Y"
        echo -e "${GREEN}>> Would you like your model to participate in the AI Prediction Market? [Y/n] Y${NC}"
    fi
}

install_python_packages() {
    TRANSFORMERS_VERSION=$(pip show transformers 2>/dev/null | grep ^Version: | awk '{print $2}')
    TRL_VERSION=$(pip show trl 2>/dev/null | grep ^Version: | awk '{print $2}')
    if [ "$TRANSFORMERS_VERSION" != "4.51.3" ] || [ "$TRL_VERSION" != "0.19.1" ]; then
        pip install --force-reinstall transformers==4.51.3 trl==0.19.1
    fi
    pip freeze | grep -E '^(transformers|trl)=='
}

has_error() {
    grep -qP '(current.?batch|UnboundLocalError|Daemon failed to start|FileNotFoundError|DHTNode bootstrap failed|Failed to connect to Gensyn Testnet|Killed|argument of type '\''NoneType'\'' is not iterable|Encountered error during training|cannot unpack non-iterable NoneType object|ConnectionRefusedError|Exception occurred during game run|get_logger\(\)\.exception)' "$LOG_FILE"
}

install_node() {
    set +m
    echo -e "${CYAN}${BOLD}INSTALLATION${NC}"
    echo -e "${YELLOW}===============================================================================${NC}"
    KEEP_TEMP_DATA=true
    export KEEP_TEMP_DATA

    # Spinner helper
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

    # Step 1: Install dependencies, clone repo, modify scripts
    ( install_deps ) & spinner $! "📦 Installing dependencies"
    ( clone_repo ) & spinner $! "📥 Cloning repo"
    ( modify_run_script ) & spinner $! "🧠 Modifying run script"
    sudo mkdir -p "$TEMP_DATA_DIR"
    unzip_files
    if [ -f "$SWARM_DIR/swarm.pem" ]; then
        sudo cp "$SWARM_DIR/swarm.pem" "$HOME/swarm.pem"
        sudo chmod 600 "$HOME/swarm.pem"
        log "INFO" "✅ Copied swarm.pem from SWARM_DIR to HOME"
    fi
    echo -e "\n${GREEN}✅ Installation completed!${NC}"
    echo -e "Auto-login: ${GREEN}ENABLED${NC}"
}



run_node() {
    if [ ! -f "$SWARM_DIR/swarm.pem" ]; then
        if [ -f "$HOME/swarm.pem" ]; then
            sudo cp "$HOME/swarm.pem" "$SWARM_DIR/swarm.pem"
            sudo chmod 600 "$SWARM_DIR/swarm.pem"
        else
            echo -e "${RED}swarm.pem not found in HOME directory. Proceeding without it...${NC}"
        fi
    fi

    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "\n${BOLD}${CYAN}⚙️  CURRENT CONFIGURATION${NC}"
        echo -e "${YELLOW}-------------------------------------------------${NC}"
        echo -e "🚀 Push to HF              : ${GREEN}$PUSH${NC}"
        echo -e "🚀 Model Name              : ${GREEN}$MODEL_NAME${NC}"
        echo -e "🚀 Participate AI Market   : ${GREEN}$PARTICIPATE_AI_MARKET${NC}"
        echo -e "${YELLOW}-------------------------------------------------${NC}"
    else
        echo -e "${RED}❗ No config found. Creating default...${NC}"
        create_default_config
        source "$CONFIG_FILE"
    fi

    # Defaults
    : "${PARTICIPATE_AI_MARKET:=Y}"
    : "${KEEP_TEMP_DATA:=true}"
    export KEEP_TEMP_DATA

    auto_enter_inputs
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
    log "INFO" "Running with model: $MODEL_NAME"

    while true; do
        LOG_FILE="$SWARM_DIR/node.log"
        : > "$LOG_FILE"

        KEEP_TEMP_DATA="$KEEP_TEMP_DATA" ./run_rl_swarm.sh <<EOF | tee "$LOG_FILE"
$PUSH
$MODEL_NAME
$PARTICIPATE_AI_MARKET
EOF

        if has_error; then
            log "ERROR" "❌ Critical error detected, restarting in 5 seconds..."
            echo -e "${RED}❌ Critical error detected. Restarting in 5 seconds...${NC}"
        else
            log "WARN" "⚠️ Node exited without critical error, restarting in 5 seconds..."
            echo -e "${YELLOW}⚠️ Node exited (non-critical). Restarting in 5 seconds...${NC}"
        fi

        sleep 5
    done
}

# Check if installed and execute
init
trap "echo -e '\n${GREEN}✅ Stopped gracefully${NC}'; exit 0" SIGINT
if [ -d "$SWARM_DIR" ] && [ -f "$SWARM_DIR/run_rl_swarm.sh" ]; then
    echo -e "${GREEN}✅ Node already installed, proceeding to run in auto-restart mode...${NC}"
    unzip_files
    run_node
else
    echo -e "${YELLOW}⚠️ Node not installed, performing installation...${NC}"
    install_node
    run_node
fi
