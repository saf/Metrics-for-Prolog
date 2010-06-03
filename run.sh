#!/bin/bash

`which sicstus`
if [[ $? == 0 ]]
then 
    PL="sicstus"
else
    `which swipl`
    if [[ $? == 0 ]]
    then
	PL="swipl"
    else
	echo 'Sicstus or SWIProlog not found in $PATH'
	exit 1
    fi
fi

# TODO parametryzacja w zaleznosci od PL
swipl -f none -t halt -g "[parse], read_file('$1')."
