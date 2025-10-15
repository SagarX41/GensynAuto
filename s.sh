#!/bin/bash
# Color setup AAAAAAAAA
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
NODE_LOG="$SWARM_DIR/node.log"
# Global Variables
KEEP_TEMP_DATA=true
JUST_EXTRACTED_PEM=false
NODE_INIT_WAIT=600 # Wait time for node initialization (in seconds, default 10 minutes)
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
# Unzip files from HOME (no validation)
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
# Dependencies
install_deps() {
    log "INFO" "🔄 Updating package list..."
    sudo apt update -y
    sudo apt install -y python3 python3-venv python3-pip curl wget screen git lsof ufw jq perl gnupg tmux
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
    log "INFO" "Starting swap file management for $SWAP_FILE..."
    # Remove existing swap file if it exists
    if [ -f "$SWAP_FILE" ]; then
        log "INFO" "Found existing swap file at $SWAP_FILE, disabling and removing..."
        if swapon --show | grep -q "$SWAP_FILE"; then
            log "INFO" "Disabling swap file..."
            sudo swapoff "$SWAP_FILE"
            if [ $? -ne 0 ]; then
                log "ERROR" "Failed to disable swap file"
                exit 1
            fi
        fi
        sudo rm -f "$SWAP_FILE"
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to remove existing swap file"
            exit 1
        fi
        log "INFO" "Existing swap file removed"
    fi
    # Check available disk space (20GB = 20 * 1024 * 1024 KB)
    local desired_size=$((20 * 1024 * 1024))
    local disk_free=$(df -k --output=avail / | tail -n 1)
    if [ "$disk_free" -lt "$desired_size" ]; then
        log "ERROR" "Insufficient disk space: ${disk_free}KB available, ${desired_size}KB required"
        exit 1
    fi
    # Create new 20GB swap file
    log "INFO" "Creating new 20GB swap file..."
    sudo fallocate -l 20G "$SWAP_FILE"
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to create 20GB swap file"
        exit 1
    fi
    sudo chmod 600 "$SWAP_FILE"
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to set permissions on swap file"
        exit 1
    fi
    sudo mkswap "$SWAP_FILE"
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to format swap file"
        exit 1
    fi
    sudo swapon "$SWAP_FILE"
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to enable swap file"
        exit 1
    fi
    # Update /etc/fstab
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to update /etc/fstab"
            exit 1
        fi
        log "INFO" "Added swap file to /etc/fstab"
    fi
    log "INFO" "✅ 20GB swap file created and enabled"
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
    if [ $? -ne 0 ]; then
        log "ERROR" "❌ Failed to clone repository from $REPO_URL"
        exit 1
    fi
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
        if [ $? -ne 0 ]; then
            log "ERROR" "❌ Failed to install Python packages"
            exit 1
        fi
        log "INFO" "✅ Installed transformers==4.51.3 and trl==0.19.1"
    else
        log "INFO" "ℹ️ Required Python packages already installed"
    fi
    pip freeze | grep -E '^(transformers|trl)==' >> "$LOG_FILE"
}
# Check Gensyn Node Status
check_gensyn_node_status() {
    log "INFO" "🔍 Checking Gensyn node status..."
    echo -e "${CYAN}${BOLD}🔍 Gensyn Node Status${NC}"

    if ! tmux has-session -t "GEN" 2>/dev/null; then
        log "ERROR" "❌ No tmux session 'GEN' found"
        echo -e "${RED}❌ Node Status: OFFLINE (No tmux session 'GEN' found)${NC}"
        return 1
    fi

    # Check if the process inside tmux is running
    local process_running=$(tmux list-panes -t "GEN" -F "#{pane_pid}" | xargs -I {} ps -p {} >/dev/null 2>&1; echo $?)
    if [ $process_running -ne 0 ]; then
        log "ERROR" "❌ Process in tmux session 'GEN' is not running"
        echo -e "${RED}❌ Node Status: OFFLINE (Process crashed)${NC}"
        return 1
    fi

    # Capture tmux output with a larger range to catch recent errors
    TMUX_OUTPUT=$(tmux capture-pane -t "GEN" -p -S -2000 2>/dev/null)
    echo "$TMUX_OUTPUT" >> "$NODE_LOG"
    log "INFO" "Captured tmux session output for debugging"

    # Define error and status indicators
    local error_indicators=("Error" "Exception" "RuntimeError" "Traceback" "Failed")
    local status_indicators=("Map: 100%" "Node running successfully" "Connected to network")
    local ignorable_error=">> Failed to open http://localhost:3000. Please open it manually"

    # Check for errors first and extract details
    local error_detected=false
    local error_message=""
    for error in "${error_indicators[@]}"; do
        if echo "$TMUX_OUTPUT" | grep -q "$error"; then
            error_message=$(echo "$TMUX_OUTPUT" | grep -A 5 "$error" | head -n 1)
            # Look for file and line number in the stack trace
            local error_location=$(echo "$TMUX_OUTPUT" | grep -B 1 "$error" | grep -o "File \"[^\"]*\", line [0-9]*" | tail -n 1)

            # Check if the error is ignorable
            if [[ "$error_message" == *"$ignorable_error"* ]]; then
                log "WARN" "⚠️ Ignored non-critical error: $error_message"
                echo -e "${YELLOW}⚠️ Ignored non-critical error: $error_message${NC}"
            else
                error_detected=true
                if [ -n "$error_location" ]; then
                    log "ERROR" "❌ Node Status: ERROR - Error detected: $error_message (Location: $error_location)"
                    echo -e "${RED}❌ Node Status: ERROR - Error detected: $error_message${NC}"
                    echo -e "${YELLOW}   Location: $error_location${NC}"
                else
                    log "ERROR" "❌ Node Status: ERROR - Error detected: $error_message"
                    echo -e "${RED}❌ Node Status: ERROR - Error detected: $error_message${NC}"
                fi
                return 1
            fi
        fi
    done

    # Check for status indicators only if no critical errors are found
    local indicator_found=false
    for indicator in "${status_indicators[@]}"; do
        if echo "$TMUX_OUTPUT" | grep -q "$indicator" >/dev/null 2>&1; then
            indicator_found=true
            log "INFO" "✅ Node is LIVE (Indicator: '$indicator' found in tmux session 'GEN')"
            echo -e "${GREEN}✅ Node Status: LIVE ($indicator found)${NC}"
            return 0
        fi
    done

    local retries=3
    local attempt=1
    while [ $attempt -le $retries ]; do
        log "WARN" "⚠️ Node status check attempt $attempt/$retries: No status indicators found"
        sleep 10
        TMUX_OUTPUT=$(tmux capture-pane -t "GEN" -p -S -2000 2>/dev/null)
        echo "$TMUX_OUTPUT" >> "$NODE_LOG"
        for error in "${error_indicators[@]}"; do
            if echo "$TMUX_OUTPUT" | grep -q "$error"; then
                error_message=$(echo "$TMUX_OUTPUT" | grep -A 5 "$error" | head -n 1)
                error_location=$(echo "$TMUX_OUTPUT" | grep -B 1 "$error" | grep -o "File \"[^\"]*\", line [0-9]*" | tail -n 1)

                if [[ "$error_message" == *"$ignorable_error"* ]]; then
                    log "WARN" "⚠️ Ignored non-critical error: $error_message"
                    echo -e "${YELLOW}⚠️ Ignored non-critical error: $error_message${NC}"
                else
                    error_detected=true
                    if [ -n "$error_location" ]; then
                        log "ERROR" "❌ Node Status: ERROR - Error detected: $error_message (Location: $error_location)"
                        echo -e "${RED}❌ Node Status: ERROR - Error detected: $error_message${NC}"
                        echo -e "${YELLOW}   Location: $error_location${NC}"
                    else
                        log "ERROR" "❌ Node Status: ERROR - Error detected: $error_message"
                        echo -e "${RED}❌ Node Status: ERROR - Error detected: $error_message${NC}"
                    fi
                    return 1
                fi
            fi
        done
        for indicator in "${status_indicators[@]}"; do
            if echo "$TMUX_OUTPUT" | grep -q "$indicator" >/dev/null 2>&1; then
                indicator_found=true
                log "INFO" "✅ Node is LIVE after retry (Indicator: '$indicator' found)"
                echo -e "${GREEN}✅ Node Status: LIVE ($indicator found)${NC}"
                return 0
            fi
        done
        ((attempt++))
    done

    log "ERROR" "❌ Node is OFFLINE (No status indicators found after $retries retries)"
    echo -e "${RED}❌ Node Status: OFFLINE (No status indicators found)${NC}"
    return 1
}
# Monitor system resources
monitor_resources() {
    while true; do
        log "INFO" "🔍 Checking system resources..."
        FREE_MEM=$(free -m | awk '/Mem:/ {print $4}')
        CPU_USAGE=$(top -bn1 | head -n 3 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
        DISK_FREE=$(df -h / | tail -n 1 | awk '{print $4}' | sed 's/G//')
        log "INFO" "Memory Free: ${FREE_MEM}MB, CPU Usage: ${CPU_USAGE}%, Disk Free: ${DISK_FREE}GB"
        echo -e "${CYAN}Memory Free: ${FREE_MEM}MB, CPU Usage: ${CPU_USAGE}%, Disk Free: ${DISK_FREE}GB${NC}"
        if [ "$FREE_MEM" -lt 500 ]; then
            log "WARN" "⚠️ Low memory (${FREE_MEM}MB free), may cause node crashes"
            echo -e "${YELLOW}⚠️ Low memory (${FREE_MEM}MB free), consider increasing swap or freeing memory${NC}"
        fi
        if [ "$CPU_USAGE" -gt 80 ]; then
            log "WARN" "⚠️ High CPU usage (${CPU_USAGE}%), may slow down node startup"
            echo -e "${YELLOW}⚠️ High CPU usage (${CPU_USAGE}%), consider reducing load${NC}"
        fi
        if (( $(echo "$DISK_FREE < 5" | bc -l) )); then
            log "WARN" "⚠️ Low disk space (${DISK_FREE}GB free), may cause issues"
            echo -e "${YELLOW}⚠️ Low disk space (${DISK_FREE}GB free), consider freeing space${NC}"
        fi
        sleep 300
    done
}
# Install node
install_node() {
    set +m
    echo -e "${CYAN}${BOLD}INSTALLATION${NC}"
    echo -e "${YELLOW}===============================================================================${NC}"
    KEEP_TEMP_DATA=true
    export KEEP_TEMP_DATA
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
   
    : "${PARTICIPATE_AI_MARKET:=Y}"
    monitor_resources &
    RESOURCE_MONITOR_PID=$!
    log "INFO" "Started resource monitoring (PID: $RESOURCE_MONITOR_PID)"
    while true; do
        echo "=== Node Restart: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$NODE_LOG"
        # --- VENV RESET ON EVERY RESTART ---
        log "INFO" "🔄 Resetting Python virtual environment..."
        rm -rf .venv
        python3 -m venv .venv
        source .venv/bin/activate
        pip install --upgrade pip setuptools wheel --no-cache-dir
        install_python_packages
        # ----------------------------------
        log "INFO" "Starting tmux session 'GEN'..."
        tmux new-session -d -s "GEN" "KEEP_TEMP_DATA=$KEEP_TEMP_DATA ./run_rl_swarm.sh <<EOF | tee -a $NODE_LOG
$PUSH
$MODEL_NAME
$PARTICIPATE_AI_MARKET
EOF"
        if [ $? -ne 0 ]; then
            log "ERROR" "❌ Failed to start tmux session 'GEN'"
            echo -e "${RED}❌ Failed to start tmux session 'GEN'${NC}"
            sleep 5
            continue
        fi
        log "INFO" "Waiting $((NODE_INIT_WAIT/60)) minutes for node to initialize..."
        echo -e "${CYAN}⏳ Waiting $((NODE_INIT_WAIT/60)) minutes for node to initialize...${NC}"
        sleep "$NODE_INIT_WAIT"
        if ! tmux has-session -t "GEN" 2>/dev/null; then
            log "WARN" "⚠️ Node exited during initialization (tmux session 'GEN' terminated), restarting in 5 seconds..."
            echo -e "${YELLOW}⚠️ Node exited during initialization. Restarting in 5 seconds...${NC}"
            sleep 5
            continue
        fi
        check_gensyn_node_status
        if [ $? -eq 0 ]; then
            log "INFO" "Node is running, entering monitoring loop..."
            while tmux has-session -t "GEN" 2>/dev/null; do
                check_gensyn_node_status
                if [ $? -ne 0 ]; then
                    log "ERROR" "❌ Node detected with error, restarting in 5 seconds..."
                    echo -e "${RED}❌ Node detected with error. Restarting in 5 seconds...${NC}"
                    tmux kill-session -t "GEN" 2>/dev/null
                    sleep 5
                    break
                fi
                sleep 10
            done
        else
            log "ERROR" "❌ Node failed to start properly, restarting in 5 seconds..."
            echo -e "${RED}❌ Node failed to start properly. Restarting in 5 seconds...${NC}"
            tmux kill-session -t "GEN" 2>/dev/null
            sleep 5
        fi
    done
}
# Check system resources
check_resources() {
    log "INFO" "🔍 Checking system resources..."
    FREE_MEM=$(free -m | awk '/Mem:/ {print $4}')
    CPU_USAGE=$(top -bn1 | head -n 3 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
    DISK_FREE=$(df -h / | tail -n 1 | awk '{print $4}' | sed 's/G//')
    log "INFO" "Memory Free: ${FREE_MEM}MB, CPU Usage: ${CPU_USAGE}%, Disk Free: ${DISK_FREE}GB"
    echo -e "${CYAN}Memory Free: ${FREE_MEM}MB, CPU Usage: ${CPU_USAGE}%, Disk Free: ${DISK_FREE}GB${NC}"
    if [ "$FREE_MEM" -lt 500 ]; then
        log "WARN" "⚠️ Low memory (${FREE_MEM}MB free), may cause node crashes"
        echo -e "${YELLOW}⚠️ Low memory (${FREE_MEM}MB free), consider increasing swap or freeing memory${NC}"
    fi
    if [ "$CPU_USAGE" -gt 80 ]; then
        log "WARN" "⚠️ High CPU usage (${CPU_USAGE}%), may slow down node startup"
        echo -e "${YELLOW}⚠️ High CPU usage (${CPU_USAGE}%), consider reducing load${NC}"
    fi
    if (( $(echo "$DISK_FREE < 5" | bc -l) )); then
        log "WARN" "⚠️ Low disk space (${DISK_FREE}GB free), may cause issues"
        echo -e "${YELLOW}⚠️ Low disk space (${DISK_FREE}GB free), consider freeing space${NC}"
    fi
}
init
check_resources
manage_swap
trap 'log "INFO" "Received SIGINT, shutting down gracefully..."; echo -e "\n${GREEN}✅ Stopped gracefully${NC}"; tmux kill-session -t "GEN" 2>/dev/null; kill $RESOURCE_MONITOR_PID 2>/dev/null; exit 0' SIGINT
if [ -d "$SWARM_DIR" ] && [ -f "$SWARM_DIR/run_rl_swarm.sh" ]; then
    echo -e "${GREEN}✅ Node already installed, proceeding to unzip files and run...${NC}"
    unzip_files
    run_node
else
    echo -e "${YELLOW}⚠️ Node not installed, performing installation...${NC}"
    install_node
    run_node
fi
