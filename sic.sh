#!/bin/bash
#
# Script Name: sic.sh
#
# Author: Ryan.Y.C.Su

function help() {
    echo "Usage: $0 [options]
Options:
  -a <file>     assemble the file
  -s            run the simulater
  -c <filename> clean up
  -h            help"
}

function assemble() {
    IFS=$'\n'
    RED='\033[0;31m'
    NC='\033[0m'
    error=false

    if [ ! -f ${asmfile} ]; then
        echo "${asmfile}: File does not exist"
        exit 1
    fi

    ./run-asm ${asmfile}

    # Cheak is there any error message in file.lst
    for line in `cat ${lstfile}`
    do
        # If the current line is the first error message in the instruction,
        # print the instruction and error message. Otherwise, only print the
        # error message
        if  [[ "${line}" =~ .*"****".* ]] && ! [[ "${prev}" =~ .*"****".* ]]; then
            error=true
            echo ${prev}
            echo -e " ${RED}error: ${NC}${line/' **** '/}"
        elif [[ "${line}" =~ .*"****".* ]]; then
            error=true
            echo -e " ${RED}error: ${NC}${line/' **** '/}"
        fi

        prev=${line}
    done

    # If there is no error when assembling, copy the object file into DEVF2
    if [ ${error} == false ]; then
        cp ${objfile} DEVF2
    else
        exit 1
    fi
}

function simulator() {
    ./sim 1>/dev/null <<- EOF
s
h 0
r
q
EOF
    cat "DEV06"
}

while getopts "a:shc:" option
do
    case "${option}" in
        a)
            assemble_option=true
            prifix=`basename ${OPTARG} .asm`
            asmfile=${OPTARG}
            lstfile="${prifix}.lst"
            objfile="${prifix}.obj"
            ;;
        s)
            sim_option=true
            ;;
        h)
            help_option=true
            ;;
        c)
            clean_option=true
            filename=${OPTARG}
            ;;
    esac
done

if [ ${OPTIND} -eq 1 ]; then
    help
fi

if [[ ${help_option} == true ]]; then
    help
    exit 0
fi

if [[ ${assemble_option} == true ]]; then
    assemble
fi

if [[ ${sim_option} == true ]]; then
    simulator
fi

if [[ ${clean_option} == true ]]; then
    rm "${filename}.obj" "${filename}.int" "${filename}.lst"
fi
