#!/bin/sh

# Copyright 2013,2014 Sven Vermeulen <swift@gentoo.org>
# Copyright 2017-2018 Jason Zaman <perfinion@gentoo.org>
# Licensed under the GPL-3 license

RELEASEDATE="${1}";
NEWVERSION="${2}";

PACKAGES="
sys-libs/libsepol
sys-libs/libselinux
sys-libs/libsemanage
sys-apps/checkpolicy
sys-apps/policycoreutils
sys-apps/selinux-python
sys-apps/semodule-utils
sys-apps/secilc
sys-apps/mcstrans
sys-apps/restorecond
"
# app-admin/setools not released together
# dev-python/sepolgen became selinux-python in 2.7 release

usage() {
  echo "Usage: $0 <release date> <newversion>";
  echo "";
  echo "Example: $0 20170101 2.7_rc1"
  echo "";
  echo "The script will update the live ebuilds then copy towards the";
  echo "<newversion>."
  echo "";
  echo "The following environment variables must be declared correctly for the script";
  echo "to function properly:";
  echo "  - GENTOOX86 should point to the gentoo-x86 checkout";
  echo "    E.g. export GENTOOX86=\"/usr/portage/\"";
}

assertDirEnvVar() {
  VARNAME="${1}";
  eval VARVALUE='$'${VARNAME};
  if [ -z "${VARVALUE}" ] || [ ! -d "${VARVALUE}" ];
  then
    echo "Variable ${VARNAME} (value \"${VARVALUE}\") does not point to a valid directory.";
    exit 1;
  fi
}

die() {
  printf "\n";
  echo "!!! Error: $*";
  exit 2;
};

# set the release date in the live ebuilds so it will be correct when copying to the new version
setLiveReleaseDate() {
    local PKG
    local PN
    cd ${GENTOOX86}
    echo "Setting release date var in live ebuilds... "

    for PKG in $PACKAGES;
    do
        cd "${GENTOOX86}/${PKG}"
        PN="${PKG#*/}"
        [[ -f "${PN}-9999.ebuild" ]] || continue;

        # make sure the tree is clean so we dont commit anything else by mistake
        [[ -z "$(git status --porcelain -- .)" ]] || die
        git diff --cached --exit-code >/dev/null 2>&1 || die "Uncommitted changes"

        # update header and release date
        sed -i "s@Copyright 1999-201. Gentoo .*@Copyright 1999-$(date '+%Y') Gentoo Authors@" "${PN}-9999.ebuild"
        sed -i "/^MY_RELEASEDATE=/s/.*/MY_RELEASEDATE=\"${RELEASEDATE}\"/" "${PN}-9999.ebuild"
        sed -i "/SRC_URI/s@raw.githubusercontent.com/wiki/SELinuxProject/selinux/files/releases@github.com/SELinuxProject/selinux/releases/download@" "${PN}-9999.ebuild"

        # no changes, skip
        [[ -z "$(git status --porcelain -- .)" ]] && continue

        # commit changes
        git add "${PN}-9999.ebuild"
        git --no-pager diff --cached
        repoman -q full
        if [[ $? -eq 0 ]]; then
            repoman -q commit -m "$PKG: update live ebuild"
        else
            git reset -- .
        fi
    done
    echo -e "\ndone ${PN}\n"
}

# Create the new ebuilds
createEbuilds() {
    local PKG
    local PN
    cd ${GENTOOX86}
    echo "Creating new ebuilds based on 9999 version... "

    for PKG in $PACKAGES;
    do
        cd "${GENTOOX86}/${PKG}"
        PN="${PKG#*/}"
        [[ -f "${PN}-9999.ebuild" ]] || continue
        [[ -f "Manifest" ]] || continue

        # make sure the tree is clean so we dont commit anything else by mistake
        [[ -z "$(git status --porcelain -- .)" ]] || die
        git diff --cached --exit-code >/dev/null 2>&1 || die "Uncommitted changes"

        sed -i -e "/${PN}-${NEWVERSION//_/-}/d" Manifest || die
        cp ${PN}-9999.ebuild ${PN}-${NEWVERSION}.ebuild || die

        repoman -q manifest
        git add Manifest ${PN}-${NEWVERSION}.ebuild

        #git --no-pager diff --cached
        repoman -q full
        if [[ $? -eq 0 ]]; then
            repoman -q commit -m "$PKG: bump to ${NEWVERSION}"
        else
            git reset -- .
        fi
    done
    echo -e "\ndone ${PN}\n"
}

if [ $# -ne 2 ];
then
  usage;
  exit 3;
fi

# Assert that all needed information is available
assertDirEnvVar GENTOOX86;

setLiveReleaseDate

# Create ebuilds
createEbuilds;

