#!/bin/bash


if [ "$1" == "display" ]; then
    if [ "$5"  == "#{pane_width}" ]; then
        echo "100"
        exit 0
    elif [ "$5"  == "#{pane_height}" ]; then
        echo "30"
        exit 0
    elif [ "$3"  == "#{pane_index}" ]; then
        echo "0"
        exit 0
    else
        echo "$@" >> tmux_unrecognized_args.log
        exit 1
    fi
elif [ "$1" == "select-pane" ]; then
    exit 0
elif [ "$1" == "send-keys" ]; then
    input="$4"
    if [ "$input" == "PS1=''" ]; then
        exit 0
    elif [ "$input" == "PS1='> '" ]; then
        exit 0
    elif [ "$input" == "stty -echo" ]; then
        exit 0
    elif [ "$input" == "clear" ]; then
        exit 0
    elif [ "$input" == "stty echo" ]; then
        exit 0
    elif [[ "$input" == *"imgcat.sh"* ]]; then
        exit 0
    elif [[ "$input" == *"read -rs -d t -p"* ]]; then
        exit 0
    elif [[ "$input" == "echo \${CELL_SIZE[1]}x\${CELL_SIZE[2]} >"* ]]; then
        # The test caller should either write a valid "cellsize" file to test
        # proper processing. Or else, the missing file should trigger a failure
        exit 0
    else
        echo "$input" >> tmux_unrecognized_input.log
        exit 1
    fi
else
    echo "$@" >> tmux_unrecognized_args.log
    exit 1
fi
