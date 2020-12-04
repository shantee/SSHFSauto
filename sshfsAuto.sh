#!/bin/bash
#
# This script will automatically mount a remote directory i=on your local filesystem 
# it uses SSHFS
# WARNING :: This script is NOT secure /safe since it stores your logins infos
# It is very convenient thought :)
# 
# HOW TO USE :
# first edit your SSH connection informations and the remote path you want to mount
# add the path to an empty folder you want to use as a mount point
# if the folder doesn't exist it will be created automatically
#
# call the script like this : ./sshfsauto.sh mount
# to unmount ./sshfsauto.sh unmount
# after unmounting sshfs will remove the folder it used as a mount point
#
# 
##


# SHH connections informations  password, login , server (ip), port
sshmdp=yoursshpass;
sshlogin=yoursshlogin;
sshserver=192.168.1.18; #ssh server IP or domain name
sshport=22; #ssh port
REMOTEDIR=/your/remote/folder; 
LOCALDIR=/your/mount/point/onyourpc;


# best method to get current script directory (IMO)
rep=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

SCRIPT_NAME=" :::::::: SSHFSMount ::::::::"
SCRIPT_FILE="${0}"
SCRIPT_VER="1.0.0"
SCRIPT_OPTS=("")
SCRIPT_CATCHALL="no"   # Must be either "yes" or "no", enables a '_catchall' method executed when no command given

# some colors
red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
reset="\e[0m"
green_bg="\e[0;102m${expand_bg}"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
rose="\e[41m"



# Print Usage for CLI
function _help () {
    echo
    echo -e "${green}\t\t${SCRIPT_NAME}${reset}\n"
    echo -e "${rose}  this script automatically mount a remote directory using SSHFS  ${reset}\n"
    echo -e "ex: sshfsauto mount | sshfsauto unmount\n"
    echo -e "-v|--version  To display script's version"
    echo -e "-h|--help     To display script's help\n"
    echo -e "Available commands:\n"
    _available-methods
    exit 0
}

# Print CLI Version
function _version () {
    echo
    echo -e "${green}\t\t${SCRIPT_NAME}${reset}\n" 1>&2
    echo -en "\t\tVersion " 1>&2
    echo -en "${SCRIPT_VER}"
    echo -e "" 1>&2
    echo
    exit 0
}

# List all the available public methods in this CLI
function _available-methods () {
    METHODS=$(declare -F | grep -Eoh '[^ ]*$' | grep -Eoh '^[^_]*' | sed '/^$/d')
    if [ -z "${METHODS}" ]; then
        echo -e "No methods found, this is script has a single entry point." 1>&2
    else
        echo "${METHODS}"
    fi
    echo
    exit 0
}

# Dispatches CLI Methods
function _handle () {
    METHOD=$(_available-methods 2>/dev/null | grep -Eoh "^${1}\$")
    if [ "x${METHOD}" != "x" ]; then ${METHOD} ${@:2}; exit 0
    else
        # Call a Catch-All method
        if [ "${SCRIPT_CATCHALL}" == "yes" ]; then _catchall ${@}; exit 0
        # Display usage options
        else  _help; fi
    fi
}

# Generate Autocomplete Script
function _generate-autocomplete () {
    SCRIPT="$(printf "%s" ${SCRIPT_NAME} | sed -E 's/[ ]+/-/')"
    ACS="function __ac-${SCRIPT}-prompt() {"
    ACS+="local cur"
    ACS+="COMPREPLY=()"
    ACS+="cur=\${COMP_WORDS[COMP_CWORD]}"
    ACS+="if [ \${COMP_CWORD} -eq 1 ]; then"
    ACS+="    _script_commands=\$(${SCRIPT_FILE} methods)"
    ACS+="    COMPREPLY=( \$(compgen -W \"\${_script_commands}\" -- \${cur}) )"
    ACS+="fi; return 0"
    ACS+="}; complete -F __ac-${SCRIPT}-prompt ${SCRIPT_FILE}"
    printf "%s" "${ACS}"
}



function _checkMounted(){
exec 2>/dev/null;
 if echo $(stat -f -c '%T' "$LOCALDIR") | grep -q "fuseblk"; then
    echo -e "${red}something is already mounted on $LOCALDIR${reset}"
    echo
    exit;
 fi
}

