class virt {
	case $operatingsystem {
		debian: { include virt::debian }
		ubuntu: { include virt::ubuntu }
		fedora: { include virt::fedora }
	}
}
