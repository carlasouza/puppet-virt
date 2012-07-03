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

