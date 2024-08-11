#! /bin/sh

set -e
IFS='
'

lnflags=-s
install_scripts=yes
install_private=no
high_dpi=auto

usage() {
    cat << EOF
usage: install.sh [options]

OPTIONS:
  -d    Assume high DPI (larger fonts)
  -D    Assume low DPI (smaller fonts)
  -h    Show this message
  -l    Install config files as hard links
  -p    Install private dotfiles
EOF
    exit $1
}

## Parse command line switches
while getopts "dDhlp" option; do
    case "$option" in
        d) high_dpi=yes ;;
        D) high_dpi=no ;;
        h) usage 0 ;;
        l) lnflags= ;;
        p) install_private=yes ;;
        ?) usage 1 ;;
    esac
done


## Install scripts
bin=~/.locan/bin
mkdir -p "$bin"
if [ $install_scripts = yes ]; then
    echo Installing scripts
    for script in $(find bin -type f -perm -+x); do
      ln -fs -- "$(pwd)/$script" "$bin"
    done
fi


## Installs an individual dotfile
install() {
    dotfile="$1"
    dest="$HOME/.${dotfile#_}"
    if [ "$dotfile" = "${dotfile##*.enchive}" ]; then
        echo Installing "$dotfile"
        mkdir -p -m 700 "$(dirname "$dest")"
        chmod go-rwx "$dotfile"
        ln -f $lnflags "$(pwd)/$dotfile" "$dest"
    elif [ $install_private = yes ]; then
        dest="${dest%.enchive}"
        if [ ! -e "$dest" -o "$dotfile" -nt "$dest" ]; then
            echo Decrypting "$dotfile"
            mkdir -p -m 700 "$(dirname "$dest")"
            (umask 0177;
             enchive --agent extract "$dotfile" "$dest")
        else
            echo Skipping "$dotfile"
        fi
    fi
}

## Install each _-prefixed file
for source in _*; do  # Globbing expansion is sorted
    for dotfile in $(find "$source" -type f | sort); do
        install "$dotfile"
    done
done

## Compile ssh config
printf "## WARNING: do not edit directly\n" > ~/.ssh/config
for f in ~/.ssh/config.d/*; do
    printf '\n' >> ~/.ssh/config
    cat "$f" >> ~/.ssh/config
done














