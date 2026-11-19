#!/bin/bash
set -x
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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
trap 'echo "Execution Interrupted\n">&2;exit 130' INT #Handle crtl+c interrupt
trap 'printf "Terminated\n" >&2; exit 143' TERM
#Run as root
ensure_root (){
	if [[ $EUID -ne 0 ]]; then
		if ! command -v sudo > /dev/null; then
			printf 'Error: root privileges required and sudo is not installed.\n' >&2
			return 1;
		fi
		printf 'Elevating previliges with sudo ...\n' >&2
		exec sudo -- "$0" "$@"
	fi
}
install_package (){
	local pm=$1
	local package=$2

	case "$pm" in
		apt-get)
			DEBIAN_FRONTEND=noninteractive apt-get update -qq
			DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${package}"  
			;;
		packman)
			pacman -S --noconfirm --needed "${package}"
			;;
		dnf)
			dnf install -y -q "${package}"
			;;
		yum)
			yum install -y -q "${package}"
			;;
		apk)
			apk add --no-cache "${package}"
			;;
		zypper)
			zypper --non-interactive install "${package}"
			;;
		*)
			echo "Unsupported package manager ${pm}" >&2
			return 1;
		;;
		esac
}
install_dependencies (){
	local -a pkgs=(iproute2 jq)
	local pm=$1
	init_runtime_dir
	for pkg in "${pkgs[@]}"; do
		install_package "$pm" "$pkg" >> "${LOG_FILE}" 2>&1
	done
}
collect_networklogs (){
	local ip_addr=""
    printf '\n--- Run started: %s ---\n' "$(date)"
	ip route show | tee -a "${NET_LOGFILE}"
	#Gather Ip details im using eth0 inmy case 
	echo
	ip_addr="$(ifconfig eth0 | awk '/inet / {printf $3}')"
	printf '%s\n' "${ip_addr}" >> "${NET_LOGFILE}"
}