#!/bin/bash

# Rift workspace windows indicator
# This script updates workspace labels to show app icons for windows in each workspace

export RELPATH=$(dirname $0)/../..
source "$RELPATH/icon_map.sh"

# Get current focused workspace
get_focused_workspace() {
  rift-cli query workspaces 2>/dev/null | jq -r '.[] | select(.is_active == true) | .name'
}

update_workspace_windows() {
  local workspace_id=$1

  # Get workspace info and extract bundle IDs
  workspace_info=$(rift-cli query workspaces 2>/dev/null | jq -r --arg workspace "$workspace_id" '.[] | select(.name == $workspace)')

  if [ -z "$workspace_info" ] || [ "$workspace_info" = "null" ]; then
    # Workspace not found, set default appearance
    sketchybar --set space.$workspace_id label.drawing=off
    return
  fi

  # Extract unique bundle IDs from the workspace
  apps=$(echo "$workspace_info" | jq -r '.windows[].bundle_id' | sort -u)

  icon_strip=""
  if [ -n "$apps" ] && [ "$apps" != "" ]; then
    while IFS= read -r app; do
      if [ -n "$app" ] && [ "$app" != "null" ]; then
        __icon_map "$app"
        icon_strip+=" $icon_result"
      fi
    done <<< "$apps"
    sketchybar --set space.$workspace_id label="$icon_strip" label.drawing=on
  else
    # No apps in workspace, set default appearance with subtle styling
    # Check if this is the focused workspace for different default behavior
    local focused_workspace=$(get_focused_workspace)
    if [ "$workspace_id" = "$focused_workspace" ]; then
      # Focused empty workspace - could show a different indicator
      sketchybar --set space.$workspace_id label.drawing=off
    else
      # Non-focused empty workspace
      sketchybar --set space.$workspace_id label.drawing=off
    fi
  fi
}

# Update all workspaces
update_all_workspace_windows() {
  workspaces=$(rift-cli query workspaces 2>/dev/null | jq -r '.[] | .name')
  for workspace in $workspaces; do
    update_workspace_windows "$workspace"
  done
}

# Handle workspace change events with proper previous workspace cleanup
handle_workspace_change() {
  # Update the previous workspace if provided
  if [ -n "$PREV_WORKSPACE" ]; then
    echo "$(date): Updating previous workspace: $PREV_WORKSPACE" >> /tmp/rift-windows-debug.log
    update_workspace_windows "$PREV_WORKSPACE"
  fi

  # Update the current focused workspace if provided
  if [ -n "$FOCUSED_WORKSPACE" ]; then
    echo "$(date): Updating focused workspace: $FOCUSED_WORKSPACE" >> /tmp/rift-windows-debug.log
    update_workspace_windows "$FOCUSED_WORKSPACE"
  fi

  # If neither is provided, fallback to updating all workspaces
  if [ -z "$PREV_WORKSPACE" ] && [ -z "$FOCUSED_WORKSPACE" ]; then
    echo "$(date): No workspace info provided, updating all workspaces" >> /tmp/rift-windows-debug.log
    update_all_workspace_windows
  fi
}

# Main logic based on SENDER and arguments
case "$SENDER" in
"rift_workspace_change")
  # Handle workspace change event - update previous and current workspace efficiently
  handle_workspace_change
  ;;
*)
  if [ -n "$1" ]; then
    # Update specific workspace
    update_workspace_windows "$1"
  else
    # Update all workspaces
    update_all_workspace_windows
  fi
  ;;
esac