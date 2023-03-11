#!/bin/bash

# just a little part of PNM fetch project.

set -e

check:requirements() {
    local _require_=("cut" "grep" "wc" "tr" "awk") # <- "tr" as bayrakları as as cCc
    local status="true"
    for cmd in "${_require_[@]}" ; do
        if ! command -v "${cmd}" &> /dev/null ; then
            export needed+=("${cmd}")
            local status="false"
        fi
    done

    if ! ${status} ; then
        return 1
    fi
}

fetch:osname() {
    if [[ -f "/etc/os-release" ]] ; then
        source "/etc/os-release"
        echo "${NAME} ${VERSION}"
    else
        echo "independent"
    fi
}

fetch:cpu() {
    echo "$(grep "model name" "/proc/cpuinfo" | wc -l) x$(grep "model name" "/proc/cpuinfo" | cut -f 2 -d ":" | head -n 1)"
}

fetch:uptime() {
    local time="$(cut -d " " /proc/uptime -f 1)" hour="0"
    until [[ "${time%.*}" -le "60" ]] ; do
        local time="$((${time%.*} / 60))"
        local hour="$((${hour} + 1))"
    done

    echo "${hour}h"
}

fetch:memory() {
    local tmemory="$(( ($(grep "MemTotal" /proc/meminfo | tr -dc "0-9") / 1024) / 1024 ))"
    local fmemory="$(( ($(grep "MemFree" "/proc/meminfo" | tr -dc "0-9") / 1024) / 1024 ))"
    if [[ "${fmemory}" -le 0 ]] ; then
        fmemory="$(( ($(grep "MemFree" "/proc/meminfo" | tr -dc "0-9") / 1024)))"
        echo "${tmemory}Gb / ${fmemory}Mb"
    else
        local umemory="$(( ${tmemory} - ${fmemory} ))"
        echo "${tmemory}Gb / ${umemory}Gb"
    fi
}

fetch:storage() {
    if grep -w "sda" "/proc/partitions" &> /dev/null ; then
        echo "$(( ( $(grep -w "sda" "/proc/partitions" | awk "{print \$3}") / 1024) / 1024 ))Gb"
    elif grep -w "sdb" "/proc/partitions" ; then
        echo "$(( ( $(grep -w "sdb" "/proc/partitions" | awk "{print \$3}") / 1024) / 1024 ))Gb"
    elif grep -w "sdc" "/proc/partitions" ; then
        echo "$(( ( $(grep -w "sdc" "/proc/partitions" | awk "{print \$3}") / 1024) / 1024 ))Gb"
    else
        echo "unknown"
    fi
}


fetch:packagemanager() {
    # For now can get just one of them that package managers.
    if [[ -f "/etc/dpkg/dpkg.cfg" ]] && command -v "dpkg" &> /dev/null ; then
        echo "dpkg: $(dpkg --get-selections | grep -v deinstall | wc -l) package(s)"
    elif [[ -f "/etc/pacman.conf" ]] ; then
        :
    fi
}

fetch:desktopenvironment() {
    :
}

convert:json() {
    if ! check:requirements ; then
        echo "{\"require\": ${needed[@]}}"
        return 1
    fi

    echo "{
    \"osname\": \"$(fetch:osname)\",
    \"cpu\": \"$(fetch:cpu)\",
    \"uptime\": \"$(fetch:uptime)\",
    \"memory\": \"$(fetch:memory)\",
    \"storage\": \"$(fetch:storage)\",
    \"packagemanager\": \"$(fetch:packagemanager)\",
    \"desktopenvironment\": \"$(fetch:desktopenvironment)\"
}"
}

if [[ "${BASH_SOURCE}" = "${BASH_SOURCE[-1]}"  ]] ; then
    convert:json
fi