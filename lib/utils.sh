#!/bin/bash

# helper functions for my scripts, to not double the code


help_file=$(mktemp)

_at_exit()
{
	rm -f $help_file
}
# each file can have it's own trap
trap _at_exit EXIT

help()
{
	comp=$1
	num=$2
	shift
	shift
	num_of_prog_args=$#

	cat - >$help_file

	if test x$1 = x-h -o x$1 = x--help ||
			test $num_of_prog_args -$comp $num; then
		# help requested, or ther was an error in
		# arg check, either way print help string
		cat $help_file
		echo
		# exit won't work here, so we commit sepuku
		kill $$ &>/dev/null
	fi
}

print_help()
{
	cat $help_file
}

# sends stdin to phone
notify_phone='sendxmpp -t -n lm-notif@kurwinet.pl'
