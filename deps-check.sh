#!/usr/bin/env bash
# ============================================================
# deps-check.sh — dependency checker for dimunyx-qs
# Console version with black background and pagination
# ============================================================

set -euo pipefail

# ============================================================
# 1. Detect OS and environment
# ============================================================

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$NAME"
    else
        OS="unknown"
        OS_NAME="Unknown"
    fi

    if [[ -d /nix/store ]] || command -v nix &>/dev/null; then
        IS_NIXOS=true
    else
        IS_NIXOS=false
    fi
}

# ============================================================
# 2. Helper functions
# ============================================================

command_exists() {
    command -v "$1" &>/dev/null
}

service_running() {
    local service="$1"
    if command_exists systemctl; then
        systemctl is-active --quiet "$service" 2>/dev/null && return 0
    fi
    if command_exists pgrep; then
        pgrep -x "$service" &>/dev/null && return 0
    fi
    return 1
}

file_exists() {
    [[ -f "$1" ]] || [[ -d "$1" ]]
}

# ============================================================
# 3. Terminal colors (black background)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================
# 4. Collect dependency information
# ============================================================

collect_deps() {
    local home="${HOME:-$HOME}"
    
    # Critical utilities
    DEPS_CRITICAL=()
    for cmd in sh awk grep tr sed df cat find; do
        if command_exists "$cmd"; then
            DEPS_CRITICAL+=("${GREEN}[OK]${NC} $cmd -> $(which "$cmd")")
        else
            DEPS_CRITICAL+=("${RED}[FAIL]${NC} $cmd -> ${RED}NOT FOUND!${NC}")
        fi
    done

    # Optional utilities
    DEPS_OPTIONAL=()
    for cmd in niri hyprctl brightnessctl playerctl cliphist wl-copy cava sensors systemctl powerprofilesctl bluetoothctl readlink; do
        if command_exists "$cmd"; then
            DEPS_OPTIONAL+=("${GREEN}[OK]${NC} $cmd -> $(which "$cmd")")
        else
            DEPS_OPTIONAL+=("${YELLOW}[WARN]${NC} $cmd -> ${YELLOW}not found (optional)${NC}")
        fi
    done

    # Services
    SERVICES=()
    for svc in pipewire NetworkManager bluetooth upower; do
        if service_running "$svc"; then
            SERVICES+=("${GREEN}[OK]${NC} $svc -> running")
        else
            SERVICES+=("${YELLOW}[WARN]${NC} $svc -> ${YELLOW}not running (optional)${NC}")
        fi
    done

    # Files and directories
    FILES=()
    for file in "$home/.config/wallpapers" "$home/.config/quickshell/configs/cava/config" "$home/.cache/quickshell" "/sys/class/leds" "/proc/meminfo" "/proc/stat"; do
        if file_exists "$file"; then
            FILES+=("${GREEN}[OK]${NC} $file")
        else
            FILES+=("${YELLOW}[WARN]${NC} $file -> ${YELLOW}not found (optional)${NC}")
        fi
    done

    # Libraries
    LIBS=()
    if command_exists quickshell; then
        local qs_ver=$(quickshell --version 2>/dev/null | head -n1 || echo "installed")
        LIBS+=("${GREEN}[OK]${NC} Quickshell -> $qs_ver")
    else
        LIBS+=("${RED}[FAIL]${NC} Quickshell -> ${RED}NOT FOUND!${NC}")
    fi

    if command_exists qmake6 || command_exists qmake || command_exists quickshell; then
        if command_exists qmake6; then
            local qt_ver=$(qmake6 --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "installed")
            LIBS+=("${GREEN}[OK]${NC} Qt 6 -> $qt_ver")
        elif command_exists qmake; then
            local qt_ver=$(qmake --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "installed")
            LIBS+=("${GREEN}[OK]${NC} Qt 6 -> $qt_ver")
        else
            LIBS+=("${GREEN}[OK]${NC} Qt 6 -> installed (via Quickshell)")
        fi
    else
        LIBS+=("${YELLOW}[WARN]${NC} Qt 6 -> ${YELLOW}not found, but may be installed via Quickshell${NC}")
    fi

    if command_exists fc-list; then
        local fonts=""
        if fc-list | grep -qi "Monocraft"; then
            fonts+="Monocraft "
        fi
        if fc-list | grep -qi "Nerd Font"; then
            fonts+="Nerd Fonts "
        fi
        if fc-list | grep -qi "Font Awesome"; then
            fonts+="Font Awesome "
        fi
        if [[ -n "$fonts" ]]; then
            LIBS+=("${GREEN}[OK]${NC} Fonts -> $fonts")
        else
            LIBS+=("${YELLOW}[WARN]${NC} Fonts -> ${YELLOW}Nerd Fonts/Monocraft not found (icons may not display)${NC}")
        fi
    else
        LIBS+=("${YELLOW}[WARN]${NC} Fonts -> ${YELLOW}fc-list not found (cannot check)${NC}")
    fi

    # System info
    SYSTEM_INFO=()
    SYSTEM_INFO+=("${WHITE}System:${NC} $OS_NAME ($OS)")
    
    if $IS_NIXOS; then
        SYSTEM_INFO+=("${WHITE}Environment:${NC} NixOS")
    else
        SYSTEM_INFO+=("${WHITE}Environment:${NC} Regular distro")
    fi

    if $IS_NIXOS; then
        SYSTEM_INFO+=("${GREEN}[OK]${NC} NixOS detected")
        if command_exists nix; then
            SYSTEM_INFO+=("${GREEN}[OK]${NC} nix -> $(which nix)")
        else
            SYSTEM_INFO+=("${RED}[FAIL]${NC} nix -> ${RED}NOT FOUND!${NC}")
        fi
        if command_exists home-manager; then
            SYSTEM_INFO+=("${GREEN}[OK]${NC} home-manager -> $(which home-manager)")
        else
            SYSTEM_INFO+=("${YELLOW}[WARN]${NC} home-manager -> ${YELLOW}not found (optional)${NC}")
        fi
        if [[ -d /nix/var/nix/profiles/system ]]; then
            SYSTEM_INFO+=("${GREEN}[OK]${NC} NixOS profile -> /nix/var/nix/profiles/system")
        else
            SYSTEM_INFO+=("${YELLOW}[WARN]${NC} NixOS profile -> ${YELLOW}not found (StateVer may not work)${NC}")
        fi
    fi

    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        SYSTEM_INFO+=("${GREEN}[OK]${NC} Wayland -> active")
    else
        SYSTEM_INFO+=("${RED}[FAIL]${NC} Wayland -> ${RED}NOT ACTIVE! (bar works only in Wayland)${NC}")
    fi
}

