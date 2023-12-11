#!/bin/bash
#
# Shell script to log a command output while keep showing it at the screen.
# The log file will be stored at ${ROBOCOMP_LOGS} folder, including a timestamp and (optionally) a label.
# 
# Generated log files can be merged using 'rcmergelogs' tool to get a single log file.
#
# Author: Ale Cruces
# Updated 2020-11
#


# Variables
LABEL_SIZE=16


# --- Begin script ---
if [ $# -ne 1 ] && [ $# -ne 2 ]; then
	printf "Wrong number of arguments.\n"
	printf 'Usage: rclogtool "label" [ "filename" ]\n'
	exit 1
fi

# Disable termination signals if stdin is not a terminal (https://www.gnu.org/software/libc/manual/html_node/Termination-Signals.html):
# - SIGTERM (15): Generic signal used to cause program termination. The normal way to politely ask a program to terminate
# - SIGINT  ( 2): Interrupt signal. Sent when the user types the INTR character (normally Ctrl+c)
# - SIGQUIT ( 3): Quit signal. Similar to SIGINT but controlled by QUIT character (normally Ctrl+\). Produces a core dump when it terminates the process
# - SIGKILL ( 9): Kill signal. Used to cause immediate program termination. It cannot be handled or ignored, and is therefore always fatal
# - SIGHUP  ( 1): Hang-up signal. Used to report that the user’s terminal is disconnected. Also used to report the termination of the controlling process on a terminal to jobs associated with that session
if ! [ -t 0 ]; then
	trap "" SIGTERM SIGINT SIGQUIT SIGHUP
fi

label="$1"
if [ $# -eq 2 ]; then
	relfilename="$2"
else
	# Get filename from label
	if [ "$label" ]; then
		relfilename="${1}.log"
	else
		printf "If no \"label\" is used, a \"filename\" must be specified.\n"
		exit 2
	fi
fi


# Destination file
if [ "${ROBOCOMP_LOGS}" ]; then
	filename="${ROBOCOMP_LOGS}/${relfilename}"
else
	filename="${relfilename}"
fi
filedir=$(dirname "$filename")
if ! [ -d "$filedir" ]; then
	mkdir -p "$filedir"
fi

# Unify label size to align messages
if [ "$label" ]; then
	head="$(printf "%-${LABEL_SIZE}s" "${label}:")"
else
	head=""
fi



# Check if 'ts' command is found (provided by 'moreutils' package)
if [ "$(command -v ts)" ]; then
	tee >(ts "%F %H:%M:%.S  $head" > "$filename")
else
	# 'ts' command not found, using builtin bash's printf date-time functionality (available since Bash 4.2)
	printf "Warning: 'ts' command not found. Install 'moreutils' package to get subsecond resolution\n\n"
	
	if [ "$head" ]; then
		# Extra space to separate message from label
		head="$head "
	fi
	tee >(
		while read -r; do
			printf '%(%F %T)T  %s%s\n' -1 "$head" "$REPLY"
		done > "$filename")
fi

exit 0
