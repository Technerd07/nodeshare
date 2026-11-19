#!/bin/bash
set -x
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependancies.sh"
ensure_root
#Gather os information
gather_osinfo (){
	local name package_manager
	local os_id=unknown
	local os_version=""
	local hostname=""
	local pm
	local -a pms=(apk yum pacman dnf zypper apt-get)
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
		if [[ -z "${package_manager}" ]]; then
			echo "Could not identify supported Package Manager!"
			return 1
		fi
		install_dependancies "${package_manager}"
	done
	hostname < "$(hostname)"
	printf '%s\n' "hosname of system: ${hostname}"
}
gather_networking (){
	echo "Networking Information"
	collect_networklogs 	
}

main (){
	init_runtime_dir
	gather_osinfo >> "${LOG_FILE}" 2>&1 ;
}

main "$@"

