class virt {
	case $operatingsystem {
		debian: { include virt::debian }
		ubuntu: { include virt::ubuntu }
		fedora: { include virt::fedora }
	}
}

class virt::debian {
	case $virtual {
		kvm: {
			package {
				["kvm",
				"virt-manager",
				"libvirt",
				"libvirt-python",
				"python-virtinst",
				"qemu",
				"qemu-img",
				"qspice-libs"]: 
					ensure => latest; 
			}
		}
		xen: {
			package {
				["linux-image-xen-686",
				"xen-hypervisor",
				"xen-tools",
				"xen-utils"]:
					ensure => latest;
			}
		}
		openvzhn: {
			package {
				["linux-image-openvz-686",
				"vzctl",
				"vzquota",
				"vzdump",
				"libvirt-bin",
				"python-virtinst" ]:
					ensure => latest;
			}
		}
	}
}

class virt::ubuntu {
	case $virtual {
		kvm: {
			package {
				["ubuntu-virt-server",
				"python-vm-builder",
				"kvm",
				"qemu",
				"qemu-kvm",
				"libvirt-ruby"]:
					ensure => latest;
			}
		}
		xen: {
			package {
				["python-vm-builder",
				"ubuntu-xen-server",
				"libvirt-ruby"]:
					ensure => latest;
			}
		}
		openvzhn: {
			package {
				["linux-openvz",
				"vzctl",
				"vzquota",
				"libvirt-bin",
				"python-virtinst"]:
					ensure => latest;
			}
		}
	}
}

class virt::fedora {
	case $virtual {
		kvm: {
			package {
				["kvm",
				"qemu",
				"libvirt",
				"python-virtinst",
				"ruby-libvirt"]:
					ensure => latest;
			}
		}
		xen: {
			package {
				["kernel-xen",
				"xen",
				"ruby-libvirt"]:
					ensure => latest;
			}
		}
		openvzhn: {
			package {
				["ovzkernel",
				"vzctl",
				"vzquota",
				"libvirt",
				"python-virtinst",
				"ruby-libvirt"]:
					ensure => latest;
			}
		}
	}
}
