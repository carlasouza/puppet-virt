Puppet Virtualization Management Module
=======================================

Puppet Module to manage virtual machines using libvirt.

Overview
--------

This is the full specification for the new types. All have the same fields::
This module provides a new type (`virt`) for virtual machines installation and management like ensure running and so on.
All the operations will be made using libvirt [0]. At first, only Xen fully paravirtualizated, and KVM will be supported.

This module is the result of my work at GSoC 2010.

[0] The Virtualization API - http://www.libvirt.org/

Usage
-----

This is the full specification for the new types. All have the same fields::

  virt { "name":
      desc 	      => "My first VM",
  # Basic configuration
      memory          => 1024, # MB, changeable
      cpus            => 2, # Changeable
      arch            => x86_64 | i386,
      clocksync       => UTC | localtime | timezone | variable, # Clock source
  
  # Boot configuration
      boot_kernel     => "/path/to/vmlinuz",
      boot_initrd     => "/path/to/initrd.img",
      boot_options    => "ks=foo noacpi" # Non changeable, controls, kickstart
          #For now, only the .img files will be supported
      virt_path       => "/path/foo.img" | "/opt/virt_images/" | "/dev/sd4" 
  
  # Storage configuration
      disk_size       => 100000, # MB, not changeable
  
  # OS specification
      os_type         => linux | other | solaris | unix | windows,
      os_variant      => solaris | debian | ubuntu | ...,  # The OS distribution (there's 37 types)
  
  # Virtualization parameters
      provider        => libvirt, # For now, only libvirt is available
      virt_type       => kvm | xen-fullyvirt | xen-paravirt  # for libvirt provider, this field is mandatory
  
  # Network configuration
      interfaces      => [ "eth0", "eth1" ], # Source host interface. Default eth0 or the existing interface
  
  # VM behaviour
      autoboot        => true | false,
      ensure          => running | stopped | installed | absent, # Default value: running
      on_poweroff     => destroy | restart | preserv | rename-restart  # Default value: destroy 
      on_reboot       => destroy | restart | preserv | rename-restart
      on_crash        => destroy | restart | preserv | rename-restart
  }


TODO
----

For now, some parameters will have a few values acceptable:
  * `virtpath` will accept only .img files;
  * `memory` and `cpus` will be, initially, not changeable;
  * input devices specification like mouse and graphic will not be supported for now.
