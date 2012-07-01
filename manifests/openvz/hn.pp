class virt::openvz::hn {
  include ::virt::libvirt
  case $::operatingsystem {
    ubuntu: { include virt::openvz::hn::ubuntu  }
    debian: { include virt::openvz::hn::debian  }
    fedora: { include virt::openvz::hn::fedora  }
  }
}
