#!/bin/bash

# Get workspace ID from command line argument or extract from NAME
WORKSPACE_ID=${1:-${NAME#space.}}

# Set RELPATH for accessing other scripts
export RELPATH=$(dirname $0)/../..

# Debug: Always log when script is called
echo "$(date): Script called with SENDER='$SENDER' NAME='$NAME' WORKSPACE_ID='$WORKSPACE_ID'" >> /tmp/rift-script-debug.log

update() {
  # Get current focused workspace if not provided
  if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(rift-cli query workspaces 2>/dev/null | jq -r '.[] | select(.is_active == true) | .name')
  fi

  # Check if this workspace is the focused one
  if [ "$FOCUSED_WORKSPACE" = "$WORKSPACE_ID" ]; then
    SELECTED="true"
  else
    SELECTED="false"
  fi

  WIDTH="dynamic"
  BACKGROUND="on"
  if [ "$SELECTED" = "true" ]; then
    WIDTH="0"
    BACKGROUND="off"
  fi

  sketchybar --animate tanh 20 --set $NAME icon.highlight=$SELECTED label.width=$WIDTH background.drawing=$BACKGROUND
}

update_all_workspaces() {
  # Get current focused workspace if not provided
  if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(rift-cli query workspaces 2>/dev/null | jq -r '.[] | select(.is_active == true) | .name')
  fi

  # Get all existing workspaces dynamically
  workspaces=$(rift-cli query workspaces 2>/dev/null | jq -r '.[] | .name')

  # Update all workspace items with the current focused workspace
  for workspace in $workspaces; do
    if [ "$FOCUSED_WORKSPACE" = "$workspace" ]; then
      sketchybar --animate tanh 20 --set space.$workspace icon.highlight=on label.width=0 background.drawing=off
    else
      sketchybar --animate tanh 20 --set space.$workspace icon.highlight=off label.width=dynamic background.drawing=on
    fi
  done
}

mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    # Rift supports workspace management - could implement workspace deletion here
    echo "Right click on rift workspace - could implement workspace actions"
  else
    # Get the workspace index for switching (rift requires numeric index)
    WORKSPACE_INDEX=$(rift-cli query workspaces 2>/dev/null | jq -r --arg name "$WORKSPACE_ID" '.[] | select(.name == $name) | .index')
    if [ -n "$WORKSPACE_INDEX" ] && [ "$WORKSPACE_INDEX" != "null" ]; then
      # Focus the rift workspace using index
      rift-cli execute workspace switch "$WORKSPACE_INDEX" 2>/dev/null

      # Update highlighting for all workspaces after click
      FOCUSED_WORKSPACE="$WORKSPACE_ID"
      update_all_workspaces
    fi
  fi
}

case "$SENDER" in
"mouse.clicked")
  mouse_clicked
  ;;
"rift_workspace_change")
  # Debug: Log what we receive
  echo "$(date): rift_workspace_change called for $NAME with FOCUSED_WORKSPACE='$FOCUSED_WORKSPACE' PREV_WORKSPACE='$PREV_WORKSPACE'" >> /tmp/rift-script-debug.log
  # For global workspace change events, update all workspace items
  update_all_workspaces
  # Update window indicators with event-aware handling, passing both workspace variables
  SENDER="$SENDER" FOCUSED_WORKSPACE="$FOCUSED_WORKSPACE" PREV_WORKSPACE="$PREV_WORKSPACE" $RELPATH/plugins/spaces/rift-windows.sh
  ;;
*)
  update
  # Update window indicators for this workspace
  $RELPATH/plugins/spaces/rift-windows.sh "$WORKSPACE_ID"
  ;;
esac