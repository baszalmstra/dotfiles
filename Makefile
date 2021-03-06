# Inspiration: https://gist.github.com/DerekV/3030284

.PHONY: all
all: checkplatform git-submodules bashrc fonts alacritty zoxide pulseaudio pavucontrol blueman polybar dunst i3 autorandr jq code-config arandr tmux bat delta

BASE_DIR := $(realpath ./)
INFO_PRINT := \e[1;32m
ERROR_PRINT := \e[1;31m
VERBOSE_PRINT := \e[90m
RESET_PRINT := \e[0m

DOTFILES_DIR?=~/.dotfiles
DOTFILES_REPO?=git@github.com:baszalmstra/dotfiles.git

REQUIRED_PACKAGES=libarchive-tools mpd pulseaudio pavucontrol blueman jq git-color arandr rofi tmux alacritty asciidoc autoconf automake cmake cmake-data curl feh git i3blocks i3lock libasound2-dev libcairo2-dev libconfig-dev libcurl4-openssl-dev libdbus-1-dev libdrm-dev libev-dev libevdev-dev libevdev2 libgl1-mesa-dev libjsoncpp-dev libmpdclient-dev libnl-genl-3-dev libpango1.0-dev libpcre2-dev libpixman-1-dev libpulse-dev libstartup-notification0-dev libtool libxcb-composite0-dev libxcb-cursor-dev libxcb-damage0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-present-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-shape0-dev libxcb-util0-dev libxcb-xfixes0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xrm-dev libxcb1-dev libxcomposite-dev libxdamage-dev libxdg-basedir-dev libxext-dev libxfixes-dev libxinerama-dev libxkbcommon-dev libxkbcommon-x11-dev libxrandr-dev libyajl-dev meson ninja-build pkg-config python-xcbgen python3 python3-sphinx uthash-dev xcb-proto xutils-dev python python-dbus autorandr libx11-dev libxss-dev libglib2.0-dev libgtk-3-dev

#
# Misc
#
is-not-installed=! (dpkg -l | grep -q $(1))

define install-package-template
$(1): update
	@if [ $$$$(dpkg-query -W -f='$$$${Status}' $(1) 2>/dev/null | grep -c "ok installed") -eq 0 ]; \
	then \
		echo "$(INFO_PRINT)Installing $(1)...$(RESET_PRINT)"; \
		sudo apt install -qq -y --no-install-recommends $(1); \
	else \
		echo "$(VERBOSE_PRINT)$(1) already installed$(RESET_PRINT)"; \
	fi
endef

$(foreach pkg,$(REQUIRED_PACKAGES), $(eval $(call install-package-template,$(pkg))))

#
# Utils
#
.PHONY : checkplatform git-update update
checkplatform:
ifneq ($(shell uname),Linux)
	@echo 'Platform unsupported, only available for Linux'  && exit 1
endif
ifeq ($(strip $(shell which apt-get)),)
	@echo 'apt-get not found, platform not supported' && exit 1
endif

git-submodules:
	@git submodule update --init --recursive

update:
	@@echo "$(INFO_PRINT)Updating package list...$(RESET_PRINT)"; \
	sudo apt update -qq

# ssh-public-key: ~/.ssh/id_rsa.pub
# 	@echo "We need an ssh public key"

# ~/.ssh/id_rsa.pub:
# 	@ssh-keygen

# github-configured: ssh-public-key
# 	@ssh -T git@github.com \
# 	|| (echo "You need to add your new public key to github" \
# 	&& cat ~/.ssh/id_rsa.pub \
# 	&& exit 1)

# .PHONY: dotfiles
# dotfiles : github-configured
# 	@if [ ! -d $(DOTFILES-DIR) ] ;\
# 	then \
# 	  echo "dotfiles does not exist, fetching"; \
# 	  git clone --recursive $(DOTFILES-REPO) $(DOTFILES-DIR); \
# 	fi


code-config:
	@mkdir -p ${HOME}/.config/Code/User && \
	ln -sf ${HOME}/.dotfiles/config/code/user/settings.json ${HOME}/.config/Code/User/settings.json

#
# Terminal
#

.PHONY : bashrc alacritty

bashrc: ${HOME}/.inputrc
	@grep -qxF 'source ~/.dotfiles/setup.bash' ~/.bashrc || ( \
	 echo 'source ~/.dotfiles/setup.bash' >> ~/.bashrc && \
	 echo "$(INFO_PRINT)Added bash sourcing to .bashrc$(RESET_PRINT)")

${HOME}/.inputrc: 
	@echo "$(INFO_PRINT)Installing .inputc...$(RESET_PRINT)" && \
	ln -sf ${HOME}/.dotfiles/.inputrc ${HOME}/.inputrc

${HOME}/.config/alacritty: ${HOME}/.dotfiles/config/alacritty
	@ln -sf ${HOME}/.dotfiles/config/alacritty ${HOME}/.config/alacritty

alacritty-apt:
	@sudo add-apt-repository -y ppa:mmstick76/alacritty

alacritty: alacritty-apt ${HOME}/.config/alacritty

#
# Sway
#

sway: sway-install i3-tools

sway-install: wayland i3-config
	@echo "$(INFO_PRINT)Installing sway...$(RESET_PRINT)" && \
	sudo snap install --beta --devmode sway

wayland:
	@sudo sed -i 's/#WaylandEnable=false/WaylandEnable=true/' /etc/gdm3/custom.conf

#
# i3
#

.PHONY: i3 i3-dependencies i3-tools picom picom-dependencies

i3: ${HOME}/.config/i3/config i3-dependencies /usr/bin/i3 i3-tools picom

${HOME}/.config/i3/config: ${HOME}/.dotfiles/config/i3/config
	@echo "$(INFO_PRINT)Installing i3 config...$(RESET_PRINT)" && \
	mkdir -p ${HOME}/.config/i3 && \
	ln -sf ${HOME}/.dotfiles/config/i3/config ${HOME}/.config/i3/config

i3-dependencies: libxcb-xrm-dev libxcb1-dev libxcb-keysyms1-dev libxcb-shape0-dev \
	libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev \
	libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev \
	libxkbcommon-x11-dev autoconf xutils-dev libtool automake

/usr/bin/i3: external/i3-gaps
	@echo "$(INFO_PRINT)Installing i3...$(RESET_PRINT)" && \
	cd ${HOME}/.dotfiles/external/i3-gaps && \
	autoreconf --force --install && \
	mkdir -p /tmp/i3-gaps-build && \
	cd /tmp/i3-gaps-build && \
	${HOME}/.dotfiles/external/i3-gaps/configure \
		--prefix=/usr --sysconfdir=/etc && \
	make && \
	sudo make install

i3-tools: update curl feh i3lock i3blocks rofi-config rofi

rofi-config: ${HOME}/.config/rofi/config.rasi

${HOME}/.config/rofi/config.rasi:
	@echo "$(INFO_PRINT)Installing rofi config...$(RESET_PRINT)" && \
	mkdir -p ${HOME}/.config/rofi && \
	rm -f ${HOME}/.config/rofi/* && \
	ln -sf ${HOME}/.dotfiles/config/rofi/config.rasi ${HOME}/.config/rofi/config.rasi

picom: picom-dependencies /usr/local/bin/picom 
picom-dependencies: meson ninja-build libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libxdg-basedir-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libevdev2
/usr/local/bin/picom: external/picom
	@mkdir -p /tmp/picom-build && \
	meson --buildtype=release external/picom /tmp/picom-build && \
	sudo ninja -C /tmp/picom-build install

autorandr: autorandr-config

autorandr-config: ${HOME}/.config/autorandr/postswitch

${HOME}/.config/autorandr/postswitch:
	@echo "$(INFO_PRINT)Installing autorandr postswitch config...$(RESET_PRINT)" && \
	mkdir -p ${HOME}/.config/autorandr && \
	ln -sf ${HOME}/.dotfiles/config/autorandr/postswitch ${HOME}/.config/autorandr/postswitch && \
	chmod a+x ${HOME}/.config/autorandr/postswitch

#
# Polybar
#

polybar: polybar-dependencies /usr/local/bin/polybar
polybar-dependencies: i3 mpd python3 python3-sphinx pkg-config git cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev python python-dbus
/usr/local/bin/polybar: external/polybar
	@mkdir -p /tmp/polybar-build && \
	cd /tmp/polybar-build && \
	cmake $(BASE_DIR)/external/polybar && \
	make -j$$(nproc) && \
	sudo make install

#
# Dunst
#

.PHONY: dunst dunst-dependencies dunst-config
dunst: dunst-dependencies dunst-config /usr/local/bin/dunst
dunst-dependencies: libdbus-1-dev libx11-dev libxinerama-dev libxrandr-dev libxss-dev libglib2.0-dev libpango1.0-dev libgtk-3-dev libxdg-basedir-dev
dunst-config: ${HOME}/.config/dunst/dunstrc
${HOME}/.config/dunst/dunstrc: 
	@mkdir -p ${HOME}/.config/dunst && \
	ln -sf ${HOME}/.dotfiles/config/dunst/dunstrc ${HOME}/.config/dunst/dunstrc
/usr/local/bin/dunst: external/dunst
	@cd external/dunst && \
	make -j$$(nproc) && \
	sudo make install


#
# Tools
#


zoxide: /usr/local/bin/zoxide

/usr/local/bin/zoxide:
	curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/master/install.sh | sh

bat: /usr/local/bin/bat
/usr/local/bin/bat: /tmp/bat_0.15.1_amd64.deb
	sudo dpkg -i /tmp/bat_0.15.1_amd64.deb

/tmp/bat_0.15.1_amd64.deb:
	wget -O /tmp/bat_0.15.1_amd64.deb https://github.com/sharkdp/bat/releases/download/v0.15.1/bat_0.15.1_amd64.deb

delta: /usr/local/bin/delta ~/.gitconfig

/usr/local/bin/delta: /tmp/delta-0.1.1-x86_64-unknown-linux-gnu/delta
	sudo cp /tmp/delta-0.1.1-x86_64-unknown-linux-gnu/delta /usr/local/bin/

/tmp/delta-0.1.1-x86_64-unknown-linux-gnu/delta: libarchive-tools
	cd /tmp && \
	wget -qO- https://github.com/dandavison/delta/releases/download/0.1.1/delta-0.1.1-x86_64-unknown-linux-gnu.tar.gz | bsdtar -xvf-

~/.gitconfig:
	ln -s ~/.dotfiles/config/.gitconfig ~/.gitconfig

#
# Fonts
#

${HOME}/.local/share/fonts/NerdFonts: external/nerd-fonts
	@echo "$(INFO_PRINT)Installing nerd fonts...$(RESET_PRINT)" && \
	external/nerd-fonts/install.sh -q --link && \
	sudo fc-cache -fv

.PHONY: fonts
fonts: ${HOME}/.local/share/fonts/NerdFonts
