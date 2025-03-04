#!/bin/bash


set -e  # Exit on any error
LC_ALL=C
PATH=/usr/bin:/bin

# Enable CRB and EPEL repositories the texinfo package is available in CRB repo
dnf config-manager --set-enabled crb || yum config-manager --set-enabled crb
dnf install -y epel-release || yum install -y epel-release

echo "Repositories enabled. Proceeding with checks..."

bail() { echo "FATAL: $1"; exit 1; }
#funtion to check and install
install_if_missing() {
    if ! command -v $2 &>/dev/null; then
        echo "$1 ($2) not found. Installing..."
        dnf install -y $3 || yum install -y $3 || bail "Failed to install $1"
    fi
}

ver_check() {
    if ! type -p $2 &>/dev/null; then
        echo "ERROR: Cannot find $2 ($1), installing..."
        dnf install -y $4 || yum install -y $4 || bail "Failed to install $1"
    fi
    v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
    if printf '%s\n' $3 $v | sort --version-sort --check &>/dev/null; then
        printf "OK: %-9s %-6s >= $3\n" "$1" "$v"
    else
        echo "Updating $1..."
        dnf install -y $4 || yum install -y $4 || bail "Failed to update $1"
    fi
}

ver_kernel() {
    kver=$(uname -r | grep -E -o '^[0-9\.]+')
    if printf '%s\n' $1 $kver | sort --version-sort --check &>/dev/null; then
        printf "OK: Linux Kernel $kver >= $1\n"
    else
        printf "ERROR: Linux Kernel ($kver) is TOO OLD ($1 or later required)\n"
    fi
}

# initinal requirement 
install_if_missing "grep" "grep" "grep"
install_if_missing "sed" "sed" "sed"
install_if_missing "sort" "coreutils" "coreutils"

# checking the version of packages and installing
ver_check Coreutils sort 8.1 coreutils
ver_check Bash bash 3.2 bash
ver_check Binutils ld 2.13.1 binutils
ver_check Bison bison 2.7 bison
ver_check Diffutils diff 2.8.1 diffutils
ver_check Findutils find 4.2.31 findutils
ver_check Gawk gawk 4.0.1 gawk
ver_check GCC gcc 5.2 gcc
ver_check "GCC (C++)" g++ 5.2 gcc-c++
ver_check Grep grep 2.5.1a grep
ver_check Gzip gzip 1.3.12 gzip
ver_check M4 m4 1.4.10 m4
ver_check Make make 4.0 make
ver_check Patch patch 2.5.4 patch
ver_check Perl perl 5.8.8 perl
ver_check Python python3 3.4 python3
ver_check Sed sed 4.1.5 sed
ver_check Tar tar 1.22 tar
ver_check Texinfo texi2any 5.0 texinfo
ver_check Xz xz 5.0.0 xz

ver_kernel 4.19

if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]; then
    echo "OK: Linux Kernel supports UNIX 98 PTY"
else
    echo "ERROR: Linux Kernel does NOT support UNIX 98 PTY"
fi

alias_check() {
    if $1 --version 2>&1 | grep -qi $2; then
        printf "OK: %-4s is $2\n" "$1"
    else
        printf "ERROR: %-4s is NOT $2\n" "$1"
    fi
}

echo "Aliases:"
alias_check awk GNU
alias_check yacc Bison
alias_check sh Bash

echo "Compiler check:"
if printf "int main(){}" | g++ -x c++ -; then
    echo "OK: g++ works"
else
    echo "ERROR: g++ compilation failed"
fi
#find the available cores here
if [ -z "$(nproc)" ]; then
    echo "ERROR: nproc is not available or produces empty output"
else
    echo "OK: nproc reports $(nproc) logical cores are available"
fi
