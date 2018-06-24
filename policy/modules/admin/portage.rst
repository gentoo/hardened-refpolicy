=================
 portage_selinux
=================

----------------------------------------
SELinux policy module for Gentoo Portage
----------------------------------------

:Author:        Sven Vermeulen <swift@gentoo.org>
:Date:          2013-04-11
:Manual section:        8
:Manual group:          SELinux

DESCRIPTION
===========

The **portage** SELinux module supports the various SELinux domains and types
related to Gentoo Portage. This includes the main **portage_t** domain and the
functionality-related **portage_sandbox_t** and **portage_fetch_t** domains.
Another provided domain is **gcc_config_t** for the ``gcc-config`` helper script.

BOOLEANS
========

The following booleans are defined through the **portage** SELinux policy
module. They can be toggled using ``setsebool``, like so::

  setsebool -P portage_use_nfs on

portage_use_nfs
  Determine whether portage can use nfs file systems

DOMAINS
=======

portage_t
---------

The **portage_t** domain is used for the majority of Portage related applications.
Applications that, when executed, will run in this domain are ``emerge``,
``ebuild``, ``quickpkg``, ``regenworld``, ``sandbox`` and ``glsa-check``.

This domain is able to trigger builds (for which it transitions to
**portage_sandbox_t**) and holds the rights to merge the eventually built
software onto the main system. As such, it should be regarded as a highly
privileged domain.

By default, only the **sysadm_r** role is allowed to transition to the
**portage_t** domain as this domain is used for system administrative
purposes.

portage_fetch_t
---------------

The **portage_fetch_t** domain is used to manage and update the Portage tree.

Permission-wise, it is allowed to transition to the **portage_t** domain when
it, for instance, needs to update metadata. 

The domain is affected by the following booleans:

* **portage_use_nfs** allows the **portage_fetch_t** domain to manage NFS-hosted
  files, such as an NFS-hosted Portage tree.

portage_sandbox_t
-----------------

The **portage_sandbox_t** domain is used when building software. It has a wide
range of read rights as it has to be flexible enough to support all possible
software builds. This includes networking support (for instance when using
``distcc``). 

This domain is only transitioned towards by the **portage_t** domain and is not
directly accessible. Also, this domain is not allowed to transition towards any
other domain.

The domain is affected by the following booleans:

* **portage_use_nfs** allows the **portage_sandbox_t** domain to manage
  NFS-hosted files.
  
  If you have the repository on an NFS share, or any of the Portage related
  locations (such as the temporary build dir) on NFS, then you will need to
  enable this boolean.

gcc_config_t
------------

The **gcc_config_t** domain is used by the ``gcc-config`` helper script which
allows users to switch between installed compilers and compiler specifications.

By default, only the **sysadm_r** role is allowed to transition to the
**gcc_config_t** domain as this domain is used for system administrative
purposes.

The domain is affected by the following booleans:

* **portage_use_nfs** allows the **gcc_config_t** domain to read NFS hosted
  files. This was made necessary as the ``gcc-config`` application underlyingly
  uses Portage code, which reads information from the repository and configuration
  locations. 

  This boolean only needs to be set if you have the Portage tree hosted on an
  NFS share.

LOCATIONS
=========

USER-ORIENTED
-------------

The following list of locations identify file resources that are used by the
Portage domains. They are by default allocated towards the default locations for
Portage, so if you use a different location, you will need to properly address
this. You can do so through ``semanage``, like so::

  semanage fcontext -a -t portage_ebuild_t "/var/portage/tree(/.*)?"

The above example marks the */var/portage/tree* location as the location where
the Portage tree is stored (identified through the **portage_ebuild_t** type).

portage_conf_t
  is used for the Portage configuration files, and defaults to
  */etc/portage*. It is also used for files or links such as
  */etc/make.profile*.

portage_ebuild_t
  is used for the Portage tree, and defaults to */usr/portage*
  This also includes the downloaded source code archives.

portage_log_t
  is used for the Portage logging. It is used for files such as
  */var/log/emerge.log*, */var/log/emerge-fetch.log* and the */var/log/portage/*
  directory.

portage_srcrepo_t
  is used for the live ebuild source code repositories,
  and is used by locations such as */usr/portage/distfiles/cvs-src*.

portage_tmp_t
  is used for the Portage domain temporary files and the build location. It
  is by default assigned to locations such as */var/tmp/portage*.

INTERNAL
--------

portage_cache_t
  is used to identify the Portage cache (*/var/lib/portage*)

portage_db_t
  is used for the Portage database files (*/var/db/pkg*)

OTHER RESOURCES
===============

EXECUTABLE FILES
----------------

portage_exec_t
  is used as entry point for the various Portage applications that generally run
  in the **portage_t** domain

portage_fetch_exec_t
  is used as the entry point for the fetch-related applications, which generally
  run in the **portage_fetch_t** domain

gcc_config_exec_t
  is used as the entry point for the ``gcc-config`` application.

POLICY
======

The following interfaces can be used to enhance the default policy with
Portage-related privileges. More details on these interfaces can be found in the
interface HTML documentation, we will not list all available interfaces here.

Run interfaces
--------------

The following run interfaces allow users and roles access to the specified
domains. Only to be used for new user domains and roles.

portage_run
  Allow the specified user domain and role access and transition rights
  to the **portage_t** domain.

portage_run_fetch
  Allow the specified user domain and role access and transition rights
  to the **portage_fetch_t** domain.

portage_run_gcc_config
  Allow the specified user domain and role access and transition rights
  to the **gcc_config_t** domain.

Domtrans interfaces
-------------------

The following domain transition interfaces allow domains to execute and
transition into the mentioned Portage domains. Only to be used for domains
assumed to be running within the general **system_r** role, or within a role
already allowed access to the Portage domains (such as **sysadm_r**).

portage_domtrans
  Allow the specified domain access and transition rights to the
  **portage_t** domain.

portage_domtrans_fetch
  Allow the specified domain access and transition rights to the
  **portage_fetch_t** domain.

portage_domtrans_gcc_config
  Allow the specified domain access and transition rights to the
  **gcc_config_t** domain.

Resource access
---------------

The following interfaces allow a specified domain access to the Portage
resources. These can be assigned on user domains as well.

portage_read_config
  Allow the specified domain read access on the Portage configuration files

portage_read_ebuild
  Allow the specified domain read access on the Portage tree.

  For instance, if you want to allow the **httpd_t** domain (used by web server
  domains) read access::

    portage_read_ebuild( httpd_t )

SEE ALSO
========

* Gentoo and SELinux at 
  https://wiki.gentoo.org/wiki/SELinux
* Gentoo Hardened SELinux Project at
  https://wiki.gentoo.org/wiki/Project:Hardened
