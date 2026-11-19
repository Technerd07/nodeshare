#!/bin/bash
set -x
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependancies.sh"

if  [[ $EUID -ne 0 ]];then
	echo "Running as root"
	exec "$0" "$@"
fi
declare -r name
declare -rw package_manager
#Gather os information
gather_osinfo (){
	local os_id=unknown
	local os_version
	local hostname

	#get os information
	if [[ -r /etc/os-release ]];then
		source /etc/os-release
		#source the file and set the key-value pairs of the variables
		os_id="${ID:-"unknown"}"
		os_version="${VERSION:-}"
		name="${NAME:-}"
	fi
	pms=(apk yum pacman dnf zypper apt-get)
	#check the package manager 
		for pm in "${pms[@]}"; do 
		if command -v $pm > /dev/null; then
			echo "package manager: $pm"
			break;
			package_manager=$pm
		fi
	done
	hostname < "$(hostname)"
	printf '%s\n hosname of system: $hostname'
}
gather_networking (){
	

}

main (){
	gather_osinfo
}

main "$@"

