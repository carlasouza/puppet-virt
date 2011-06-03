Puppet Virtualization Management Module
=======================================

Puppet Module to manage virtual machines.

Overview
--------

This module provides a new type, `virt`, for virtual machines installation and management like ensure running and so on.
Xen fullyvirtualization, Xen paravirtualization, KVM, and OpenVZ [1] are supported, which of the first three uses libvirt as provider.

This module is the result of my work at GSoC 2010.

[0] The Virtualization API - http://www.libvirt.org/
[1] OpenVZ - http://wiki.openvz.org/

Usage
-----

This is the full specification for the new type. Note that not all are supported by libvirt provider or openvz provider::

  virt { "name":
      desc            => "My first VM",
      hostname        => "vm",
      id              => 101,
      user            => "user:passwd",
  # Basic configuration
      memory          => 1024, # MB, changeable
      arch            => "i386" | "i686" | "amd64" | "ia64" | "powerpc" | "hppa"
      graphics        => enable | disable | vnc:VNCPORT
      clocksync       => UTC | localtime | timezone | variable, # Clock source

  # CPU parameters
      cpus            => 2, # Changeable
      cpuunits        => 1000
      cpulimit        => 1000
      ioprio          => 0

  # Boot configuration
      boot_localtion  => "/path/to/vmlinuz and initrd.img",
      boot_options    => "noacpi" # Non changeable, controls, kickstart
      kickstart       => "http://path/to/ks.cfg" #Used only for installation
      pxe             => true | false
  
  # Storage configuration
      disk_size       => 10, # GB, not changeable
      diskspace       => 100000,
      diskinodes      => 100000,
      quotatime       => 1000,
      quotaugidlimit  => 1000,
      devices         => ["b|c:major:minor|all:[r|w|rw|none]","device:r|w|rw|none"]
      virt_path       => "/path/foo.img" | "/opt/virt_images/" | "/dev/sd4" 

      * For now, only the existing .img, .qcow2 and .qcow files will be supported *
  
  # Resource management
      noatime          => true | false,
      features         => ["sysfs", "nfs", "sit", "ipip"]
      capability       => ["chown", "dac_override"]
      resources_parameters => ["kmemsize=14372700:14790164", "lockedpages=256:256"]

  # OS specification
      os_type         => linux | other | solaris | unix | windows | hvm,
      os_variant      => ubuntu | "debian-5.0-i386-minimal" | "fedora-13-x86_64" | ..., 
  
  # Virtualization parameters
      virt_type       => kvm | xen-fullyvirt | xen-paravirt | openvz | qemu  # This field is mandatory

  # Network configuration
      interfaces      => [ "eth0", "eth1" ] | "disable" # Source host interface.
      ipaddr          => ["10.0.0.1", "10.0.0.2"],
      nameserver      => ["8.8.8.8", "8.8.4.4"],
      searchdomain    => "localnet.com",
      iptables        => ["iptable_filter", "iptable_mangle", "ipt_limit"],
  
  # VM behaviour
      disabled        => true | false,
      autoboot        => true | false,
      ensure          => running | stopped | installed | absent, # Default value: running
      on_poweroff     => destroy | restart | preserv | rename-restart  # Default value: destroy 
      on_reboot       => destroy | restart | preserv | rename-restart,
      on_crash        => destroy | restart | preserv | rename-restart,

  # XML configuration
      # This will allow you to create a new guest from an already defined XML configuration file.
      xml_file        => "/etc/libvirt/qemu/name.xml"

  } 

Future Work
----

For now, some parameters will have a few values acceptable:
  * `virtpath` will accept only existing .img, .qcow and .qcow2 files;
  * `memory` and `cpus` will be, initially, not changeable for Libvirt provider;
  * Input devices specification like mouse will not be supported for now.
  * The parameters `on_poweroff`; `on_reboot` and `on_crash` are not changeable. They will be used only to create a new domain using Libvirt provider (not for import existing domain's image, because libvirt does not support modify those values)
