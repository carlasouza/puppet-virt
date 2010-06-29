class virt-exemple {
	virt { "Jun29":
		memory => 512,
		virt_path => "/home/carla/ourgrid/images/worker-carla/disk0.qcow2",
		ensure => installed,
		virt_type => "xen_fullyvirt"
	}
}
