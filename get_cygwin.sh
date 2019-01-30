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
# x64 doesn't really work. So x86 for now.
arch=x86

setup_w98="2.575"
circa_w98="2009/12/01/192034"
setup_nt4="2.762"
circa_nt4="2012/02/04/034515"
setup_2k="2.774"
circa_2k="2013/06/04/121035"
setup_xp_x86="x86-2.874"
circa_xp_x86="2016/08/30/104223"
setup_xp_x64="x86_64-2.874"
circa_xp_x64="2016/08/30/104235"

get_dir() {
    circa=$1
    echo "${root}/cygwin-${circa//\//-}/$arch"
}

get_one() {
    circa=$1
    f=$2
    link="$mirror/circa/${circa}/$f"
    dir="../${f%/*}"
    mkdir -p $dir && wget -P $dir $link
}

get_setup() {
    ver=$1
    circa=$2
    dir=$(get_dir $circa)
    mkdir -p $dir
    [[ -s setup-$ver.exe ]] || wget $mirror/setup/snapshots/setup-${ver}.exe -P $dir
    ( cd $dir && [[ -s setup.ini ]] \
	  || { wget $mirror/circa/${circa}/$arch/setup.bz2 \
		   && bunzip2 setup.bz2 && mv setup setup.ini; } )
}

get_pkgs() {
    circa=$1
    dir=$(get_dir $circa)
    download_log=download-log-${circa//\//-}-$arch

    cd $dir

    # extract from setup.ini the packages to download (only latest version) including sources
    count=0   # used to give an idea about the progress
    for fname in $(grep -E "^@|^install:|^source" setup.ini | grep -A2 '^@' | grep -E "^install:|^source:" | awk '{print $2}'); do
	((count=count+1))
	if [[ -f ../$fname ]]; then
	    echo "===== Skipping $count : $fname"
	    continue  # skip packages that are already present
	else
	    echo "===== $count : $fname" # download packages in background...
	    get_one $circa "$fname" >> $download_log 2>&1
	fi
    done

    # check which packages we have with incorrect size... should be deleted and re-downloaded on next run
    count=0
    grep -E "^@|^install:|^source" setup.ini | grep -A2 '^@' | grep -E "^install:|^source:" | awk '{print $2, $3}' > file.tmp
    exec 5<file.tmp
    while read fname src <&5; do
	((count=count+1))
	# using this was "ls" make it slow, but it works
	#[[ $(ls -l ../$fname | awk '{print $5}') -eq $src ]] || { echo "$count: $fname $src"; rm -f "../$fname"; }
	[[ $(ls -l ../$fname | awk '{print $5}') -eq $src ]] || { echo "$count: $fname $src"; echo "$fname" >> incorrect_size; }
    done
    exec 5<&-
    rm -f file.tmp

    cd "$root_dir"
}

mkdir -p $root
get_setup $setup_w98 $circa_w98
get_pkgs $circa_w98
get_setup $setup_nt4 $circa_nt4
get_pkgs $circa_nt4
get_setup $setup_2k $circa_2k
get_pkgs $circa_2k
# 32-bit version of setup
get_setup $setup_xp_x86 $circa_xp_x86
# 64-bit version of setup
#get_setup x86_64 $setup_xp_x64 $circa_xp_x64
# 32-bit packages
get_pkgs $circa_xp_x86
