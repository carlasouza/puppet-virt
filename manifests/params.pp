class virt::params {

  case $::virtual {
    /^openvzhn/: {
      $servicename = 'vz'
      $basedir = '/etc/vz/'
      $confdir = '/etc/vz/conf/'
      $vedir = '/var/lib/vz/' # You can update here with your custom value
      $packages = $operatingsystem ? {
        Debian => [ "linux-image-${kernelmajversion}-openvz-686", 'vzctl', 'vzquota' ],
        Ubuntu => [ "linux-image-${kernelmajversion}-openvz-686", 'vzctl', 'vzquota' ],
        Fedora => [ 'ovzkernel', 'vzctl', 'vzquota' ],
      }
    }
    /^physical|^kvm/: {
      $servicename = 'libvirtd'
      $packages = $operatingsystem ? {
        Debian => [ 'kvm', 'virt-manager', 'libvirt', 'python-virtinst', 'qemu', 'qemu-img' ],
        Ubuntu => [ 'ubuntu-virt-server', 'python-vm-builder', 'kvm', 'qemu', 'qemu-kvm', 'libvirt-ruby' ],
        Fedora => [ 'kvm', 'qemu', 'libvirt', 'python-virtinst', 'ruby-libvirt' ],
      }
    }
    /^xen/: {
      $servicename = 'libvirtd'
      $packages = $operatingsystem ? {
        Debian => [ 'linux-image-xen-686', 'xen-hypervisor', 'xen-tools', 'xen-utils' ],
        Ubuntu => [ 'python-vm-builder', 'ubuntu-xen-server', 'libvirt-ruby' ],
        Fedora => [ 'kernel-xen', 'xen', 'ruby-libvirt' ],
      }
    }
    default: {
      $servicename = 'libvirtd'
    }
  }

}
