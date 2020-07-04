# Inspiration: https://gist.github.com/DerekV/3030284

.PHONY: all
all: checkplatform git-submodules bashrc fonts zoxide pulseaudio pavucontrol polybar dunst i3 tmux bat delta

BASE_DIR := $(realpath ./)
INFO_PRINT := \e[1;32m
ERROR_PRINT := \e[1;31m
VERBOSE_PRINT := \e[90m
RESET_PRINT := \e[0m

DOTFILES_DIR?=~/.dotfiles
DOTFILES_REPO?=git@github.com:baszalmstra/dotfiles.git

REQUIRED_PACKAGES=libarchive-tools mpd pulseaudio pavucontrol git-color rofi tmux asciidoc autoconf automake cmake cmake-data curl feh git i3blocks i3lock libasound2-dev libcairo2-dev libconfig-dev libcurl4-openssl-dev libdbus-1-dev libdrm-dev libev-dev libevdev-dev libevdev2 libgl1-mesa-dev libjsoncpp-dev libmpdclient-dev libnl-genl-3-dev libpango1.0-dev libpcre2-dev libpixman-1-dev libpulse-dev libstartup-notification0-dev libtool libxcb-composite0-dev libxcb-cursor-dev libxcb-damage0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-present-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-shape0-dev libxcb-util0-dev libxcb-xfixes0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xrm-dev libxcb1-dev libxcomposite-dev libxdamage-dev libxdg-basedir-dev libxext-dev libxfixes-dev libxinerama-dev libxkbcommon-dev libxkbcommon-x11-dev libxrandr-dev libyajl-dev meson ninja-build pkg-config python-xcbgen python3 python3-sphinx uthash-dev xcb-proto xutils-dev python python-dbus autorandr libx11-dev libxss-dev libglib2.0-dev libgtk-3-dev

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

#
# Terminal
#
.PHONY : bashrc 

${HOME}/.inputrc: 
	@echo "$(INFO_PRINT)Installing .inputc...$(RESET_PRINT)" && \
	ln -sf ${HOME}/.dotfiles/.inputrc ${HOME}/.inputrc


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

delta: /usr/local/bin/delta ~/.gitconfig

/usr/local/bin/delta: /tmp/delta-0.1.1-x86_64-unknown-linux-gnu/delta
	sudo cp /tmp/delta-0.1.1-x86_64-unknown-linux-gnu/delta /usr/local/bin/

/tmp/delta-0.1.1-x86_64-unknown-linux-gnu/delta: libarchive-tools
	cd /tmp && \
	wget -qO- https://github.com/dandavison/delta/releases/download/0.1.1/delta-0.1.1-x86_64-unknown-linux-gnu.tar.gz | bsdtar -xvf-

#
# Fonts
#

${HOME}/.local/share/fonts/NerdFonts: external/nerd-fonts
	@echo "$(INFO_PRINT)Installing nerd fonts...$(RESET_PRINT)" && \
	external/nerd-fonts/install.sh -q --link && \
	sudo fc-cache -fv

.PHONY: fonts
fonts: ${HOME}/.local/share/fonts/NerdFonts
