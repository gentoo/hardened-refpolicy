#!/bin/sh

# Copyright 2013,2014 Sven Vermeulen <swift@gentoo.org>
# Copyright 2017-2022 Jason Zaman <perfinion@gentoo.org>
# Copyright 2022 Kenton Groombridge <concord@gentoo.org>
# Licensed under the GPL-3 license

NEWVERSION="${1}"

PACKAGES="
sys-libs/libsepol
sys-apps/secilc
sys-libs/libselinux
sys-libs/libsemanage
sys-apps/checkpolicy
sys-apps/policycoreutils
sys-apps/selinux-python
sys-apps/semodule-utils
sys-apps/mcstrans
sys-apps/restorecond
"
# app-admin/setools not released together
# dev-python/sepolgen became selinux-python in 2.7 release

SCAN="$(command -v pkgcheck || command -v repoman)"
COMMIT="$(command -v pkgdev || command -v repoman)"

usage() {
  echo "Usage: $0 <release date> <newversion>"
  echo ""
  echo "Example: $0 3.4_rc1"
  echo ""
  echo "The script will update the live ebuilds then copy towards the"
  echo "<newversion>."
  echo ""
  echo "The following environment variables must be declared correctly for the script"
  echo "to function properly:"
  echo "  - GENTOOX86 should point to the gentoo-x86 checkout"
  echo "    E.g. export GENTOOX86=\"/usr/portage\""
}

assertDirEnvVar() {
  VARNAME="${1}"
  eval VARVALUE='$'${VARNAME}
  if [ -z "${VARVALUE}" ] || [ ! -d "${VARVALUE}" ]
  then
    echo "Variable ${VARNAME} (value \"${VARVALUE}\") does not point to a valid directory."
    exit 1
  fi
}

die() {
  printf "\n"
  echo "!!! Error: $*"
  exit 2
}

# scan the tree for QA issues with pkgcheck or repoman
doScan() {
  if [[ "$(basename "${SCAN}")" == "pkgcheck" ]]; then
    "${SCAN}" -q scan --staged
  else
    "${SCAN}" -q full
  fi
}

# commit the current staged changes with pkgdev or repoman
doCommit() {
  "${COMMIT}" -q commit -m "${@}"
}

# set the release date in the live ebuilds so it will be correct when copying to the new version
updateLiveEbuilds() {
    local PKG
    local PN
    cd ${GENTOOX86} || die
    echo "Setting release date var in live ebuilds... "

    for PKG in $PACKAGES
    do
        cd "${GENTOOX86}/${PKG}" || die
        PN="${PKG#*/}"
        [[ -f "${PN}-9999.ebuild" ]] || continue

        # make sure the tree is clean so we dont commit anything else by mistake
        [[ -z "$(git status --porcelain -- .)" ]] || die
        git diff --cached --exit-code >/dev/null 2>&1 || die "Uncommitted changes"

        # update header and release date
        sed -i "s@Copyright 1999-20.. Gentoo .*@Copyright 1999-$(date '+%Y') Gentoo Authors@" "${PN}-9999.ebuild"

        # Update PYTHON_COMPAT
        sed -i '/^PYTHON_COMPAT/s/PYTHON_COMPAT=.*$/PYTHON_COMPAT=( python3_{8..10} )/' "${PN}-9999.ebuild" || die

        # no changes, skip
        [[ -z "$(git status --porcelain -- .)" ]] && continue

        # commit changes
        git add "${PN}-9999.ebuild"
        git --no-pager diff --cached
        doScan
        if [[ $? -eq 0 ]]
        then
            doCommit "$PKG: update live ebuild"
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
    cd ${GENTOOX86} || die
    echo "Creating new ebuilds based on 9999 version... "

    for PKG in $PACKAGES
    do
        cd "${GENTOOX86}/${PKG}" || die
        PN="${PKG#*/}"
        [[ -f "${PN}-9999.ebuild" ]] || continue
        [[ -f "Manifest" ]] || continue

        # make sure the tree is clean so we dont commit anything else by mistake
        [[ -z "$(git status --porcelain -- .)" ]] || die "Uncommitted changes"
        git diff --cached --exit-code >/dev/null 2>&1 || die "Uncommitted changes"

        sed -i -e "/${PN}-${NEWVERSION//_/-}/d" Manifest || die
        cp ${PN}-9999.ebuild ${PN}-${NEWVERSION}.ebuild || die

        "${COMMIT}" -q manifest || die
        git add Manifest ${PN}-${NEWVERSION}.ebuild || die

        #git --no-pager diff --cached
        doScan
        if [[ $? -eq 0 ]]
        then
            doCommit "$PKG: bump to ${NEWVERSION}" || die
        else
            git reset -- . || die
        fi
    done
    echo -e "\ndone ${PN}\n"
}

if [ $# -ne 1 ]
then
  usage
  exit 3
fi

# Assert that all needed information is available
assertDirEnvVar GENTOOX86

updateLiveEbuilds

# Create ebuilds
createEbuilds

