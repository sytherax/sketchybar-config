#!/bin/bash
export RELPATH=$(dirname $0)/../../..
source "$RELPATH/icon_map.sh"

mouse_clicked() {
	if [ "$BUTTON" = "right" ]; then
		yabai -m space --destroy $SID
		sketchybar --trigger space_change --trigger windows_on_spaces
	else
		yabai -m space --focus $SID 2>/dev/null
	fi
}

update() {
	WIDTH="dynamic"
	#BACKGROUND=on

	if [ "$SELECTED" = "true" ]; then
		WIDTH="0"
		#BACKGROUND=off
	fi

	sketchybar --animate tanh 20 --set $NAME icon.highlight=$SELECTED label.width=$WIDTH #background.drawing=$BACKGROUND
}

case "$SENDER" in
"mouse.clicked")
	mouse_clicked
	;;
*)
	# Update focused state
	update
	;;
esac
