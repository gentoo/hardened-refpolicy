=============
munin_selinux
=============

-------------------------------
SELinux policy module for Munin
-------------------------------

:Author:        Sven Vermeulen <swift@gentoo.org>
:Date:          2014-11-11
:Manual section:        8
:Manual group:          SELinux

DESCRIPTION
===========

The *munin* SELinux module supports the Munin networked resource management
tool. 

DOMAINS
=======

The following is a list of munin related domains.

munin_t
  is the main domain for the munin daemon

'*'_munin_plugin_t
  is a set of domains related to the munin plugins

LOCATIONS
=========

The following list of locations identify file resources that are used by the
munin domains. They are by default allocated towards the default locations for
munin, so if you use a different location, you will need to properly address
this. You can do so through ``semanage``, like so::

  semanage fcontext -a -t system_cron_spool_t "/usr/local/share/munin/plugins(/.*)?"

The above example marks the */usr/local/share/munin/plugins* location as the location where
munin plugin executables are stored.

FUNCTIONAL
----------

munin_etc_t
  is used for the munin configuration files

EXECUTABLES
-----------

munin_exec_t
  is used for the munin binaries

munin_initrc_exec_t
  is used for the munin init script

'*'_munin_plugin_exec_t
  is used for the munin plugin executables

DAEMON FILES
------------

munin_log_t
  is used for the munin logs

munin_plugin_state_t
  is used for the munin plugin state information

munin_var_lib_t
  is used for the variable information used by munin

munin_runtime_t
  is used for the variable runtime state information of munin

POLICY
======

The following interfaces can be used to enhance the default policy with
munin-related provileges. More details on these interfaces can be found in the
interface HTML documentation, we will not list all available interfaces here.

Plugin template
---------------

With the ``munin_plugin_template`` interface, additional munin plugin domains
can be created. The interface takes a single prefix (like "disk") and will create
the proper types and privileges, including (using "disk" as the example):

* *disk_munin_plugin_t* as plugin domain
* *disk_munin_plugin_exec_t* as plugin executable type
* *disk_munin_plugin_tmp_t* as plugin temporary file type

To enable it::

  munin_plugin_template(disk)

Administrative role
-------------------

The ``munin_admin`` interface grants a user role and type administrative access
to the munin types::

  munin_admin(myuser_t, myuser_r)

BUGS
====

Munin
-----

The ``net-analyzer/munin`` package deploys the munin cronjobs as end user
cronjobs inside ``/var/spool/cron/crontabs``. The munin cronjobs are meant to
be executed as the munin Linux account, but the jobs themselves are best seen
as system cronjobs (as they are not related to a true interactive end user).

The default deployed files might not get the *system_u* SELinux ownership
assigned. To fix this, execute the following command::

  ~# chcon -u system_u /var/spool/cron/crontabs/munin

For more information, see bug #526532.

SEE ALSO
========

* Gentoo and SELinux at https://wiki.gentoo.org/wiki/SELinux
* Gentoo Hardened SELinux Project at
  https://wiki.gentoo.org/wiki/Project:Hardened
