class virt::params {

  case $::virtual {
    /^openvzhn/: {
      $servicename = 'vz'
      $basedir = '/etc/vz/'
      $confdir = '/etc/vz/conf/'
      $vedir = '/var/lib/vz/' #XXX: Update here with your custom value
    }
    default: {
      $servicename = 'libvirtd'
    }
  }

  case $::operatingsystem {
    Debian: {

      $packages = $virtual ? {
        kvm => [ 'kvm', 'virt-manager', 'libvirt', 'libvirt-python', 'python-virtinst', 'qemu', 'qemu-img', 'qspice-libs' ],
        xen => [ 'linux-image-xen-686', 'xen-hypervisor', 'xen-tools', 'xen-utils' ],
        openvzhn =>  [ "linux-image-${kernelmajversion}-openvz-686", 'vzctl', 'vzquota' ],
      }
    }

    Ubuntu: {
      $packages = $virtual ? {
        kvm => [ 'ubuntu-virt-server', 'python-vm-builder', 'kvm', 'qemu', 'qemu-kvm', 'libvirt-ruby' ],
        xen => [ 'python-vm-builder', 'ubuntu-xen-server', 'libvirt-ruby' ],
        openvzhn =>  [ "linux-image-${kernelmajversion}-openvz-686", 'vzctl', 'vzquota' ],
      }
    }

    Fedora: {
      # FIXME: not tested
      $packages = $virtual ? {
        kvm => [ 'kvm', 'qemu', 'libvirt', 'python-virtinst', 'ruby-libvirt' ],
        xen => [ 'kernel-xen', 'xen', 'ruby-libvirt' ],
        openvzhn =>  [ 'ovzkernel', 'vzctl', 'vzquota' ],
      }

    }

    default: {
      fail ("This module is not supported on $operatingsystem")
    }
  }
}
