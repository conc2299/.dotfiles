#!/bin/sh

RED='\033[0;31m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

say(){
	printf "$1" >&2
}

info(){
	say "${WHITE}Info: $1${NC}\n"
}

warn(){
	say "${YELLOW}Warning: $1${NC}\n"
}

error(){
	say "${RED}Error: $1${NC}\n"
	exit 1
}

get_suffix(){
	local file="$1"
	local delim="$2"
	echo "${file##*$delim}"
}

get_prefix(){
    local file="$1"
    local delim="$2"
    echo "${file%$delim*}"
}

ensure_dir(){
	local dir="$1"
	if ! [ -d "$dir" ]; then
		mkdir -p "$dir"
	fi
}	

# get distro name
# if there's an empty character in the name, replace it with underscore
get_distro(){
	if ! [ -f /etc/os-release ]; then
		error "No distro info"
	fi
	echo $(grep '^NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | sed 's/ /_/g')
}

distro_update_prefix(){
	local distro="$1"
	case "$distro" in
		"Ubuntu" | "Debian")
			echo "apt-get update -q"
		;;
		"Arch_Linux")
			echo "pacman -Sy --quiet"
		;;
		*)
			error "Not support distro: $distro"
		;;
	esac
}

distro_install_prefix(){
	local distro="$1"
	case "$distro" in
		"Ubuntu" | "Debian")
			echo "apt-get install -y"
		;;
		"Arch_Linux")
			echo "pacman -S --noconfirm --needed"
		;;
		*)
			error "Not support distro: $distro"
		;;
	esac
}

distro_info_prefix(){
	local distro="$1"
	case "$distro" in
		"Ubuntu" | "Debian")
			echo "apt-cache show"
		;;
		"Arch_Linux")
			echo "pacman -Si"
		;;
		*)
			error "Not support distro: $distro"
		;;
	esac
}
 
get_package_version(){
	local package_name="$1"
	local distro="$2"
	local info_prefix=$(distro_info_prefix "$distro")
	case "$distro" in
		*)
			echo $($info_prefix $package_name | grep Version | cut -d':' -f2 | tr -d ' ')
		;;
	esac
}