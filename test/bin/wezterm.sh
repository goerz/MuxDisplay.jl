#!/bin/bash

if [ "$1" == "cli" ] && [ "$2" == "list" ] && [ "$3" == "--format" ]; then
  # Output the JSON only when --format is json
  if [ "$4" == "json" ]; then
    cat <<EOF
[
  {
    "window_id": 0,
    "tab_id": 0,
    "pane_id": 0,
    "size": {
      "rows": 24,
      "cols": 80
    }
  },
  {
    "window_id": 1,
    "tab_id": 1,
    "pane_id": 1,
    "size": {
      "rows": 30,
      "cols": 80
    }
  }
]
EOF
    exit 0
  else
    exit 1
  fi
elif [ "$1" == "cli" ] && [ "$2" == "send-text" ] && [ "$3" == "--no-paste" ] && [ "$4" == "--pane-id" ]; then
    input=$(cat | sed 's/[[:space:]]*$//')  # remove trailing whitespace
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
        echo "$input" >> wezterm_unrecognized_input.log
        exit 1
    fi
else
    echo "$@" >> wezterm_unrecognized_args.log
    exit 1
fi
