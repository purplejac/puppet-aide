# Copyright © 2022 The Trustees of Indiana University
# SPDX-License-Identifier: BSD-3-Clause
#
#@summary This class manages the aide's cron job. For all params reference README.
#
#@param aide_path
#@param cat_path
#@param rm_path
#@param mail_path
#@param conf_path
#@param minute
#@param hour
#@param date
#@param month
#@param weekday
#@param nocheck
#@param mailto
#@param mail_only_on_changes
#@param exclude_config_argment
# Default: False
# Exclude the '--config ${conf_path}' argument from the CRON job.  This is helpful if you have
# 3rd party hardening scripts that are causing false negatives for AIDE runs.
#
# @example
#   include aide::cron
class aide::cron (
  String $aide_path,
  String $cat_path,
  String $rm_path,
  String $mail_path,
  String $conf_path,
  Cron::Minute $minute,
  Cron::Hour $hour,
  Cron::Date $date,
  Cron::Month $month,
  Cron::Weekday $weekday,
  Boolean $nocheck,
  Optional[String] $mailto,
  Boolean $mail_only_on_changes,
  Boolean $exclude_config_argument = false,
) {
  # Throttle I/O with nice and ionice
  $io = 'nice ionice -c3'

  if $nocheck == true {
    $cron_ensure = 'absent'
  } else {
    $cron_ensure = 'present'
  }

  $config_command = $exclude_config_argument ? {
    false => "--config ${conf_path} ",    # Trailing space is important.
    true  => undef,
  }

  if $mailto != undef {
    $settings = "${aide_path} ${config_command}--check"
    $email_subject = "\"\$(hostname) - AIDE Integrity Check\" ${mailto}"

    if $mail_only_on_changes {
      $cron_command = "AIDE_OUT=$(${io} ${settings} 2>&1) || echo \"\${AIDE_OUT}\" | ${cat_path} -v | ${mail_path} -E -s ${email_subject}"
    } else {
      $cron_command = "${io} ${settings} | ${cat_path} -v | ${mail_path} -s ${email_subject}"
    }
  } else {
    $cron_command = "${io} ${aide_path} ${config_command}--check"
  }


  # Create the AIDE cron job.
  cron::job { 'aide':
    ensure  => $cron_ensure,
    command => $cron_command ,
    user    => 'root',
    hour    => $hour,
    minute  => $minute,
    date    => $date,
    month   => $month,
    weekday => $weekday,
  }
}
