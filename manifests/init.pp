class virt {
	case $virtual {
		/^kvm/: { include virt::kvm }
		/^xen/: { include virt::xen }
		/^openvzhn/: { include virt::openvz }
	}
}

class virt::xen {
	case $operatingsystem {
		debian: { include virt::xen::debian }
		ubuntu: { include virt::xen::ubuntu }
		fedora: { include virt::xen::fedora }
	}
}

class virt::kvm {
	case $operatingsystem {
		debian: { include virt::kvm::debian }
		ubuntu: { include virt::kvm::ubuntu }
		fedora: { include virt::kvm::fedora }
	}
}

class virt::openvz {
	case $operatingsystem {
		debian: { include virt::openvz::debian }
		ubuntu: { include virt::openvz::ubuntu }
		fedora: { include virt::openvz::fedora }
	}
}

##
# KVM
##

class virt::kvm::debian {
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

class virt::kvm::ubuntu {
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

class virt::kvm::fedora {
	package {
		["kvm",
		"qemu",
		"libvirt",
		"python-virtinst",
		"ruby-libvirt"]:
			ensure => latest;
	}
}

##
# Xen
##

class virt::xen::debian {
	package {
		["linux-image-xen-686",
		"xen-hypervisor",
		"xen-tools",
		"xen-utils"]:
			ensure => latest;
	}
}
class virt::xen::ubuntu {
	package {
		["python-vm-builder",
		"ubuntu-xen-server",
		"libvirt-ruby"]:
			ensure => latest;
	}
}
class virt::xen::fedora {
	package {
		["kernel-xen",
		"xen",
		"ruby-libvirt"]:
			ensure => latest;
	}
}

##
# OpenVZ
##

class virt::openvzhn::debian {
	package {
		["linux-image-openvz-686",
		"vzctl",
		"vzquota",
		"vzdump"]:
			ensure => latest;
	}
}


class virt::openvzhn::ubuntu {
	package {
		["linux-openvz",
		"vzctl",
		"vzquota"]:
			ensure => latest;
	}
}


class virt::openvzhn::fedora {
	package {
		["ovzkernel",
		"vzctl",
		"vzquota"]:
			ensure => latest;
	}
}
