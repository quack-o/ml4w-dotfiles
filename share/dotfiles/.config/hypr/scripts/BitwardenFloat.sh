#!/bin/sh

handle() {
  case $1 in
    windowtitle*)
      # Extract the window ID from the line
      window_id=${1#*>>}

      # Fetch the list of windows and parse it using jq to find the window by its decimal ID
      window_info=$(hyprctl clients -j | jq --arg id "0x$window_id" '.[] | select(.address == ($id))')

      # Extract the title from the window info
      window_title=$(echo "$window_info" | jq '.title')

      # Check if the title matches the characteristics of the Bitwarden popup window
      if [[ "$window_title" == *"(Bitwarden Password Manager) - Bitwarden"* ]]; then
      
        # echo $window_id, $window_title
        # hyprctl dispatch togglefloating address:0x$window_id
        # hyprctl dispatch resizewindowpixel exact 20% 40%,address:0x$window_id
        # hyprctl dispatch movewindowpixel exact 40% 30%,address:0x$window_id

        hyprctl --batch "dispatch togglefloating address:0x$window_id ; dispatch resizewindowpixel exact 20% 40%,address:0x$window_id ; dispatch movewindowpixel exact 40% 30%,address:0x$window_id"        
      fi
      ;;
  esac
}


exec 32> "/tmp/bitwarden.lock"
if ! flock -n 32; then
    printf 'another instance is running\n';
    exit 1
fi


# Listen to the Hyprland socket for events and process each line with the handle function
socat -U - UNIX-CONNECT:/run/user/1000/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
echo "?"