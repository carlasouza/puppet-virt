# A wrapper for Carla's virt module used to manage a OpenVZ VE
#
# Required modules:
# - lvm (patched): https://github.com/windowsrefund/puppet-lvm
# - iptables: http://bob.sh/puppet-iptables
#
# Performs the following when ensure => present:
#
# - Create and format the LV
# - Mount the LV
# - Create the VE
# - Puppetize the VE if desired
#
# When ensure => absent:
#
# - Stop the VE
# - Umount the LV
#
# * We do not delete data*
#
# Parameters:
#
# ensure: Whether the resources exist or not
#   values: present, absent
#
# puppetize: If set to true, vzctl will run the puppet agent inside
# the VE. The following assumptions are made here:
#
# The remaining parameters should be self-explanitory
#
# Assumptions:
#
# 1. The OS template used to create the VE is equipped with a
# legitimate puppet agent.
#
# 2. A manifest exists on the Puppet Master for the newly created VE.
#
# 3. The newly created VE can reach the Puppet Master. In most cases,
# proper NAT/Forwarding will achieve this goal. Because the NAT rule
# is a singleton, it's best to manage the resource in the same scope
# where this definition is used. See the "Example" section for more
# info.
#
# Example:
#
# See http://bob.sh/puppet-iptables for more info on the iptables type
#
# iptables {
# nat-ves:
#   proto => 'all',
#   table => 'nat',
#   chain => 'POSTROUTING',
#   source => "${network_eth0}/${netmask_eth0}",
#   outiface => 'eth0',
#   jump => 'MASQUERADE';
#    forward-ves-out:
#        proto => 'all',
#        chain => 'FORWARD',
#        iniface => 'venet0',
#        outiface => 'eth0',
#        jump => 'ACCEPT';
#    forward-ves-in:
#        proto => 'all',
#        chain => 'FORWARD',
#        state => [ 'RELATED', 'ESTABLISHED' ],
#        iniface => 'eth0',
#        outiface => 'venet0',
#        jump => 'ACCEPT';
# }
#
# virt::ve { helloworld:
#    os_template => "debian-6.0-${architecture}-reliant",
#    ipaddr => '10.250.250.81',
#    nameserver => '10.250.250.5',
#    require => Iptables[nat-ves, forward-ves-out, forward-ves-in],
# }
#
define virt::ve (
  $ensure = 'present',
  $puppetize = true,
  $os_template = undef,
  $tmpl_repo = undef,
  $ipaddr = undef,
  $nameserver = undef,
  $searchdomain = undef,
  $configfile = 'basic',
  $virt_type = 'openvz',
  $lvm_vg = 'vg0',
  $lvm_pv = '/dev/sda3',
  $lvm_fstype = 'ext4',
  $lvm_size = '1G',
  $memory = 256,
  $vedir_override = ''
) {

  if $os_template == undef {
      fail("The os_template parameter must be defined.")
  }

  include virt
  include virt::params

  if ($vedir_override != '') {
    $vedir = $vedir_override
  } else {
    $vedir = $virt::params::vedir
  }

  virt { $name:
    ensure => $ensure ? {
        absent => 'stopped',
        default => 'running',
    },
    virt_type => $virt_type,
    os_template => $os_template,
    tmpl_repo => $tmpl_repo,
    configfile => $configfile,
    ipaddr => $ipaddr,
    ve_root => "${vedir}/${name}/root",
    ve_private => "${vedir}/${name}/private",
    nameserver => $nameserver,
    searchdomain => $searchdomain,
    memory => $memory,
    require => $ensure ? {
      present => Mount["${vedir}/$name"],
      default => undef,
    },
  }

  # mount when the VE is present. Otherwise, unmount it
  mount { "${vedir}/$name":
    ensure => $ensure ? {
      absent => unmounted,
      default => mounted,
    },
    fstype => $lvm_fstype,
    options => 'rw,noatime',
    device => "/dev/mapper/${lvm_vg}-$name",
    require => $ensure ? {
      absent => Virt[$name],
      default => [ Lvm::Volume[$name], File ["${vedir}/$name"] ],
    },
  }

  file { "${vedir}/$name":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  lvm::volume { $name:
    ensure => present,
    vg => $lvm_vg,
    pv => $lvm_pv,
    fstype => $lvm_fstype,
    size => $lvm_size,
  }

  if ($puppetize) and ($ensure == 'present') {

    notify { "notify-puppetize-$name":
			message => "Puppetizing $name",
      require => Virt[$name],
		}

    exec { "puppetize-$name":
      command => "vzctl exec2 $name 'puppet agent -t -l /tmp/install.log --pluginsync true'",
      unless => "vzctl exec2 $name 'crontab -l | grep -q puppet-client'",
      timeout => 300,
      returns => [ 0, 2 ],
      require => Notify["notify-puppetize-$name"],
    }

  }

}

