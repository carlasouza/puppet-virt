class virt::params {

    case $operatingsystem {

        # Each variable should really be broken out depending on $virtual but I'm not doing that now since
        # I am only working with openvz
        debian: {
            $service = 'vz'
            $basedir = '/etc/vz'
            $confdir = '/etc/vz/conf'
            $vedir = '/vz'
            $packages = $virtual ? {
              kvm => [ 'kvm', 'virt-manager', 'libvirt', 'libvirt-python', 'python-virtinst', 'qemu', 'qemu-img', 'qspice-libs' ], 
              xen => [ 'linux-image-xen-686', 'xen-hypervisor', 'xen-tools', 'xen-utils' ],
              openvzhn =>  [ "linux-image-${kernelmajversion}-openvz-686", 'vzctl', 'vzquota' ],
            }
        }

        ubuntu: {
            $service = 'vz'
            $basedir = '/etc/vz'
            $confdir = '/etc/vz/conf'
            $vedir = '/vz'
            $packages = $virtual ? {
              kvm => [ 'ubuntu-virt-server', 'python-vm-builder', 'kvm', 'qemu', 'qemu-kvm', 'libvirt-ruby' ],
              xen => [ 'python-vm-builder', 'ubuntu-xen-server', 'libvirt-ruby' ],
              openvzhn =>  [ "linux-image-${kernelmajversion}-openvz-686", 'vzctl', 'vzquota' ],
            }
        }

        fedora: {
            # I don't run this distribution so fix if needed - AK
            $service = 'vz'
            $basedir = '/etc/vz'
            $confdir = '/etc/vz/conf'
            $vedir = '/vz'
            $packages = $virtual ? {
              kvm => [ 'kvm', 'qemu', 'libvirt', 'python-virtinst', 'ruby-libvirt' ],
              xen => [ 'kernel-xen', 'xen', 'ruby-libvirt' ],
              openvzhn =>  [ 'ovzkernel', 'vzctl', 'vzquota', 'libvirt', 'python-virtinst', 'ruby-libvirt' ],
            }

        }

        default: {
            fail("This module is not supported on $operatingsystem")
        }

    }
        
}