function _checkDir(){
if [ -d "$LOCALDIR" ]; then
   if [ -n "$(find "$LOCALDIR" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
     echo -e "ok : $LOCALDIR is empty";
    else
     echo -e "${rose}WARNING: $LOCALDIR is not empty ! ${reset}\n"
     exit;
   fi
else 
  echo -e "-> creating $LOCALDIR";
  mkdir $LOCALDIR;
fi
}

#
# User Implementation Begins
#
# Catches all executions not performed by other matched methods
function _catchall () {
    exit 0
}

# ...
function unmount () {
 echo   
 echo -e "${bold}\t  unmounting $REMOTEDIR ...${reset}\n"; 
 fusermount -u $LOCALDIR  > /dev/null 2>&1;
 echo "killing sshfs :";
 killall sshfs;
 echo
 echo -e "${bold}\t  removing $LOCALDIR ${reset}\n"
 rmdir -v $LOCALDIR;
 echo "bye !";
 echo
 exit 0
}

function mount(){
    echo
    _checkMounted
    _checkDir
    echo -e "${bold}-> mounting $REMOTEDIR ...${reset}\n"; 
    echo $sshmdp | sshfs -o password_stdin -o allow_other -p $(echo $sshport) $(echo $sshlogin)@$(echo $sshserver):$(echo $REMOTEDIR) $(echo $LOCALDIR) && echo "ok"
    echo
}
#
# User Implementation Ends
# Do not modify the code below this point.
#
# Main Method Switcher
# Parses provided Script Options/Flags. It ensures to parse
# all the options before routing to a metched method.
#
# `<script> generate-autocomplete` is used to generate autocomplete script
# `<script> methods` is used as a helper for autocompletion scripts
ARGS=(); EXPORTS=(); while test $# -gt 0; do
    OPT_MATCHED=0; case "${1}" in
        -h|--help) OPT_MATCHED=$((OPT_MATCHED+1)); _help ;;
        -v|--version) OPT_MATCHED=$((OPT_MATCHED+1)); _version ;;
        methods) OPT_MATCHED=$((OPT_MATCHED+1)); _available-methods ;;
        generate-autocomplete) _generate-autocomplete ;;
        *) # Where the Magic Happens!
        if [ ${#SCRIPT_OPTS[@]} -gt 0 ]; then for OPT in ${SCRIPT_OPTS[@]}; do SUBOPTS=("${1}"); LAST_SUBOPT="${1}"
        if [[ "${1}" =~ ^-[^-]{2,} ]]; then SUBOPTS=$(printf "%s" "${1}"|sed 's/-//'|grep -o .); LAST_SUBOPT="-${1: -1}"; fi
        for SUBOPT in ${SUBOPTS[@]}; do SUBOPT="$(printf "%s" ${SUBOPT} | sed -E 's/^([^-]+)/-\1/')"
        OPT_MATCH=$(printf "%s" ${OPT} | grep -Eoh "^.*?:" | sed 's/://')
        OPT_KEY=$(printf "%s" ${OPT} | grep -Eoh ":.*?$" | sed 's/://')
        OPT_VARNAME="OPTS_${OPT_KEY}"
        if [ -z "${OPT_VARNAME}" ]; then echo "Invalid Option Definition, missing VARNAME: ${OPT}" 1>&2; exit 1; fi
        if [[ "${SUBOPT}" =~ ^${OPT_MATCH}$ ]]; then
            OPT_VAL="${OPT_VARNAME}"; OPT_MATCHED=$((OPT_MATCHED+1))
            if [[ "${SUBOPT}" =~ ^${LAST_SUBOPT}$ ]]; then
            if [ -n "${2}" -a $# -ge 2 ] && [[ ! "${2}" =~ ^-+ ]]; then OPT_VAL="${2}"; shift; fi; fi
            if [ -n "${!OPT_VARNAME}" ]; then OPT_VAL="${!OPT_VARNAME};${OPT_VAL}"; fi
            declare "${OPT_VARNAME}=${OPT_VAL}"
            EXPORTS+=("${OPT_VARNAME}")
            if [[ "${SUBOPT}" =~ ^${LAST_SUBOPT}$ ]]; then shift; fi
        fi; done; done; fi ;;
    esac # Clean up unspecified flags and parse args
    if [ ${OPT_MATCHED} -eq 0 ]; then if [[ ${1} =~ ^-+ ]]; then
        if [ -n ${2} ] && [[ ! ${2} =~ ^-+ ]]; then shift; fi; shift
    else ARGS+=("${1}"); shift; fi; fi
done
EXPORTS_UNIQ=$(echo "${EXPORTS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
for EXPORT in ${EXPORTS_UNIQ[@]}; do if [[ ${!EXPORT} == *";"* ]]; then
    TMP_VAL=(); for VAL in $(echo ${!EXPORT} | tr ";" "\n"); do TMP_VAL+=("${VAL}"); done
    eval ''${EXPORT}'=("'${TMP_VAL[@]}'")'
fi; done; _handle ${ARGS[@]}; exit 0