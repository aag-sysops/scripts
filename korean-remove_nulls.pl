#!/usr/bin/perl -0777 -p

# Make the record terminator "crlf" per wintel standards rather
# than the UNIX "newline" terminator.
#
# Note that the command line switch -0777 invoked above causes the entire
# input file to be treated as a single record.  This must be done so that
# the newline can be read as a character rather than implicitly ignored
# as the record terminator as is typically the case.  The -p switch
# simply implies a "while (<>)" loop around the program code and prints
# the result when input hits EOF.
#
# Created 6/5/01 by Rob Scott.

s/\0/ /g;


# That's it.  Pretty stupid, isn't it.  Useful, but utterly simple.
