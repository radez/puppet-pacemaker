# == Class: pacemaker::corosync
#
# A class to setup a pacemaker cluster
#
# === Parameters
# [*cluster_name*]
#   The name of the cluster (no whitespace)
# [*cluster_members*]
#   A space-separted list of cluster IP's or names
# [*setup_cluster*]
#   If your cluster includes pcsd, this should be set to true for just
#    one node in cluster.  Else set to true for all nodes.
# [*manage_fw*]
#   Manage or not IPtables rules.
# [*settle_timeout*]
#   Timeout to wait for settle.
# [*settle_tries*]
#   Number of tries for settle.
# [*settle_try_sleep*]
#   Time to sleep after each seetle try.

class pacemaker::corosync(
  $cluster_members,
  $cluster_name     = 'clustername',
  $hacluster_pwd    = $pacemaker::params::hacluster_pwd,
  $setup_cluster    = true,
  $manage_fw        = true,
  $settle_timeout   = '3600',
  $settle_tries     = '360',
  $settle_try_sleep = '10',
  $pcs_token        = '1000',
  $pcs_join         = '50',
  $pcs_consensus    = '1200',
  $pcs_miss_count   = '5',
  $pcs_fail_recv    = '2500',
) inherits pacemaker {

  if $manage_fw {
    firewall { '001 corosync mcast':
      proto  => 'udp',
      dport  => ['5404', '5405'],
      action => 'accept',
    }
  }

  if $pcsd_mode {
    if $manage_fw {
      firewall { '001 pcsd':
        proto  => 'tcp',
        dport  => ['2224'],
        action => 'accept',
      }
    }
    Service['pcsd'] ->
    # we have more fragile when-to-start pacemaker conditions with pcsd
    exec {"enable-not-start-${cluster_name}":
      command => '/usr/sbin/pcs cluster enable',
      unless  => $::pacemaker::enabled_check_cmd,
    }
    ->
    exec {"Set password for hacluster user on ${cluster_name}":
      command => "/bin/echo ${::pacemaker::hacluster_pwd} | /usr/bin/passwd --stdin hacluster",
      creates => $::pacemaker::config_file,
      require => Class['::pacemaker::install'],
    }
    ->
    exec {'auth-successful-across-all-nodes':
      command   => "/usr/sbin/pcs cluster auth ${cluster_members} -u hacluster -p ${::pacemaker::hacluster_pwd} --force",
      timeout   => $settle_timeout,
      tries     => $settle_tries,
      try_sleep => $settle_try_sleep,
    }
    ->
    Exec['wait-for-settle']
  }

  if $setup_cluster {
    exec {"Create Cluster ${cluster_name}":
      creates => $::pacemaker::config_file,
      command => "/usr/sbin/pcs cluster setup --name ${cluster_name} ${cluster_members} --token=${pcs_token} --join=${pcs_join} --miss_count_const=${pcs_miss_count} --consensus=${pcs_consensus} --fail_recv_const=${pcs_fail_recv}",
      unless  => '/usr/bin/test -f /etc/corosync/corosync.conf',
      require => Class['::pacemaker::install'],
    }
    ->
    exec {"Start Cluster ${cluster_name}":
      unless  => '/usr/sbin/pcs status >/dev/null 2>&1',
      command => '/usr/sbin/pcs cluster start --all',
      require => Exec["Create Cluster ${cluster_name}"],
    }
    if $pcsd_mode {
      Exec['auth-successful-across-all-nodes'] ->
        Exec["Create Cluster ${cluster_name}"]
    }
    Exec["Start Cluster ${cluster_name}"] ->
      Exec['wait-for-settle']
  }

  exec { 'wait-for-settle':
    timeout   => $settle_timeout,
    tries     => $settle_tries,
    try_sleep => $settle_try_sleep,
    command   => "/usr/sbin/pcs status | grep -q 'partition with quorum' > /dev/null 2>&1",
    unless    => "/usr/sbin/pcs status | grep -q 'partition with quorum' > /dev/null 2>&1",
    notify    => Notify['pacemaker settled'],
  }

  notify {'pacemaker settled':
    message => 'Pacemaker has reported quorum achieved',
  }
}
