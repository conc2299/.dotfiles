#!/bin/sh

# utils
say(){
	printf "$1" >&2
}

get_distro(){
	if ! [ -f /etc/os-release ]; then
		echo "No distro info" >&2
		exit 1
	fi
	echo $(grep '^NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
}

get_package_manager(){
	local distro=$(get_distro)
	case "$distro" in
		"Ubuntu" | "Debian")
			echo apt-get
		;;
		"Arch Linux")
			echo pacman
		;;
		*)
			echo "Not support distro: $distro" >&2
			exit 1
		;;
	esac
}

pm_update_flags(){
	local pm="$1"
	case "$pm" in
		apt-get)
			echo "update"
		;;
		pacman)
			echo "-Sy"
		;;
		*)
			echo "Not support package manager: $pm" >&2
			exit 1
		;;
	esac
}

pm_install_flags(){
	local pm="$1"
	case "$pm" in
		apt-get)
			echo "install -y"
		;;
		pacman)
			echo "-S --noconfirm"
		;;
		*)
			echo "Not support package manager: $pm" >&2
			exit 1
		;;
	esac
}

pm_info_flags(){
	local pm="$1"
	case "$pm" in
		apt)
			echo "show"
		;;
		pacman)
			echo "-Si"
		;;
		*)
			echo "Not support package manager: $pm" >&2
			exit 1
		;;
	esac
}
 
get_version(){
	local software="$1"
	local pm=$(get_package_manager)
	local info_flags=$(pm_info_flags $pm)
	case "$pm" in
		*)
			echo $($pm $info_flags $software | grep Version | cut -d':' -f2 | tr -d ' ')
		;;
	esac
}

# proxy
select_proxy_software(){
	say "Choose proxy:\n1) v2ray\n2) clash\n"
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
		*)
			echo Unknown proxy >&2
			exit -1
			;;
	esac
}


# window manager


# 

# install softwares
proxy=$(select_proxy_software)
echo $proxy
get_version v2ray