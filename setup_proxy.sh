#!/bin/sh

# import utils
. ./setup.sh
. ./shell.sh

# config

# proxy
select_proxy_software(){
	say "Choose proxy:\n1) v2ray\n2) clash\n3) mihomo\n"
	read -p "Input a number(default 1): " sel
	if [ -z $sel ]; then
		sel=1
	fi;
	case "$sel" in
		1)
			echo v2ray
			;;
		2)
			echo clash
			;;
		3) 	
			echo mihomo
			;;
		*)
			echo Unknown proxy >&2
			exit -1
			;;
	esac
}

sudo $(distro_update_prefix $(get_distro))
proxy=$(select_proxy_software)
say "Selected proxy: $proxy\n"
case $proxy in
    "v2ray")
        ;;
    "mihomo")
        install_package mihomo
        chmod +x "$HOME/.local/bin/mihomo/mihomo"
        install_package mihomo-tui
        add_source "bash" "$HOME/.local/bin/mihomo/setup.sh"
        add_source "zsh" "$HOME/.local/bin/mihomo/setup.sh"
        add_source "bash" "$HOME/.local/bin/mihomo-tui/setup.sh"
        add_source "zsh" "$HOME/.local/bin/mihomo-tui/setup.sh"
        stow "mihomo-tui"
		stow "mihomo"
        ;;
  *)
    error "Unsupported proxy software: $proxy"
    exit 1
    ;;
esac








