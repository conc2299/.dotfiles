#!/bin/sh

# import utils
. ./utils.sh

# config
data_file="softwares.data"
software_dir="$HOME/.local/bin"

# utils for this particular script
uncompress_file(){
	local file="$1"
	local to_name="$2"
	to_path="$(dirname "${file}")/$to_name"
	ensure_dir "$to_path"
	case "$file" in
		*.tar.gz|*.tgz)
			tar -xzf "$file" -C "$to_path"
			rm "$file"
			;;
		*.gz)
			gunzip -c "$file" > "$to_path/$to_name"
			rm "$file"
			;;
		*.zip)
			unzip "$file" -d "$to_path"
			rm "$file"
			;;
		*)
			warn "Not a compressed file: $file"
			;;
	esac
}


# return empty string if not found
get_record_value_when(){
	local file="$1"
	local query_field="$2"
	local when_field="$3"
	local when_value="$4"
	local empty="/"
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
			if($field_index != "'$empty'") {
				print $field_index
			}
		}
	' "$file")
}

get_required_version(){
	local file="$1"
	local software="$2"
	echo $(get_record_value_when "$file" "version" "name" "$software")
}

get_required_package_name(){
	local file="$1"
	local software="$2"
	local distro="$3"
	echo $(get_record_value_when "$file" "$distro" "name" "$software")
}

get_required_external_link(){
	local file="$1"
	local software="$2"
	echo $(get_record_value_when "$file" "link" "name" "$software")
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
	local package_name=$(get_required_package_name "$data_file" "$software" "$distro")
	local required_version=$(get_required_version "$data_file" "$software")
	local external_link=$(get_required_external_link "$data_file" "$software")

	# get from package manager
	if [ -n "$package_name" ]; then
		info "Found package name for $software on $distro: $package_name"
		local package_version=$(get_package_version "$package_name" "$distro")
	fi

	if [ -z "$required_version" ]; then
		warn "No required version for $software, skip version check"
		required_version=">=0.0.0"
	fi

	if [ -n "$package_version" ] && [ check_version_meet_requirement "$package_version" "$required_version" ]; then
		info "$software version $package_version meets requirement $required_version, install from package manager"
		package_name="$(get_required_package_name "$data_file" "$software" "$distro")"
		install_cmd="$(distro_install_prefix "$distro") $package_name"
		info "Running command: $install_cmd"
		sudo $install_cmd
	elif [ -n "$external_link" ]; then
		info "Installing $software from external link"
		ensure_dir "$software_dir"
		file_name=$(basename "$external_link")
		info "Downloading from $external_link to $software_dir/$file_name"
		curl -L "$external_link" -o "$software_dir/$file_name"
		if [ $? -ne 0 ]; then
			error "Download $software failed"
		fi
		uncompress_file "$software_dir/$file_name" "$software"
	else
		error "$software version $package_version does not meet requirement $required_version, and no external link provided"
	fi
}

