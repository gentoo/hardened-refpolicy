#!/bin/bash
readarray -t -d '' UPSTREAM_MODULES < <(find "${REFPOLGIT}" -type f -iname '*.te' -print0)
readarray -t -d '' GENTOO_MODULES < <(find "${GENTOOX86}"/sec-policy -type d -print0)

declare -A module_map=()
declare -A excluded_map=(
	[example]=1
	# Not happening, way too RHEL-specific
	[setroubleshoot]=1
	[rhsmcertd]=1
)

# Don't warn on things in selinux-base{,-policy}
while read -r f; do
	excluded_map["${f}"]=1
done < <(grep '= base' "${HARDENEDREFPOL}"/policy/modules.conf | cut -d' ' -f1)

# Gather all policy modules we have declared in ebuild MODS
for gentoo_module in "${GENTOO_MODULES[@]}" ; do
	while IFS= read -r -d '' f; do
		mods=$(
			eval $(grep "^MODS=" ${f})
			echo "${MODS[@]}"
		)

		for mod in ${mods[@]} ; do
			[[ -n ${mod} ]] || continue

			module_map["${mod}"]=1
			#printf "found ${mod@Q}\n"
		done
	done < <(find "${gentoo_module}" -iname '*.ebuild' -type f -print0)
done

# Find the upstream modules not declared in any ebuild
for upstream_module in "${UPSTREAM_MODULES[@]}" ; do
	upstream_module="${upstream_module##*/}"
	upstream_module="${upstream_module%.te}"

	# We know some things are missing for MLS (bug #556652)
	[[ ${upstream_module} == *adm ]] && continue

	if ! [[ -v module_map["${upstream_module}"] ]] && ! [[ -v excluded_map["${upstream_module}"] ]]; then
		printf "upstream module ${upstream_module@Q} missing\n"
	fi
done
