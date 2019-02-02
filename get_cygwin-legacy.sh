#!/bin/bash

# 		Download Cygwin packages compatible with Windows XP
#         ===================================================
#
#    Created based on information from the FruitBat.org:
#               http://www.fruitbat.org/Cygwin/timemachine.html
#    Setup files will be downloaded into current directory.
#	Repo structure will be created into "./CygwinTimeMachine" directory.
#    Once downloaded use the setup to install from local repository.
#
#                                            czvtools @ 2016
#

mirror="http://ctm.crouchingtigerhiddenfruitbat.org/pub/cygwin"
root=./cygwin-mirror
root_dir="$PWD"
circa_legacy="2009/12/27/103117"

get_dir() {
    circa=$1
    echo "${root}/cygwin-legacy-${circa//\//-}"
}

get_one() {
    circa=$1
    f=$2
    link="$mirror/circa-legacy/${circa}/$f"
    dir="${f%/*}"
    mkdir -p $dir && wget -P $dir $link
}

get_setup() {
    circa=$1
    dir=$(get_dir $circa)
    mkdir -p $dir
    [[ -s setup-legacy.exe ]] || wget $mirror/setup/legacy/setup-legacy.exe -P $dir
    ( cd $dir && [[ -s setup-legacy.ini ]] \
	  || { wget $mirror/circa-legacy/${circa}/setup-legacy.bz2 \
		   && bunzip2 setup-legacy.bz2 && mv setup-legacy setup-legacy.ini; } )
}

get_pkgs() {
    circa=$1
    dir=$(get_dir $circa)
    download_log=download-log-${circa//\//-}

    cd $dir

    # extract from setup.ini the packages to download (only latest version) including sources
    count=0   # used to give an idea about the progress
    for fname in $(grep -E "^@|^install:|^source" setup-legacy.ini | grep -A2 '^@' | grep -E "^install:|^source:" | awk '{print $2}'); do
	((count=count+1))
	if [[ -f $fname ]]; then
	    echo "===== Skipping $count : $fname"
	    continue  # skip packages that are already present
	else
	    echo "===== $count : $fname" # download packages in background...
	    get_one $circa "$fname" >> $download_log 2>&1
	fi
    done

    # check which packages we have with incorrect size... should be deleted and re-downloaded on next run
    count=0
    grep -E "^@|^install:|^source" setup-legacy.ini | grep -A2 '^@' | grep -E "^install:|^source:" | awk '{print $2, $3}' > file.tmp
    exec 5<file.tmp
    while read fname src <&5; do
	((count=count+1))
	# using this was "ls" make it slow, but it works
	#[[ $(ls -l ../$fname | awk '{print $5}') -eq $src ]] || { echo "$count: $fname $src"; rm -f "../$fname"; }
	[[ $(ls -l $fname | awk '{print $5}') -eq $src ]] || { echo "$count: $fname $src"; echo "$fname" >> incorrect_size; }
    done
    exec 5<&-
    rm -f file.tmp

    cd "$root_dir"
}

mkdir -p $root
get_setup $circa_legacy
get_pkgs $circa_legacy
