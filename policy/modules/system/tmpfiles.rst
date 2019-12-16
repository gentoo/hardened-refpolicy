================
tmpfiles_selinux
================

----------------------------------
SELinux policy module for tmpfiles
----------------------------------

:Author:        Sven Vermeulen <swift@gentoo.org>
:Date:          2014-08-15
:Manual section:        8
:Manual group:          SELinux

DESCRIPTION
===========

The **tmpfiles** SELinux module supports the use of the tmpfiles interface (for
generating and managing temporary files, directories, sockets and what not) as
documented through the *tmpfiles.d* manual page, available at
http://www.freedesktop.org/software/systemd/man/tmpfiles.d.html

BOOLEANS
========

The following booleans are defined through the **tmpfiles** SELinux policy module.
They can be toggled using ``setsebool``, like so::

  setsebool -P tmpfiles_manage_all_non_security

tmpfiles_manage_all_non_security
  Enable to allow tmpfiles to manage non-default types (beyond variable run-time
  locations) as well

DOMAINS
=======

tmpfiles_t
----------

The **tmpfiles_t** domain is used by the *tmpfiles* and *checkpath* scripts
which are responsible for creating and modifying the boot-time resources.

LOCATIONS
=========

tmpfiles_conf_t
  is used for the tmpfiles configuration files (*/etc/tmpfiles.d*)

tmpfiles_exec_t
  is used as entrypoint for the tmpfiles application

tmpfiles_runtime_t
  is used as the variable run-time data used by the tmpfiles application

POLICY
======

The following interfaces can be used to enhance the default policy with
tmpfiles-related provileges. More details on these interfaces can be found in the
interface HTML documentation, we will not list all available interfaces here.

tmpfiles_read_conf
  to allow read access on the tmpfiles configuration files

tmpfiles_manage_conf
  to allow a domain to manage the tmpfiles configuration files

SEE ALSO
========

* Gentoo and SELinux at https://wiki.gentoo.org/wiki/SELinux
* Gentoo Hardened SELinux Project at
  https://wiki.gentoo.org/wiki/Project:Hardened
