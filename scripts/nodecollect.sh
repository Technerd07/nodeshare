#!/bin/bash
set -x
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependencies.sh"
#Gathertrap on_err ERR
trap cleanup EXIT
trap 'printf "Interrupted\n" >&2; exit 130' INT
trap 'printf "Terminated\n" >&2; exit 143' TERM 
#gather os information

gather_osinfo (){
	local name package_manager
	local os_id=unknown
	local os_version=""
	local hostname=""
	local pm
	local -a pms=(apk yum pacman dnf zypper apt)
	package_manager=""


	#get os information
	if [[ -r /etc/os-release ]];then
		source /etc/os-release
		#source the file and set the key-value pairs of the variables
		os_id="${ID:-"unknown"}"
		os_version="${VERSION:-}"
		name="${NAME:-}"
	fi
		#check the package manager 
		for pm in "${pms[@]}"; do 
		if command -v $pm > /dev/null 2>&1; then
			echo "package manager: $pm"
			package_manager=$pm
			break;
		fi 
		done
		if [[ -z "${package_manager}" ]]; then
			echo "Could not identify supported Package Manager!"
			return 1
		fi
		install_dependencies "${package_manager}"
	hostname="$(hostname)"
	printf '%s\n' "hosname of system: ${hostname}"
}
gather_networking (){
	echo "Networking Information"
	collect_networklogs 	
}

main (){
	#ensure_root
	init_runtime_dir
 {
	gather_osinfo
 }
 #>>"${LOG_FILE}" 2>&1;
}

main "$@"

