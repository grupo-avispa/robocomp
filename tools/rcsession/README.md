#rcsession

Utility to manage a session with some processess running into background while showing mixed standard output for all process and logging each one into individual log files.

Includes:
- 'rcSessionLib.sh': Shell script library with functions to manage a session.
- 'rclogtools': Utility to log a command output while keep showing it at the screen. The log file will include a timestamp and (optionally) a label and will be stored at $ROBOCOMP_LOGS or local folder if not defined.
- 'rcmergelogs': Utility to merge some timestamped log files into a unified one.

##Use

rcSessionLib.sh
This library provides shell functions to manage a session. The session must be open with 'openSession' before start desired components (using 'startComponent') and finally wait until finish with 'runSession'.
Log files for each component are internally created (if $ROBOCOMP_LOGS is defined) using 'rclogtool' and merged into a combined one with 'rcmergelogs'.
Some parameters can be configured after import this library into a script.

 openSession
 startComponent "label" "command"
 runSession

rclogtool
The first argument defines a label to be included after the timestamp. An empty field will indicate to do not use any label.
An optional argument can be given to specify the destination filename, that defaults to "label.log".
The destination file path will be relative to $ROBOCOMP_LOGS or local folder if not defined.
That means that typically, if used only with a single argument, the generated log file will be "label.log" at $ROBOCOMP_LOGS folder.

 rclogtool "label" [ "filename" ]

rcmergelogs
The first argument indicate the new combined log file that will be created using individual log files defined into the other parameters.

 rcmergelogs "mergedLog" "logFile1" [ "logFile2" ... ]

###Example: Minimal script content to run a session:

	#!/bin/sh
	. rcSessionLib.sh
	openSession
	startComponent "label1" "command1"
	startComponent "label2" "command2"
	startComponent "label3" "command3"
	...
	startComponent "labelN" "commandN"
	runSession
	exit 0

###Example: To log a command output (stdout and stderr) using "commandLabel" as label and "commandLabel.log" as filename:

 command 2>&1 | rclogtool "commandLabel"

###Example: To log a command output (only stdout) using "LogFile" as filename, without any label:

 command | rclogtool "" "LogFile"

###Example: To log a command output (stdout and stderr) using "commandLabel" as label and "LogFile" as filename:

 command 2>&1 | rclogtool "commandLabel" "LogFile"

###Example: To merge "*.log" files into "folder" and store the unified log file into "full.log":

 rcmergelogs "full.log" "folder/*.log"
