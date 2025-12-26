#!/bin/sh

data_file="softwares.data"
software_dir="$HOME/.local/bin"
RED='\033[0;31m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# utils
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

ensure_dir(){
	local dir="$1"
	if ! [ -d "$dir" ]; then
		mkdir -p "$dir"
	fi
}	

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
	local software="$1"
	local distro="$2"
	local info_prefix=$(distro_info_prefix "$distro")
	case "$distro" in
		*)
			echo $($info_prefix $software | grep Version | cut -d':' -f2 | tr -d ' ')
		;;
	esac
}

# utils for this particular script

uncompress_file(){
	local file="$1"
	case "$file" in
		*.tar.gz|*.tgz)
			tar -xzf "$file" -C ${file%.*}
			;;
		*.zip)
			unzip "$file" -d ${file%.*}
			;;
		*)
			warn "Not a compressed file: $file"
			;;
	esac
}

get_suffix(){
	local file="$1"
	local delim="$2"
	echo "${file##*$delim}"
}

# return empty string if not found
get_record_value_when(){
	local file="$1"
	local query_field="$2"
	local when_field="$3"
	local when_value="$4"
	if ! [ -f "$file" ]; then
		error "No data file: $file"
	fi
	echo $(awk -F'[[:space:]]+' -v wf="$when_field" -v wv="$when_value" -v qf="$query_field" '
		NR == 1 { 
			for(i=1;i<=NF;i++) {
				if ($i==wf) { when_index=i }
				if ($i==qf) { field_index=i }
			}
			if (!when_index) {exit 1}
			if (!field_index) {exit 1}
			next
		}
		$when_index == wv {
			print $field_index
		}
	' "$file")
}

get_required_version(){
	local software="$1"
	local file="$2"
	echo $(get_record_value_when "$file" "version" "name" "$software")
}

get_required_package_name(){
	local software="$1"
	local file="$2"
	local distro="$3"
	echo $(get_record_value_when "$file" "$distro" "name" "$software")
}

# version compare using SemVer rules
compare_semver() {
  awk -v a="$1" -v b="$2" '
  BEGIN {
    # split into fields by dot
    nA = split(a, A, "\\.")
    nB = split(b, B, "\\.")
    max = (nA > nB ? nA : nB)

    for (i = 1; i <= max; i++) {
      pa = (i in A ? A[i] : "0")
      pb = (i in B ? B[i] : "0")

      # if entirely digits -> numeric value, else treat as 0
      if (pa ~ /^[0-9]+$/) pa_num = pa + 0
      else pa_num = 0

      if (pb ~ /^[0-9]+$/) pb_num = pb + 0
      else pb_num = 0

      if (pa_num < pb_num) { print -1; exit 0 }
      if (pa_num > pb_num) { print 1; exit 0 }
      # otherwise equal, continue
    }
    print 0
  }'
}

check_version_meet_requirement(){
	local current_version="$1"
	local required_version="$2"
	local compare=${required_version%%[0-9]*}
	case "$compare" in
		">=")
			comp=$(compare_semver "$current_version" "${required_version#">="}")
			if [ "$comp" -ge 0 ]; then
				return 0
			fi
			;;
		">")
			comp=$(compare_semver "$current_version" "${required_version#">="}")
			if [ "$comp" -gt 0 ]; then
				return 0
			fi
			;;
		"<=")
			comp=$(compare_semver "$current_version" "${required_version#"<="}")
			if [ "$comp" -le 0 ]; then
				return 0
			fi
			;;
		"<")
			comp=$(compare_semver "$current_version" "${required_version#"<"}")
			if [ "$comp" -lt 0 ]; then
				return 0
			fi
			;;
		"==")
			comp=$(compare_semver "$current_version" "${required_version#"=="}")
			if [ "$comp" -eq 0 ]; then
				return 0
			fi
			;;
		*)
		 	say "Unknown version compare operator: $compare\n"
			exit 1
			;;
	esac
	return 1
}

install_package(){
	local software="$1"
	local distro="$(get_distro)"
	local package_version=$(get_package_version "$software" "$distro")
	local required_version=$(get_required_version "$software" "$data_file")
	local external_link=$(get_record_value_when "$data_file" "link" "name" "$software")
	if [ -z "$required_version" ]; then
		warn "No required version for $software, skip version check"
		required_version=">=0.0.0"
	fi
	if check_version_meet_requirement "$package_version" "$required_version"; then
		info "$software version $package_version meets requirement $required_version, install from package manager"
		package_name="$(get_required_package_name "$software" "$data_file" "$distro")"
		install_cmd="$(distro_install_prefix "$distro") $package_name"
		info "Running command: $install_cmd"
		sudo $install_cmd
	elif [ -n "$external_link" ]; then
		info "$software version $package_version does not meet requirement $required_version, installing from external link"
		ensure_dir "$software_dir"
		file_name=$(get_suffix "$external_link" "/")
		info "Downloading from $external_link to $software_dir/$file_name"
		curl -L "$external_link" -o "$software_dir/$file_name"
		if [ $? -ne 0 ]; then
			error "Download $software failed"
		fi
		uncompress_file "$software_dir/$file_name"
	else
		error "$software version $package_version does not meet requirement $required_version, and no external link provided"
	fi
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

sudo $(distro_update_prefix $(get_distro))
proxy=$(select_proxy_software)
say "Selected proxy: $proxy\n"
install_package "$proxy"
