#!/bin/sh

# Copyright 2013,2014 Sven Vermeulen <swift@gentoo.org>
# Licensed under the GPL-3 license

# Prepare new policy release

TRANSLATE="s:\(${HARDENEDREFPOL}\|${REFPOLRELEASE}\):refpolicy/:g";
NEWVERSION="${1}";
# If remote requires a different username, it should be set in ~/.ssh/config
REMOTELOCATION="dev.gentoo.org:/home/perfinion/public_html/patches/selinux-base-policy";

usage() {
  echo "Usage: $0 <newversion>";
  echo "";
  echo "Example: $0 2.20140311-r5"
  echo "";
  echo "The script will copy the live ebuilds towards the";
  echo "<newversion>."
  echo "";
  echo "The following environment variables must be declared correctly for the script";
  echo "to function properly:";
  echo "  - GENTOOX86 should point to the gentoo-x86 checkout";
  echo "    E.g. export GENTOOX86=\"/home/user/dev/gentoo-x86/\"";
  echo "  - HARDENEDREFPOL should point to the hardened-refpolicy.git checkout";
  echo "    E.g. export HARDENEDREFPOL=\"/home/user/dev/hardened-refpolicy/\"";
  echo "  - REFPOLRELEASE should point to the current latest /release/ of the reference"
  echo "    policy (so NOT to a checkout), extracted somewhere on the file system."
  echo "    E.g. export REFPOLRELEASE=\"/home/user/local/refpolicy-20130424/\"";
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

# cleanTmp - Clean up TMPDIR
cleanTmp() {
  if [ -z "${NOCLEAN}" ];
  then
    echo "Not cleaning TMPDIR (${TMPDIR}) upon request.";
  else
    [ -d "${TMPDIR}" ] && [ -f "${TMPDIR}/.istempdir" ] && rm -rf "${TMPDIR}"
  fi
}

die() {
  printf "\n";
  echo "!!! $*";
  cleanTmp;
  exit 2;
};

# buildpatch - Create the patch set to be applied for the new release
buildpatch() {
  printf "Creating patch 0001-full-patch-against-stable-release.patch... ";
  diff -uNr -x ".git*" -x "CVS" -x "*.autogen*" -x "*.part" ${REFPOLRELEASE} ${HARDENEDREFPOL} | sed -e ${TRANSLATE} > ${TMPDIR}/0001-full-patch-against-stable-release.patch || die "Failed to create patch";
  printf "done\n"

  printf "Creating patch bundle for ${NEWVERSION}... ";
  cd ${TMPDIR};
  tar cvjf patchbundle-selinux-base-policy-${NEWVERSION}.tar.bz2 *.patch > /dev/null 2>&1 || die "Failed to create patchbundle";
  printf "done\n";

  . /etc/portage/make.conf;
  printf "Copying patch bundle into ${DISTDIR} location and dev.g.o... ";
  cp patchbundle-selinux-base-policy-${NEWVERSION}.tar.bz2 ${DISTDIR} || die "Failed to copy patchbundle to ${DISTDIR}";
  scp patchbundle-selinux-base-policy-${NEWVERSION}.tar.bz2 ${REMOTELOCATION} > /dev/null 2>&1 || die "Failed to scopy patchbundle to ${REMOTELOCATION}";
  printf "done\n";
}

# Create (or modify) the new ebuilds
createEbuilds() {
  cd ${GENTOOX86}/sec-policy;
  printf "Removing old patchbundle references in Manifest (in case of rebuild)... ";
  for PKG in *;
  do
    [[ -f "${PKG}/Manifest}" ]] || continue;
    sed -i -e "/patchbundle-selinux-base-policy-${NEWVERSION}/d" ${PKG}/Manifest;
  done
  printf "done\n";

  printf "Creating new ebuilds based on 9999 version... ";
  for PKG in *;
  do
    [[ -f "${PKG}/${PKG}-9999.ebuild" ]] || continue;
    cp ${PKG}/${PKG}-9999.ebuild ${PKG}/${PKG}-${NEWVERSION}.ebuild;
  done
  printf "done\n";
}

# Create and push tag for new release
tagRelease() {
  printf "Creating tag ${NEWVERSION} in our repository... ";
  cd ${HARDENEDREFPOL};
  git tag -a ${NEWVERSION} -m "Release set of ${NEWVERSION}" --sign > /dev/null 2>&1 || die "Failed to create tag";
  printf "done\n";
};

if [ $# -ne 1 ];
then
  usage;
  exit 3;
fi

# Assert that all needed information is available
assertDirEnvVar GENTOOX86;
assertDirEnvVar HARDENEDREFPOL;
assertDirEnvVar REFPOLRELEASE;

TMPDIR=$(mktemp -d);
touch ${TMPDIR}/.istempdir;

# Build the patch
buildpatch;
# Create ebuilds
createEbuilds;
# Tag release
tagRelease;

cat << EOF
The release has now been prepared.

Please go do the following to finish up:

In ${GENTOOX86}/sec-policy:
git add .
repoman --digest=y full

Then, before finally committing - do a run yourself, ensuring that the right
version is deployed of course:
- "emerge -1 \$(qlist -IC sec-policy)"

Only then do:
repoman commit -m 'sec-policy: Release of SELinux policies ${NEWVERSION}'
git push --sign

In ${HARDENEDREFPOL} do:
git push origin --tags
EOF

cleanTmp;
