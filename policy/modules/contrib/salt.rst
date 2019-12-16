============
salt_selinux
============

------------------------------
SELinux policy module for Salt
------------------------------

:Author:        Sven Vermeulen <swift@gentoo.org>
:Date:          2014-08-15
:Manual section:        8
:Manual group:          SELinux

DESCRIPTION
===========

The **salt** SELinux module supports the Salt configuration management (as
offered by Saltstack) tools and resources.

BOOLEANS
========

The following booleans are defined through the **salt** SELinux policy module.
They can be toggled using ``setsebool``, like so::

  setsebool -P salt_master_read_nfs on

salt_master_read_nfs
  Should be enabled if the Salt state files (SLS) are stored on an NFS mount

salt_minion_manage_nfs
  Should be enabled if the Salt minion needs manage privileges on NFS mounts

DOMAINS
=======

salt_master_t
-------------

The **salt_master_t** domain is used by the Salt master. It is usually launched
by the init script ``salt-master`` although it can also be launched through the
command line command **salt-master -d**.

This domain is responsible for servicing the Salt minions. Unlike the Salt
minion domain (**salt_minion_t**) the master domain is not very privileged as it
only provides access to the Salt state files.

salt_minion_t
-------------

The **salt_minion_t** domain is used by the Salt minion. It is usually launched
by the init script ``salt-minion`` although it can also be launched through the
command line command **salt-minion -d**.

This domain is responsible for enforcing the state as provided by the Salt
master on the system. This makes the **salt_minion_t** domain a *very
privileged* domain.

LOCATIONS
=========

FUNCTIONAL
----------

The following list of locations identify file resources that are used by the
Salt domains. They are by default allocated towards the default locations for
Salt, so if you use a different location, you will need to properly address
this. You can do so through ``semanage``, like so::

  semanage fcontext -a -t salt_sls_t "/var/lib/salt/state(/.*)?"

The above example marks the */var/lib/salt/state* location as the location where
the Salt state files (``*.sls``) are stored (identified through the
**salt_sls_t** type).

salt_sls_t
  is used for the Salt state files (*/srv/salt*)

salt_pki_t
  is used as the parent directory in which the master and minion keys are stored
  (*/etc/salt/pki*)

salt_master_pki_t
  is used for the private and public keys managed by the Salt master
  (*/etc/salt/pki/master*)

salt_minion_pki_t
  is used for the private and public keys managed by the Salt minion
  (*/etc/salt/pki/minion*)

EXEUTABLES
----------

salt_master_exec_t
  is used as entry point for the Salt master (**salt_master_t**)

salt_minion_exec_t
  is used as entry point for the Salt minion (**salt_minion_t**)

salt_master_initrc_exec_t
  is used for the init script to launch the salt master

salt_minion_initrc_exec_t
  is used for the init script to launch the salt minion

DAEMON FILES
------------

salt_cache_t
  is used for the parent directory for Salt caches (*/var/cache/salt*)

salt_master_cache_t
  is used to store the Salt master cache (*/var/cache/salt/master*)

salt_minion_cache_t
  is used to store the Salt minion cache (*/var/cache/salt/minion*)

salt_log_t
  is used for the parent directory for Salt log files (*/var/log/salt*)

salt_master_log_t
  is used for the Salt master log file (*/var/log/salt/master*)

salt_minion_log_t
  is used for the Salt minion log file (*/var/log/salt/minion*)

salt_runtime_t
  is used for the parent directory for Salt run-time files (*/var/run/salt*)

salt_master_runtime_t
  is used for the Salt master variable run-time files (*/var/run/salt/master*)

salt_minion_runtime_t
  is used for the Salt minion variable run-time files (*/var/run/salt/minion*)

CONFIGURATION FILES
-------------------

salt_etc_t
  is used for the Salt configuration (*/etc/salt*)

POLICY
======

The following interfaces can be used to enhance the default policy with
Salt-related provileges. More details on these interfaces can be found in the
interface HTML documentation, we will not list all available interfaces here.

Role interfaces
---------------

The following role interfaces allow users and roles access to the specified
domains. Only to be used for user domains and roles.

salt_admin_master
  is used for user domains to allow administration of a Salt master environment

salt_minion_master
  is used for user domains to allow administration of a Salt minion environment

SEE ALSO
========

* Gentoo and SELinux at https://wiki.gentoo.org/wiki/SELinux
* Gentoo Hardened SELinux Project at
  https://wiki.gentoo.org/wiki/Project:Hardened
