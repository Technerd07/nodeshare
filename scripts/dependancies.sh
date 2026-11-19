#!/bin/bash
set -x
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nodecollect.sh"
logfile=install.log

if [[ $EUID -ne 0 ]]; then
	echo "Running as root"
	exec "$0" "$@"
fi

install_dependancies (){
	#first install networking utils
	if [[ $package_manger == "apt" ]]; then
			apt-get install iproute2 &>/dev/null;
		elif [[ $package_manger == "packman" ]];then
			packman -S iproute2
		else
			dnf install iproute2
	fi >> logfile 2>&1
	packages=(iproute2 jq)
	for package in "${packages[@]}"; do 
		apt-get install $package >> logfile 2>&1
	done
}