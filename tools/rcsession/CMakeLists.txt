cmake_minimum_required(VERSION 2.6)
PROJECT( rcsession )

INSTALL(FILES "rcSessionLib.sh" DESTINATION /opt/robocomp/bin )
INSTALL(PROGRAMS "rclogtool.sh" DESTINATION /opt/robocomp/bin RENAME rclogtool )
INSTALL(PROGRAMS "rcmergelogs.sh" DESTINATION /opt/robocomp/bin RENAME rcmergelogs )
