# If picom is running, kill it to prevent multiple instances
#if ps -A | grep picom; then
	killall -q picom
#fi

# Load picom
picom --config ~/.dotfiles/config/picom.conf --experimental-backend