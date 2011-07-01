Puppet Virtualization Management Module
=======================================

Puppet Module to manage virtual machines using libvirt.

Overview
--------

This module provides a new type, `virt`, for virtual machines installation and management like ensure running and so on.
All the operations will be made using libvirt [0]. At first, only Xen fullyvirtualization, Xen paravirtualization, KVM and OpenVZ are supported.

This module is the result of my work at GSoC'2010.

[0] The Virtualization API - http://www.libvirt.org/

Usage
-----

This is the full specification for the new types. All have the same fields::

  virt { "name":
      desc            => "My first VM",
  # Basic configuration
      memory          => 1024, # MB, changeable
      cpus            => 2, # Changeable
      arch            => "i386" | "i686" | "amd64" | "ia64" | "powerpc" | "hppa"
      graphics        => enable | disable | vnc:VNCPORT
      clocksync       => UTC | localtime | timezone | variable, # Clock source
  
  # Boot configuration
      boot_localtion  => "/path/to/vmlinuz and initrd.img",
      boot_options    => "noacpi" # Non changeable, controls, kickstart
      kickstart       => "http://path/to/ks.cfg" #Used only for installation
      pxe             => true | false
  
  # Storage configuration
      disk_size       => 10, # GB, not changeable
      virt_path       => "/path/foo.img" | "/opt/virt_images/" | "/dev/sd4" 

      * For now, only the existing .img, .qcow2 and .qcow files will be supported *
  
  # OS specification
      os_type         => linux | other | solaris | unix | windows | hvm,
      os_variant      => solaris | debian | ubuntu | ...,  # The OS distribution (there's 37 types)
      tmpl_cache      => "debian-5.0-i386-minimal" | "fedora-13-x86_64" | ...,  # This only applies to OpenVZ guests
  
  # Virtualization parameters
      virt_type       => kvm | xen-fullyvirt | xen-paravirt | openvz | qemu  # for libvirt provider, this field is mandatory

      * If you specify Openvz as a type you'd like to create, the following fields 
        are the minimum requirements: `name`, `memory`, `vcpu`, `tmpl_cache`, and `xml_file` *
  
  # Network configuration
      interfaces      => [ "eth0", "eth1" ] | "disable" # Source host interface.
  
  # VM behaviour
      autoboot        => true | false,
      ensure          => running | stopped | installed | absent, # Default value: running
      on_poweroff     => destroy | restart | preserv | rename-restart  # Default value: destroy 
      on_reboot       => destroy | restart | preserv | rename-restart
      on_crash        => destroy | restart | preserv | rename-restart

  # XML configuration
      # This will allow you to create a new guest from an already defined XML configuration file.
      xml_file        => "/etc/libvirt/qemu/name.xml"

      * When creating a new openvz container this option is required - note
        please that the xml file must be named after the VEID i.e. (/etc/libvirt/qemu/101.xml) *
  } 

Future Work
----

For now, some parameters will have a few values acceptable:
  * `virtpath` will accept only existing .img, .qcow and .qcow2 files;
  * `memory` and `cpus` will be, initially, not changeable;
  * Input devices specification like mouse will not be supported for now.
  * The parameters `on_poweroff`; `on_reboot` and `on_crash` are not changeable. They will be used only to create a new domain (not for import existing domain's image, because libvirt does not support modify those values)
  * if `virt_type` is openvz, providing both `tmpl_cache` and `xml_file` are required.
