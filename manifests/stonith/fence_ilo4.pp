# generated by agent_generator.rb, manual changes will be lost

define pacemaker::stonith::fence_ilo4 (
  $auth = undef,
  $ipaddr = undef,
  $passwd = undef,
  $passwd_script = undef,
  $lanplus = undef,
  $login = undef,
  $timeout = undef,
  $cipher = undef,
  $method = undef,
  $power_wait = undef,
  $delay = undef,
  $privlvl = undef,
  $verbose = undef,

  $interval = "60s",
  $ensure = present,
  $pcmk_host_list = undef,

  $tries = undef,
  $try_sleep = undef,
) {
  $auth_chunk = $auth ? {
    undef => "",
    default => "auth=\"${auth}\"",
  }
  $ipaddr_chunk = $ipaddr ? {
    undef => "",
    default => "ipaddr=\"${ipaddr}\"",
  }
  $passwd_chunk = $passwd ? {
    undef => "",
    default => "passwd=\"${passwd}\"",
  }
  $passwd_script_chunk = $passwd_script ? {
    undef => "",
    default => "passwd_script=\"${passwd_script}\"",
  }
  $lanplus_chunk = $lanplus ? {
    undef => "",
    default => "lanplus=\"${lanplus}\"",
  }
  $login_chunk = $login ? {
    undef => "",
    default => "login=\"${login}\"",
  }
  $timeout_chunk = $timeout ? {
    undef => "",
    default => "timeout=\"${timeout}\"",
  }
  $cipher_chunk = $cipher ? {
    undef => "",
    default => "cipher=\"${cipher}\"",
  }
  $method_chunk = $method ? {
    undef => "",
    default => "method=\"${method}\"",
  }
  $power_wait_chunk = $power_wait ? {
    undef => "",
    default => "power_wait=\"${power_wait}\"",
  }
  $delay_chunk = $delay ? {
    undef => "",
    default => "delay=\"${delay}\"",
  }
  $privlvl_chunk = $privlvl ? {
    undef => "",
    default => "privlvl=\"${privlvl}\"",
  }
  $verbose_chunk = $verbose ? {
    undef => "",
    default => "verbose=\"${verbose}\"",
  }

  $pcmk_host_value_chunk = $pcmk_host_list ? {
    undef => '$(/usr/sbin/crm_node -n)',
    default => "${pcmk_host_list}",
  }

  # $title can be a mac address, remove the colons for pcmk resource name
  $safe_title = regsubst($title, ':', '', 'G')

  if($ensure == absent) {
    exec { "Delete stonith-fence_ilo4-${safe_title}":
      command => "/usr/sbin/pcs stonith delete stonith-fence_ilo4-${safe_title}",
      onlyif => "/usr/sbin/pcs stonith show stonith-fence_ilo4-${safe_title} > /dev/null 2>&1",
      require => Class["pacemaker::corosync"],
    }
  } else {
    package {
      "fence-agents-ipmilan": ensure => installed,
    } ->
    exec { "Create stonith-fence_ilo4-${safe_title}":
      command => "/usr/sbin/pcs stonith create stonith-fence_ilo4-${safe_title} fence_ilo4 pcmk_host_list=\"${pcmk_host_value_chunk}\" ${auth_chunk} ${ipaddr_chunk} ${passwd_chunk} ${passwd_script_chunk} ${lanplus_chunk} ${login_chunk} ${timeout_chunk} ${cipher_chunk} ${method_chunk} ${power_wait_chunk} ${delay_chunk} ${privlvl_chunk} ${verbose_chunk}  op monitor interval=${interval}",
      unless => "/usr/sbin/pcs stonith show stonith-fence_ilo4-${safe_title} > /dev/null 2>&1",
      tries => $tries,
      try_sleep => $try_sleep,
      require => Class["pacemaker::corosync"],
    } ->
    exec { "Add non-local constraint for stonith-fence_ilo4-${safe_title}":
      command => "/usr/sbin/pcs constraint location stonith-fence_ilo4-${safe_title} avoids ${pcmk_host_value_chunk}",
      tries => $tries,
      try_sleep => $try_sleep,
    }
  }
}
