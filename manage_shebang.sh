#!/bin/sh
#This script requires 'ed', a posix standard text editor

BACKUP=true
VERBOSE=false

usage(){
    echo "Usage: $(basename "$0") -[fepisvh]"
    echo '-f [file]  : the file you want to modify. REQUIRED'
    echo '-e [string]: the executable part of the shebang. OPTIONAL'
    echo '-p [string]: the prefix or path. Can be used to specifiy a hardcoded path. OPTIONAL'
    echo "-i [string]: ignore files that match this string in the shebang. OPTIONAL"
    echo "-s         : skip making a backup of any matching files. OPTIONAL"
    echo "-v         : verbose output"
    echo "-h         : print this help message"
    echo
    echo "Example usage: $(basename "$0") -f my_file.py -p /usr/bin/ -e python3.11"
    echo "               $(basename "$0") -f my_file.py -e ambari-python-wrap -v -s"
}

while getopts 'f:e:p:i:hsv' c
do
    case $c in
        f) FILE=$OPTARG ;;
        e) EXECUTABLE=$OPTARG;;
        p) PREFIX=$OPTARG;;
        i) IGNORE=$OPTARG;;
        s) BACKUP=false;;
        v) VERBOSE=true;;
        h) usage && exit 0;;
        *) usage && exit 1;;

    esac
done

if [ -z "$FILE" ]; then
    printf "Please pass a filename\n"
    usage
    exit 1
fi

#The reason we use ed instead of something like sed is so that it works across
#MacOS and Linux. ed is part of the posix standard.
if ! command -v ed >/dev/null; then
    printf "ERROR\n 'ed' not installed\n" >&2
    printf "('yes | dnf install ed' or 'yes | apt install ed')\n" >&2
    printf "Trying to install ed now...\n"
    if command -v dnf >/dev/null && [ "$(id -u)" -eq 0 ]; then
        yes | dnf install ed || { printf "Installation of ed failed\n"; exit 1; }
    elif command -v dnf >/dev/null && [ "$(id -u)" -ne 0 ]; then
        yes | sudo dnf install ed || { printf "Installation of ed failed\n"; exit 1; }
    elif command -v apt >/dev/null && [ "$(id -u)" -eq 0 ]; then
        yes | apt install ed || { printf "Installation of ed failed\n"; exit 1; }
    elif command -v apt >/dev/null && [ "$(id -u)" -ne 0 ]; then
        yes | sudo apt install ed || { printf "Installation of ed failed\n"; exit 1; }
    elif command -v brew >/dev/null; then
        #This shouldn't be required since ed is part of MacOS, but just in case
        brew install ed || { printf "Installation of ed failed\n"; exit 1; }
    else
        printf "Unable to determine your os. "
        printf "Please install 'ed' manually before continuing\n"
        exit 1
    fi
    if ! command -v ed >/dev/null; then
        printf "Still can't find 'ed'. Check that 'ed' is available in your path\n"
        exit 1
    fi
fi

if [ -z "$EXECUTABLE" ]; then
   EXECUTABLE="ambari-python-wrap"
fi

if [ -z "$PREFIX" ]; then
    PREFIX="/usr/bin/env"
else
    PREFIX="$(printf '%s' "$PREFIX" | sed 's/ //g')"
fi

if [ "$(printf '%s' "$PREFIX" | tail -c 3)" = "env" ]; then
    #Append a space if we use env. This is just in case someone specifies
    #/usr/bin/env instead of using the default
    PREFIX="$PREFIX "
elif [ "$(printf '%s' "$PREFIX" | tail -c 1)" != "/" ]; then
    PREFIX="$PREFIX/"
fi 

if echo "$FILE" | grep ".orig">/dev/null; then
    if "$VERBOSE"; then
        printf "Skipping file '%s' since it's a backup file\n" "$FILE"
    fi
elif [ -n "$IGNORE" ] && head -n 1 "$FILE" | grep "$IGNORE" >/dev/null; then
    if "$VERBOSE"; then
        printf 'Skipping "%s" since its shebang matches "%s"\n' "$FILE" "$IGNORE"
    fi
    exit 0
elif head -n 1 "$FILE" | grep "^#\!" >/dev/null; then
    if [ -w "$FILE" ]; then
        if "$BACKUP"; then
            #Create a backup of the original file in case we need it for verification
            \cp "$FILE" "$FILE.orig"
        fi
        #Delete the first line. Insert #!$PREFIX & $EXECUTABLE.
        #Leave insert mode with [.]. Then write to the file and quit.
        #Everything is separated by '\n' to simulate pressing enter
        printf '1d\ni\n#!%s%s\n.\nwq\n' "$PREFIX" "$EXECUTABLE" | ed -s "$FILE"
    else
        printf "User '%s' doesn't have permission to write to %s\n" "$USER" "$FILE" >&2
        exit 1
    fi
else
    if "$VERBOSE"; then
        printf "Skipping file '%s' since it doesn't have a shebang\n" "$FILE"
    fi
fi
