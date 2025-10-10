#!/bin/bash

### Get real name of current user

RealName=$(dscl . -read /Users/"$(whoami)" RealName | awk 'NR>1 {sub(/^[[:space:]]*/, ""); print; exit}')
sketchybar --set "$NAME" label="$RealName"
