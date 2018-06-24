=================
 aide_selinux
=================

------------------------------
SELinux policy module for AIDE
------------------------------

:Author:        Sven Vermeulen <swift@gentoo.org>
:Date:          2013-04-11
:Manual section:        8
:Manual group:          SELinux

DESCRIPTION
===========

The **aide** SELinux module supports the AIDE application (Advanced Intrusion
Detection Environment) and resources.

DOMAINS
=======

aide_t
------

The **aide_t** domain is used for the application runtime context. When the
``aide`` command is invoked, it should run within this domain. 

The use of this domain is restricted to the roles responsible for the security
administration of the system, so **sysadm_r** and **secadm_r**. It is strongly
discouraged to allow the use of AIDE for other roles.

Due to its sensitive nature, when the MLS policy is enabled, AIDE runs in the
**mls_systemhigh** sensitivity.

LOCATIONS
=========

USER-ORIENTED
-------------

The following list of locations identify file resources that are used by the
AIDE domain. They are by default allocated towards the default locations for
AIDE, so if you use a different location, you will need to properly address
this. You can do so through ``semanage``, like so::

  semanage fcontext -a -t aide_db_t "/mnt/db/aide(/.*)?"

The above example marks the */mnt/db/aide* location as the location where
the AIDE databases are stored (identified through the **aide_db_t** type).

aide_db_t
  is used for the AIDE database location

aide_log_t
  is used for the AIDE logs

OTHER RESOURCES
===============

EXECUTABLE FILES
----------------

aide_exec_t
  is used as entry point for the AIDE application that runs in the **aide_t**
  domain

POLICY
======

The following interfaces can be used to enhance the default policy with
AIDE-related privileges. More details on these interfaces can be found in the
interface HTML documentation, we will not list all available interfaces here.

Run interfaces
--------------

The following run interfaces allow users and roles access to the specified
domains. Only to be used for new user domains and roles.

aide_run
  Allow the specified user domain and role access and transition rights to the
  **aide_t** domain.

aide_admin
  Allow the specified user domain and role access and transition rights to the
  **aide_t** domain, and allow administration of the AIDE related resources.

Domtrans interfaces
-------------------

The following domain transition interfaces allow domains to execute and
transition into the mentioned AIDE domain. Only to be used for domains
assumed to be running within the general **system_r** role, or within a role
already allowed access to the AIDE domain (such as **sysadm_r**).

aide_domtrans
  Allow the specified domain access and transition rights to the **aide_t**
  domain.

SEE ALSO
========

* Gentoo and SELinux at 
  https://wiki.gentoo.org/wiki/SELinux
* Gentoo Hardened SELinux Project at 
  https://wiki.gentoo.org/wiki/Project:Hardened
