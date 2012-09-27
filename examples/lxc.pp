# lXC Examples

class lxc-guest2 {
  include virt::lxc

  virt { 'container1':
    ensure      => running,
    os_template => 'ubuntu',
    provider    => 'lxc'
  }

  # clone from container1
  virt { 'container2':
    ensure   => running,
    clone    => 'container1',
    snapshot => true,
    provider => 'lxc'
  }
}

class lxc-guest2 {

  virt { guest-lxc1:
    ensure      => running,
    os_template => 'ubuntu',
    provider    => 'lxc'
  }

  # clone from guest-lxc1
  virt { guest-lxc2:
    ensure   => running,
    clone    => 'guest-lxc1',
    snapshot => true,
    provider => 'lxc',
    require  => Virt['lxc1']
  }

}
