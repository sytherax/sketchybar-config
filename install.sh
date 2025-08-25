#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Logging helpers
log()     { echo -e "${YELLOW}➤ $1${RESET}"; }
success() { echo -e "${GREEN}✔ $1${RESET}"; }
error()   { echo -e "${RED}✖ $1${RESET}" >&2; exit 1; }

# Ensure dependencies
for cmd in git brew curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || error "$cmd not found. Please install it first."
done

CONFIG_DIR="$HOME/.config/sketchybar"

### Clone config
log "Cloning sketchybar-config repository..."
rm -rf "$CONFIG_DIR"
git clone --depth 1 https://github.com/Kcraft059/sketchybar-config "$CONFIG_DIR"
success "Cloned sketchybar-config repository."

### Install dependencies
log "Installing SketchyBar dependencies..."
brew tap FelixKratz/formulae
brew install sketchybar media-control macmon imagemagick \
  || error "Failed to install formulae."
brew install --cask sf-symbols font-sketchybar-app-font font-sf-pro \
  || error "Failed to install casks."
success "Installed dependencies."

### Download latest icon map with jq
log "Fetching latest icon map..."
latest_tag=$(curl -fsSL https://api.github.com/repos/kvndrsslr/sketchybar-app-font/releases/latest \
  | jq -r .tag_name)

log "Latest release tag: $latest_tag"

font_url="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/${latest_tag}/icon_map.sh"
output_path="$CONFIG_DIR/dyn-icon_map.sh"

mkdir -p "$(dirname "$output_path")"
curl -fsSL -o "$output_path" "$font_url" || error "Failed to download dyn-icon_map.sh."
success "Downloaded dyn-icon_map.sh → $output_path"

### Restart SketchyBar
log "Restarting SketchyBar..."
brew services restart sketchybar
sketchybar --reload
success "SketchyBar loaded and reloaded."
