class xen-fullvirt-guest {
	virt { "Jun29":
		memory => 512,
		virt_path => "/home/carla/ourgrid/images/worker-carla/disk0.qcow2",
		ensure => installed,
		virt_type => "xen_fullyvirt"
	}
}

class ovz-guest {
	virt { "101":
		memory => 1024,
                xml_file => "/etc/libvirt/qemu/systems/101.xml",
		tmpl_cache => "debian-5.0-x86",
		ensure => installed,
		virt_type => "openvz"
	}
}
