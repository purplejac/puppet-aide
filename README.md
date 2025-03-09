# puppet-aide (AIDE - Advanced Intrusion Detection Enviroment).
[![Build Status](https://travis-ci.com/indiana-university/puppet-aide.svg?branch=master)](https://travis-ci.com/indiana-university/puppet-aide) [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity) [![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)


#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with aide](#setup)
      * [Setup requirements](#setup-requirements)
3. [Examples](#examples)
4. [Cron Entry](#cron)
5. [Reference - What the module is doing and how](#reference)
6. [Assigning parameters using Hiera](#hiera)
7. [Limitations](#limitations)
8. [Contributing to the development of this module](#contributing)
9. [Credits](#Credits)

## Description

This is a maintained fork of https://github.com/indiana-university/puppet-aide.

This is a module for managing the installation, configuration and initial database creation of [AIDE](https://aide.github.io/) (Advanced Intrustion Detection Environment)package.

AIDE creates a database of files and their attributes from the rules that it finds in its configuration file. Once this database is initialized, it can be used to verify the integrity of the files contained within it. If the file attributes change according to the rules supplied, a summary of changes is logged and can be acted upon.

Refer to the [AIDE manual](https://aide.github.io) for further details about configuration options.

This module will also add a cron job to periodically run the `aide --check` command to verify the integrity of the AIDE database. Results will be logged to the log file (defaults to `/var/log/aide/aide.log`) and to the AUTH log facility.

### Setup Requirements

This module requires some additional modules, but it is highly likely that they
are already installed on your puppet server. They are as follows:

* `puppetlabs/concat` `9.0 - 10.0`
* `puppetlabs/stdlib` `9.0 - 10.0`
* `puppet/cron` `1.0 - 5.0`

## Examples

Include the aide class and set cron run time to 6am with mail to a user other than root.
----------
    class { 'aide':
      minute => 0,
      hour   => 6,
      day    => 3,
    }

Include the aide class and exclude the ''--config /etc/aide.conf'' argument. 
----------

This is useful if you are using a 3rd-party security/scanning tool that fails to verify you're running AIDE via a CRON job due to a bad regex on the vendor side.

    class { 'aide':
      minute                 => 0,
      hour                   => 17,
      day                    => 22,
      exclude_config_argment => true, 
    }

This results in the cron job:

    0 17 22 * *  root  nice ionice -c3 /usr/sbin/aide --check

instead of:

    0 17 22 * *  root  nice ionice -c3 /usr/sbin/aide --config /etc/aide.conf --check

Watch permissions of all files on filesystem
----------

The simplest use of `iu/aide` is to place a watch on the root directory, as follows.

    aide::watch { 'example':
      path  => '/',
      rules => 'p'
    }

This example adds the line `/ P` which watches the permissions of all files on the operating system. Obviously, this is a simplistic non useful solution.

Note that the path parameter is optional with the default being the watch name, e.g.

    aide::watch { '/etc':
      rules => 'p'
    }

Watch permissions and md5sums of all files in /etc
----------

    aide::watch { 'watch etc':
      path  => '/etc',
      rules => 'p+md5'
    }

This example adds the line `/etc p+md5` which watches `/etc` with both permissions and md5sums.  This could also be implemented as follows.

    aide::watch { '/etc':
      rules => ['p', 'md5']
    }

Create a common rule for watching multiple directories
-----------

Sometimes you wish to use the same rule to watch multiple directories and in keeping up with the Don't Repeat Yourself(DRY) viewpoint, we should create a common name for the rule.  This can be done via the `aide::rule` stanza.

    aide::rule { 'MyRule':
      name  => 'MyRule',
      rules => ['p', 'md5']
    }
    aide::watch { '/etc':
      rules => 'MyRule'
    }
    aide::watch { 'otherApp':
      path  => '/path/to/other/config/dir',
      rules => 'MyRule'
    }

Here we are defining a rule called **MyRule** which will add the line `MyRule = p+md5`.  The next two stanzas can reference that rule.  They will show up as `/etc MyRule` and `/path/to/other/config/dir MyRule`.

Create a rule to exclude directories
-----------

    aide::watch { 'Exclude /var/log':
      path => '/var/log',
      type => 'exclude'
    }

This with ignore all files under /var/log. It adds the line `!/var/log` to the config file.

Create a rule to watch only specific files
-----------

    aide::watch { '/var/log/messages':
      type => 'equals',
      rules => 'MyRule'
    }

This will watch only the file /var/log/messages.  It will ignore /var/log/messages/thingie. It adds the line `=/var/log/messages MyRule` to the config file.

## Cron

A cron job is created during installation to run aide checks that use the `minute`, `hour`, `day`, `month` and `weekday` parameters to specify the run time.

This cron job can be disabled by setting the `aide::nocheck` parameter.

## Reference

The following parameters are accepted by the `::aide` class:

### Installation  Options

#### `package`

Data type: String.

AIDE package name.

Default value: `aide`.

#### `version`

Data type: String.

AIDE version for installation passed to Package::ensure

Default value: `latest`.

### Configuration  Options

#### `conf_path`

Data type: String.

Location of AIDE configuration file

Default value: `/etc/aide.conf`.

#### `db_path`

Data type: String.

Location of AIDE database file

Default value: `/var/lib/aide/aide.db`.

#### `db_temp_path`

Data type: String.

Location of update AIDE database file

Default value: `/var/lib/aide/aide.db.new`.

#### `gzip_dbout`

Data type: Boolean.

Gzip the AIDE database file (may affect performance)

Default value: `false`.

#### `aide_path`

Data type: String.

Location of aide binary.

Default value: `/usr/sbin/aide`.

### `mail_path`

Data type: String.

Location of mail binary.

Default value: `/usr/bin/mail`.
#### `config_template`

Data type: String.

Template to use for aide configuration.

Default value: `aide/aide.conf.erb`.
#### `report_ignore_e2fsattrs`

Data type: String

List (no delimiter) of ext2 file attributes which are to be ignored in the final report.

Default value: `undef`

### Logging Options

#### `aide_log`

Data type: String.

AIDE check output log.

Default value: `/var/log/aide/aide.log`.

#### `syslogout`

Data type: Boolean.

Enables logging to the system logging service AUTH facility and `/var/log/messages`.

Default value: `true`.

### Cron scheduling Options

#### `minute`

Data type: Cron::Minute (Integer)

Minute of cron job to run

Default value: `0`.

#### `hour`

Data type: Cron::Hour (Integer).

Hour of cron job to run

Default value: `0`.

#### `date`

Data type: Cron::Date (Integer).

Date of cron job to run

Default value: `*`.

#### `month`

Data type: Cron::Month (Integer).

Month of cron job to run

Default value: `*`.

#### `weekday`

Data type: Cron::Weekday (Integer).

Day of week of cron job to run

Default value: `*`.

#### `nocheck`

Data type: Boolean.

Whether to enable or disable scheduled checks

Default value: `true`.

#### `mailto`

Data type: String

Set this vaule to send email of results from aide --check in cron.

Default value: `undef`

#### `mail_only_on_changes`

Data type: Boolean

Whether to only send emails when changes are detected.

Default value: `false`

#### `max_mail_lines`

Data type: Optional[Integer[1]]

If set to a positive integer, mail messages are truncated to the given number of lines. This can be used to prevent too large mail bodies for large changesets (which may be triggered by OS updates, and not be accepted by the mail server).

Default value: `undef`

#### `init_timeout`

Data type: Integer.

Timeout of "aide --init" run.

Default value: `300`.

### `cat_path`

Data type: String.

The cat command path. This is based on the system

Default value: `/usr/bin/cat`

### `rm_path`

Data type: String.

The rm command path. This is based on the system

Default value: `/usr/bin/rm`

### `head_path`

Data type: String.

The head command path. This is based on the system

Default value: `/usr/bin/head`


## Hiera

Values can be set using hiera, for example:

```
aide::syslogout: false
aide::hour: 1
```

### Tasks
The aide module has a task that allows a user to manually initialize aide and copy the database. This is paticular useful when multiple changes are detected on more than one server. The commands the task executes are below and has been tested on Ubuntu.
```
aideinit
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

## Limitations

This module currently supports RedHat, CentOS, Debian and Ubuntu Linux but it has been fully tested on Ubuntu 18.04 and Ubuntu 20.04.

## Contributing

Pull requests for new functionality or bug fixes are welcome but all code must meet the following requirements:
  * Is fully tested
  * All tests must pass
  * Follows the [Puppet language style guide](https://puppet.com/docs/puppet/latest/style_guide.html)


## Credits

This module was adopted based on the initial refacter work of [Warren Powell](https://github.com/warrenpnz) and [Matt Lauber](https://github.com/mklauber) which uses parameter based classes rather than includes and also includes additional features for:
  * enabling gzip for database
  * allow for overrides of aide.conf and cron.d templates
  * aide logging options
