#!/bin/sh
#
# Author: Ale Cruces
# Updated: 2021-12-01
#


# This variables can be overriden after import this file.
SHOW_FULL_COMMANDS=false
PAUSE_AFTER_RUN_COMMAND="0.1"
HIDE_INTERNAL_CHILDREN=true
WATCH_RUNNING_CHILDREN=true
HIDE_CHILDREN_OUT=false
CHILDREN_OUT_ALIGN=16
# RoboComp specific variables
USE_YAKUAKE=false
KEEP_SESSIONS=9


# Manage session
openSession () {
	# RoboComp specific code
	if [ -n "${ROBOCOMP_LOGS}" ]; then
		printf "Rotate Robocomp logs folder\n"
		rotate "$KEEP_SESSIONS" "${ROBOCOMP_LOGS}"
		mkdir -p "${ROBOCOMP_LOGS}"
	fi
	
	
	# Print script PID
	printf "Starting session: PID %d\n\n" "$$"
	
	# Capture termination signals (https://www.gnu.org/software/libc/manual/html_node/Termination-Signals.html):
	# - SIGTERM (15): Generic signal used to cause program termination. The normal way to politely ask a program to terminate
	# - SIGINT  ( 2): Interrupt signal. Sent when the user types the INTR character (normally Ctrl+c)
	# - SIGQUIT ( 3): Quit signal. Similar to SIGINT but controlled by QUIT character (normally Ctrl+\). Produces a core dump when it terminates the process
	# - SIGKILL ( 9): Kill signal. Used to cause immediate program termination. It cannot be handled or ignored, and is therefore always fatal
	# - SIGHUP  ( 1): Hang-up signal. Used to report that the user’s terminal is disconnected. Also used to report the termination of the controlling process on a terminal to jobs associated with that session
	trap "printf '\nReceived a termination signal\n'; interruptSession" TERM INT QUIT HUP
	
	# Capture exit signal
	trap "closeSession" EXIT
}
runSession () {
	# Session resume
	local pids
	if [ "$SHOW_FULL_COMMANDS" = true ]; then
		pids="$(pgrep -a -P $$)"
	else 
		pids="$(pgrep -l -P $$)"
	fi
	local nPids="$(printf "%s" "$pids" | grep -c '^')"
	if [ $nPids -ne 0 ]; then
		local nTotal="$nPids"
		if [ "$HIDE_INTERNAL_CHILDREN" = true ]; then
			if [ "$SHOW_FULL_COMMANDS" = true ]; then
				pids="$(printf "%s" "$pids" | grep -v -E "^([0-9]+) sed s/\^/(\w+):( +)/$")"
				# RoboComp specific code
				pids="$(printf "%s" "$pids" | grep -v -E "rclogtool (\w+)$")"
			else
				pids="$(printf "%s" "$pids" | grep -v " sed$")"
				# RoboComp specific code
				pids="$(printf "%s" "$pids" | grep -v " rclogtool$")"
			fi
			nPids="$(printf "%s" "$pids" | grep -c '^')"
		fi
		local nHidden=$(($nTotal-$nPids))
		
		printf "\nSession running with %d children:\n%s\n" "$nPids" "$pids"
		if [ $nHidden -ne 0 ]; then
			printf "...and other %d internal more\n" "$nHidden"
		fi
		printf "\n"
		
		if [ "$WATCH_RUNNING_CHILDREN" = true ]; then
			# Show children status into a new terminal
			x-terminal-emulator -e "
				while true; do clear; date
					alive=\$(pgrep -P $$)
					[ -z \"\$alive\" ] && break
					printf \"\nSession running with %d children:\" \"$nPids\"
					printf \"\n\nALIVE:\n\"
					printf \"$pids\" | grep \"^\$alive \"
					printf \"\n\nDEAD:\n\"
					printf \"$pids\" | grep -v \"^\$alive) \"
					sleep 2
				done"
		fi
		
		printf "Press Ctrl+C to end session or wait until all children finish execution...\n\n"
	else
		printf "Session started without any child process running\n\n"
	fi
	
	# RoboComp specific code
	if [ "$USE_YAKUAKE" = true ]; then
		printf "Using Yakuake as launcher: Session should be finished by the user (pressing Ctrl+C) AFTER all yakuake's components are done\n"
		sleep infinity &
	fi
	
	
	# Wait until all children finish or session is interrupted
	wait
}
interruptSession () {
	# Disable new termination signals
	trap "" TERM INT QUIT HUP
	killChildren
	
	exit 0
}
closeSession () {
	printf "Session finished\n"
	
	# RoboComp specific code
	if [ -n "${ROBOCOMP_LOGS}" ]; then
		printf "Merging RoboComp session logs\n"
		rcmergelogs "${ROBOCOMP_LOGS}/full.log" "${ROBOCOMP_LOGS}/*.log"
	fi
}


# Children functions
startComponent () {		# RoboComp specific function
	# Check for proper number of arguments
	if [ $# -lt 2 ]; then
		printf "Wrong number of arguments\n"
		return 1
	fi
	
	local label="$1"
	shift
	local command="$* 2>&1 | rclogtool $label"
	
	if [ "$USE_YAKUAKE" != true ]; then
		runCommand "$label" "$command"
	else
		printf "Starting into Yakuake \"%s\"...\n" "$command"
		
		qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.addSession
		local session="$(qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.activeSessionId)"
		qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.runCommand "$command"
		qdbus org.kde.yakuake /yakuake/tabs org.kde.yakuake.setTabTitle "$session" "$label"
		
		# A yakuake session (similar for a terminal inside a session) can be finished later with the command:
		# 	qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.removeSession "$session"
		# but it appears to send a SIGHUP signal to all children processes recursivelly, so won't stop properly a running robocomp's component.
		# This is the same behaviour that closing sessions/tabs via graphic interface.
	fi
}
runCommand () {
	# Check for proper number of arguments
	if [ $# -lt 2 ]; then
		printf "Wrong number of arguments\n"
		return 1
	fi
	
	local label="$1"
	shift
	local command="$*"
	
	printf "Starting \"%s\"...\n" "$command"
	if [ "$HIDE_CHILDREN_OUT" = true ]; then
		command="$command > /dev/null"
	elif [ -n "$label" ]; then
		local head="$(printf "%-${CHILDREN_OUT_ALIGN}s" "${label}: ")"
		command="$command | sed 's/^/$head/'"
	fi
	eval "$command &"
	sleep "$PAUSE_AFTER_RUN_COMMAND"
}

killChildren () {
	# Check for proper number of arguments
	if [ $# -gt 1 ]; then
		printf "Wrong number of arguments\n"
		return 1
	fi
	
	if [ $# -eq 1 ]; then
		local parent="$1"
	else
		local parent="$$"
	fi
	
	local pids
	local nPids
	
	# Finish children processes properly (or badly if necessary)
	for signal in "SIGTERM" "SIGINT" "SIGKILL"; do
		# Send kill signals to all children
		nPids="$(pkill -$signal -c -P $parent)"
		if [ $nPids -eq 0 ]; then
			printf "No child process running\n\n"
			return
		fi
		case $signal in
			"SIGKILL" )	how="badly ($signal)";;
			* )			how="properly ($signal)";;
		esac
		printf "Killing %s children processes\n" "$how"
		
		# Wait for children to die
		for i in $(seq 1 5); do
			printf "Waiting for children to die... %d running\n" "$nPids"
			sleep 1
			if [ "$SHOW_FULL_COMMANDS" = true ]; then
				pids="$(pgrep -a -P $$)"
			else 
				pids="$(pgrep -l -P $$)"
			fi
			nPids="$(printf "%s" "$pids" | grep -c '^')"
			if [ $nPids -eq 0 ]; then
				printf "All children successfully killed\n\n"
				return
			fi
		done
		printf "There are %d children still alive:\n%s\n\n" "$nPids" "$pids"
	done
}


# Helper functions
rotate () {
	# Check for proper number of arguments
	if [ $# -ne 2 ]; then
		printf "Wrong number of arguments\n"
		return 1
	fi
	
	local toKeep="$1"
	if ! [ $((toKeep)) -ge 1 ]; then
		printf "Wrong number of elements to keep\n"
		return 2	# Returns 2 on non valid value or non integer
	fi
	local basename="$2"
	
	
	# Rotate secuence: basename ---> basename.1 ---> basename.2 ---> ... ---> basename.$toKeep ---> null
	local next=".$((toKeep))"
	local tail
	for tail in $(seq $((toKeep-1)) -1 1 | sed 's/^/./') ""; do
		if [ -e "${basename}${tail}" ]; then
			rm -rf "${basename}${next}" && mv "${basename}${tail}" "${basename}${next}"
		fi
		next="$tail"
	done
}
