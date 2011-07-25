class virt {

	include virt::params
	package { $virt::params::packages: ensure => latest }

	File {
		owner => 'root',
		group => 'root',
		mode => 0644,
		subscribe => Package[$virt::params::packages],
	}
	
	service { $virt::params::service:
		ensure => running,
		enable => true,
	}

	case $virtual {
	
		/^openvzhn/: {

			file { 
				"${virt::params::basedir}/vz.conf":
				ensure => present,
				source => 'puppet:///modules/virt/global/vz.conf',
				notify => Service[$virt::params::service];
				[ $virt::params::confdir, $virt::params::vedir ]: ensure => directory;
			}

		}
	}
}
