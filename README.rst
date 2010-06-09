Puppet Virtualization Management Module
======================================

Puppet Module to manage virtual machines using libvirt.

Overview
--------

Usage
-----
  
  virtualmachine { "name":
      desc            => "My first VM",
  
  # Basic configuration
      memory          => 1024,                             # MB, changeable
      cpus            => 2,                                # Changeable
      arch            => x86_64 | i386,
      clocksync       => UTC | localtime | timezone | variable,    # Clock source
  
  # Boot configuration
      install_kernel  => "/path/to/vmlinuz",
      install_initrd  => "/path/to/initrd.img",
      virt_path       => "/opt/virt_images/foo.img" | "/opt/virt_images" | "/dev/sd4" #For now, only the .img files will be supported
      install_options => "ks=foo noacpi"  		# non changeable, controls, kickstart
  
  # Storage configuration
      disk_size       => 100000,                              # MB, not changeable
  
  # OS specification
      os_type         => linux | other | solaris | unix | windows,
      os_variant      => solaris | debian | ubuntu | ...,  # The OS distribution (theres 37 types)
  
  # Virtualization parameters
      provider        => libvirt,                          # For now, only libvirt is available
      virt_type       => qemu | xen_paravirt | xen_fullvirt,
  
  # Network configuration
      interfaces      => [ "eth0", "eth1" ],                       # Source host interface. Default eth0 or the exists interface
  
  # VM behaviour
      autoboot        => true | false,
      ensure          => running | stopped,
      on_poweroff     => destroy | restart | preserv | rename-restart  # default destroy
  }
  

TODO
----