# ============================================================
# 5. Generate output
# ============================================================

generate_output() {
    local output=""
    
    output+="${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    output+="${BOLD}${PURPLE}  🔍 dimunyx-qs — Dependency Check${NC}\n"
    output+="${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}\n\n"
    
    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    output+="${BOLD}🔧 Critical system utilities${NC}\n"
    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    for item in "${DEPS_CRITICAL[@]}"; do
        output+="  $item\n"
    done
    output+="\n"

    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    output+="${BOLD}🔧 Optional system utilities${NC}\n"
    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    for item in "${DEPS_OPTIONAL[@]}"; do
        output+="  $item\n"
    done
    output+="\n"

    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    output+="${BOLD}🔌 System services${NC}\n"
    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    for item in "${SERVICES[@]}"; do
        output+="  $item\n"
    done
    output+="\n"

    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    output+="${BOLD}📁 Files and directories${NC}\n"
    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    for item in "${FILES[@]}"; do
        output+="  $item\n"
    done
    output+="\n"

    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    output+="${BOLD}📚 Libraries and frameworks${NC}\n"
    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    for item in "${LIBS[@]}"; do
        output+="  $item\n"
    done
    output+="\n"

    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    output+="${BOLD}🐧 System information${NC}\n"
    output+="${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    for item in "${SYSTEM_INFO[@]}"; do
        output+="  $item\n"
    done
    output+="\n"

    output+="${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    output+="${BOLD}${GREEN}✅ Check complete!${NC}\n"
    output+="${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    output+="\n"
    output+="${YELLOW}💡 Legend:${NC}\n"
    output+="  ${GREEN}[OK]${NC} — found / active\n"
    output+="  ${YELLOW}[WARN]${NC} — optional but missing (module may not work fully)\n"
    output+="  ${RED}[FAIL]${NC} — critical! Without this the bar won't start or modules will crash\n"
    
    echo -e "$output"
}

# ============================================================
# 6. Main function with pagination
# ============================================================

main() {
    detect_os
    collect_deps
    
    # Set black background
    echo -ne "\033]11;#000000\007"
    
    # Pipe output to less/more
    if command -v less &>/dev/null; then
        generate_output | less -R -X -F -i -P "Press q to exit, arrows to scroll"
    elif command -v more &>/dev/null; then
        generate_output | more -d
    else
        generate_output
        echo ""
        echo -e "${CYAN}Press Enter to exit...${NC}"
        read -r
    fi
}

# ============================================================
# Run
# ============================================================

main "$@"
