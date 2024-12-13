#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -Eeuo pipefail

#---------  Global variables  -------------------
VIRSH="sudo virsh"
SUPPORTED_OS=("Ubuntu"
              "Microsoft Windows")

#---------      Functions    -------------------
function list_domains_by_state() {
    local state="$1"
    virsh list --all | awk -v a="$state" '{ if ( NR > 2 && $3 == a ) { print $2 } }'
}

function find_in_array() {
    local item=$1
    local -n array=$2

    for e in "${array[@]}"; do [[ "$e" == "$item" ]] && return 0; done
    return 1
}

function pmsuspend_guests() {
    local pmsuspend_target=$1
    local max_timeout=120
    local loop=0
    declare -A endstates
    local endstates=( [mem]="pmsuspended" [disk]="shut" )
    declare -A waiting_list

    checkstate=${endstates[$pmsuspend_target]}
    if [ -z "$checkstate" ]; then
        echo "Error: suspend target $pmsuspend_target is unsupported"
        return 255
    fi
    if [[ $pmsuspend_target == "disk" ]]; then
        max_timeout=300
    fi
    local running_domains
    mapfile -t running_domains < <(list_domains_by_state "running")
    for DOMAIN in "${running_domains[@]}"; do
        local osname
        osname=$($VIRSH guestinfo "$DOMAIN" --os | grep os.name | awk '-F: ' '{ print $2 }')
        if [ -z "$osname" ]; then
            echo "Error: Check if VM $DOMAIN supports or has qemu guest agent installed"
            return 255 
        fi
        if ! find_in_array "$osname" SUPPORTED_OS; then
            echo "Error: Domain $DOMAIN (OS name $osname) is not of supported OS type"
            return 255 
        fi
        echo "Trigger $DOMAIN suspend to $pmsuspend_target..."
        set +e
        suspend_ret=$($VIRSH dompmsuspend "$DOMAIN" "$pmsuspend_target" 2>&1)
        set -e
        if [[ $suspend_ret =~ "successfully suspended" ]];then
            echo "$suspend_ret"
            waiting_list[$DOMAIN]="running"
        else
            if [[ $suspend_ret =~ "suspend-to-ram not supported by OS" ]]; then
                echo "suspend-to-ram not supported by $DOMAIN"
                continue
            else
                echo "$DOMAIN suspend to $pmsuspend_target fail"
                return 255
            fi
        fi
    done
    set +u
    running_vm_num=${#waiting_list[*]}
    set -u
    while [[ $running_vm_num -ne 0 ]]; do
        loop=$((loop+1))
        echo "$loop: Waiting for guest VM to be in target state..."
        local -a domains_in_state
        mapfile -t domains_in_state < <(list_domains_by_state "$checkstate")
        for i in "${!waiting_list[@]}"; do
            if [[ "${waiting_list[$i]}" == "suspended" ]]; then
                continue
            fi
            suspend=0
            for j in "${domains_in_state[@]}"; do
                if [[ "$i" == "$j" ]]; then
                    suspend=1
                    break
                fi
            done
            if [[ $suspend -eq 1 ]]; then
                echo "$i done"
                waiting_list[$i]="suspended"
                running_vm_num=$((running_vm_num-1))
            fi
        done
        sleep 1
        if [[ $loop -gt $max_timeout ]]; then
            echo "timeout"
            return 255
        fi
    done
}

function pmresume_guests() {
    local max_timeout=60
    local loop=0
    local checkstate="running"
    list_domains_by_state pmsuspended | while read -r DOMAIN; do
        echo -n "Resuming pmsuspended $DOMAIN ..."
        if $VIRSH dompmwakeup "$DOMAIN"; then
            while true ; do
                loop=$((loop+1))
                echo "$loop: Waiting for $DOMAIN to be in target state..."
                local domain_in_state
                domain_in_state=$(list_domains_by_state "$checkstate" | grep -w "$DOMAIN")
                if [[ -n $domain_in_state ]]; then
                    echo "done"
                    break
                fi
                sleep 1
                if [[ $loop -gt $max_timeout ]]; then
                    echo "timeout"
                    break
                fi
            done
        fi
    done
}

function show_help() {
    printf "%s [-h] [--suspend] [--hibernate] [--resume]\n" "$(basename "${BASH_SOURCE[0]}")"
    printf "Options:\n"
    printf "\t-h\tshow this help message\n"
    printf "\t--suspend\tSuspend all running guests if supported.\n"
    printf "\t\t\tIf suspend-to-ram is not supported by guest, hibernation will be used instead.\n"
    printf "\t--hibernate\tHibernate all running guests if supported.\n"
    printf "\t--resume\tResume all currently suspended guests\n"
    printf "\tNote: Only guests of below OS type are supported:\n"
    for os in "${SUPPORTED_OS[@]}"; do
        printf "\t\t%s\n" "$os"
    done
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit 0
                ;;

            --suspend)
                pmsuspend_guests "mem" || return 255
                # For supported OS but may not support suspend-to-ram, do hibernate instead
                pmsuspend_guests "disk" || return 255
                ;;

            --hibernate)
                pmsuspend_guests "disk" || return 255
                ;;

            --resume)
                pmresume_guests || return 255
                ;;

            -?*)
                echo "Error: Invalid option: $1"
                show_help
                return 255
                ;;
            *)
                echo "Error: Unknown option: $1"
                return 255
                ;;
        esac
        shift
    done
}

#-------------    main processes    -------------
trap 'echo "Error line ${LINENO}: $BASH_COMMAND"' ERR

parse_arg "$@" || exit 255

echo "Done: \"$(realpath "${BASH_SOURCE[0]}") $*\""
