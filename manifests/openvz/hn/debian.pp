class virt::openvz::hn::debian inherits virt::openvz::hn::base {
  Package['openvz-kernel']{
    name => "linux-image-openvz-${architecture}",
  }
  package{'vzdump':
    ensure => present;
  }
}
