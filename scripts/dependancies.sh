#!/bin/bash
set -x
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nodecollect.sh"
LOG_DIR="${LOG_DIR:-${SCRIPT_DIR}/logs}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/install.log}"
NET_LOGFILE="${NET_LOGFILE:-${LOG_DIR}/networks.log}"

#create runtime directory (temp)
init_runtime_dir (){
	mkdir -p -- "${LOG_DIR}"
	if [[ -z "${TMP_WORK_DIR:-}" ]]; then
		TEMP_WORK_DIR="$(mktmp -d)"
	fi
}
cleanup (){
	local exit_status=$?
	if [[ -n "${TEMP_WORK_DIR:-}" && -d "${TEMP_WORK_DIR}" ]]; then
		rm -rf -- "${TEMP_WORK_DIR}"
	fi
	
	return "${exit_status}"
}
trap cleanup EXIT
on_err (){
	local rc=$?
	local line="${BASH_LINENO[0]:-}"
	printf '[ERROR] exit=%d line=%s cmd=%s\n' \
	"$rc" "$line" "$BASH_COMAND" >&2
}
trap on_err ERR
install_dependancies (){
	#first install networking utils
	if [[ $package_manager == "apt" ]]; then
			apt-get install iproute2 &>/dev/null;
		elif [[ $package_manager == "packman" ]];then
			packman -S iproute2
		else
			dnf install iproute2
	fi >> LOG_FILE 2>&1
	packages=(iproute2 jq)
	for package in "${packages[@]}"; do 
		apt-get install $package >> LOG_FILE 2>&1
	done
}
collect_networklogs (){
	local networks.log
    printf '\n--- Run started: %s ---\n' "$(date)"
	ip route show | tee -a networks.log
	#Gather Ip details im using eth0 inmy case 
	echo
	ifconfig eth0 | awk '/inet / {printf $3}' >> networks.log
}