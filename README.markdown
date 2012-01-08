# Puppet Virtualization Management Module

Puppet Module to manage virtual machines. Provides a the type: `virt`.

----------------

### virt

Manage virtual environments. [Xen] [1], [KVM] [2], and [OpenVZ] [3] hypervisors are supported, which of the first three uses [libvirt] [4] as provider.
This module is the result of my work at GSoC 2010. I thank [Reliant Security] [5] for funding the OpenVZ provider development.

  [1]: http://xen.org "Xen® Hypervisor"
  [2]: http://www.linux-kvm.org/  "Kernel Based Virtual Machin"
  [3]: http://wiki.openvz.org/  "OpenVZ"
  [4]: http://www.libvirt.org/ "The Virtualization API"
  [5]: http://reliantsecurity.com/  "Reliant Security"

**Autorequires:** If Puppet is managing Xen or KVM guests, the virt resource will autorequire `libvirt` library.

Example:

    virt { server:
      ensure     => 'running',
      id       => 101,
      os_template => 'ubuntu-10.10',
      virt_type  => 'openvz',
      autoboot   => 'false'
    }

Note that some values can be specified as an array of values:

    virt { server:
      ensure => 'installed',
      memory => 512,
      os_template => 'ubuntu-10.10-x86_64',
      virt_type => 'openvz',
      autoboot => true,
      interfaces => [ "eth0a", "eth1a"]
    }

#### Features

- *disabled*: The provider can disable guest start.
- *cpu_fair*: The provider can manage CPU usage by guest.
- *disk_quota*: The provider can set disk usage quota by the guest.
- *pxe*: The provider supports guests creation using pxe.
- *iptables*: The provider can loads iptables modules on the guest.
- *graphics*: The provider can setup a virtual console in the guest for VNC.
- *clocksync*: The provider can specify the guest's clock syncronization method.
- *boot_params*: The provider support parameters for the guest boot.
- *manages_resources*: The provider manage a set of limits and guarantees controlled per guest.
- *manages_capabilities*: The provider manage a set of capabilities for a guest.
- *manages_features*: The provider can enable or disable a specific guest feature.
- *manages_devices*: The provider can give the guest an access to a device.
- *manages_users*: The provider manage guest's users and passwords.
- *manages_behaviour*: The provider manage the quest's behaviour for reboot, crash and shutdown.
- *initial_config*: The provider can receive a config file with default values for VE creation.
- *storage_path*: The provider can set the path to storage and mount VE files.


Features \ Provider  | libvirt | openvz |
-------------------- | ------- | ------ |
disabled             |         |  *X*   |
cpu_fair             |         |  *X*   |
disk_quota           |         |  *X*   |
pxe                  |   *X*   |        |
iptables             |         |  *X*   |
graphics             |   *X*   |        |
clocksync            |   *X*   |        |
boot_params          |   *X*   |        |
manages_resources    |         |  *X*   |
manages_capabilities |         |  *X*   |
manages_features     |         |  *X*   |
manages_devices      |         |  *X*   |
manages_users        |         |  *X*   |
manages_behaviour    |   *X*   |        |
initial_config       |         |  *X*   |
storage_path         |         |  *X*   |


#### Parameters

##### desc

A description of the virutal machine. Generally is what services it provides.

##### name 

- **namevar**
The guest's name.

##### hostname

The guest's hostname. It not specified, `name` will be used as VE's hostname.

##### id 

OpenVZ CT ID. It must be an integer greater then 100. CT ID <= 100 are reserved for OpenVZ internal purposes. If not specified, the provider will automatically generate it with the first valid value.

##### ensure

Valid values are `running`, `stopped`, `installed`, `absent`.

##### os_type

Optimize the guest configuration for a type of operating system (ex. 'linux', 'windows') for libvirt provider. It is used during the guest creation.

##### os_template

Further optimize the guest configuration for a specific operating system variant (ex. 'fedora8', 'winxp'). This parameter is optional for libvirt provider and mandatory for openvz provider.

Available values for libvirt are:

* `linux`
 * `debianetch`: Debian Etch
 * `debianlenny`: Debian Lenny
 * `debiansqueeze`: Debian Squeeze
 * `fedora5`: Fedora Core 5
 * `fedora6`:  Fedora Core 6
 * `fedora7`: Fedora 7
 * `fedora8`: Fedora 8
 * `fedora9`: Fedora 9
 * `fedora10`: Fedora 10
 * `fedora11`: Fedora 11
 * `generic24`: Generic 2.4.x kernel
 * `generic26`: Generic 2.6.x kernel
 * `virtio26`: Generic 2.6.25 or later kernel with virtio
 * `rhel2.1`: Red Hat Enterprise Linux 2.1
 * `rhel3`: Red Hat Enterprise Linux 3
 * `rhel4`: Red Hat Enterprise Linux 4
 * `rhel5`: Red Hat Enterprise Linux 5
 * `sles10`: Suse Linux Enterprise Server
 * `ubuntuhardy`: Ubuntu 8.04 LTS (Hardy Heron)
 * `ubuntuintrepid`: Ubuntu 8.10 (Intrepid Ibex)
 * `ubuntujaunty`: Ubuntu 9.04 (Jaunty Jackalope)

* `other`
 * `generic`: Generic
 * `msdos`: MS-DOS
 * `netware4`: Novell Netware 4
 * `netware5`: Novell Netware 5
 * `netware6`: Novell Netware 6

* `solaris`
 * `opensolaris`: Sun OpenSolaris
 * `solaris10`: Sun Solaris 10
 * `solaris9`: Sun Solaris 9

* `unix`
 * `freebsd6`: Free BSD 6.x
 * `freebsd7`: Free BSD 7.x
 * `openbsd4`: Open BSD 4.x

* `windows`
 * `vista`: Microsoft Windows Vista
 * `win2k`: Microsoft Windows 2000
 * `win2k3`: Microsoft Windows 2003
 * `win2k8`: Microsoft Windows 2008
 * `winxp`: Microsoft Windows XP (x86)
 * `winxp64`: Microsoft Windows XP (x86\_64)

For OpenVZ provider, available values are:

* `centos-4`: CentOS 4 
* `centos-5`: CentOS 5
* `debian-5.0`: Debian Lenny
* `debian-6.0`: Debian Squeeze
* `fedora-13`: Fedora 13
* `fedora-14`: Fedora 14
* `suse-11.3`: Suse 11.3
* `suse-11.4`: Suse 11.4
* `ubuntu-8.04`: Ubuntu LTS 8.04
* `ubuntu-9.10`: Ubuntu 9.10
* `ubuntu-10.04`: Ubuntu LTS 10.04
* `ubuntu-10.10`: Ubuntu 10.10
* `ubuntu-11.04`: Ubuntu 11.04

Also, you can use a custom value with your custom template name. Example: `my-customized-ubuntu-10` or `fedora-mycompany`.

When using OpenVZ provider, the template for the new guest will be automaticaly downloaded if don't already exists. It will download from official OpenVZ repository or from URL specified at `tmpl_repo` parameter.

##### provider

The specific backend for provider to use.
Available providers are:

* **openvz**: Guest management for OpenVZ guests. Supported features: `disabled`, `cpu_fair`, `disk_quota`, `iptables`, `manages_resources`, `manages_capabilities`, `manages_features`, `manages_devices` and `manages_users`.
* **libvirt**: Guest management for Xen and KVM guests. Note that you will need to install the `libvirt` Ruby library. Supported features: `pxe`, `graphics`, `clocksync`, `boot_params` and `manages_behaviour`

##### virt_type

Specify the guest virtualization type. Mandatory field.
Available values:

* `xen_fullyvirt`: Request the use of full virtualization, if both para & full virtualization are available on the host. This parameter may not be available if connecting to a Xen hypervisor on a machine without hardware virtualization support. This parameter is implied if connecting to a QEMU based hypervisor.
* `xen_paravirt`: This guest should be a paravirtualized guest. It requires hardware virtualization support
* `kvm`: When installing a QEMU guest, make use of the KVM or KQEMU kernel acceleration capabilities if available. Use of this option is recommended unless a guest OS is known to be incompatible with the accelerators.
* `openvz`: When defining an OpenVZ guest, the `os_template` paramenter must be defined.
The values `xen_fullyvirt`, `xen_paravirt` and `kvm` will use libvirt as provider. `openvz` will use the `openvz` provider.

##### xml_file

This is the path to a predefined xml config file, to be used with the import function.

##### ve_root

Sets the path to the mount point for the container root directory (default is VE_ROOT specified in vz.conf(5) file). Argument can contain literal string $VEID, which will be substituted with the numeric CT ID.

Requires features `storage_path`.

##### ve_private

Set the path to directory in which all the files and directories specific to this very container are stored (default is VE_PRIVATE specified in vz.conf(5) file). Argument can contain literal string $VEID, which will be substituted with the numeric CT ID.

Requires features `storage_path`.

##### configfile

If specified, values from example configuration file /etc/vz/conf/ve-<VALUE>.conf-sample are put into the container configuration file. If this container configuration file already exists, it will be removed.

Requires features `initial_config`.

##### user 

User name and password. It is generally a good idea to keep to the degenerate 8 characters, beginning with a letter.

Sets password for the given user in the guest, creating the user if it does not exists. In case guest is not running, it is automatically mounted, then all the appropriate file changes are applied, then it is unmounted.

Requires features `manages_users`.

For OpenVZ guests, must use the format: "user:password"

##### ipaddr 

IP address(es) of the guest. Multiple IP addresses should be specified as an array.

##### interfaces

Connect the guest network to the host using the specified network as a bridge. The value can take one of 2 formats:

* `disabled`: The guest will have no network.
* `[ "ethX", ... ] | "ethX"`: The guest can receive one or an array with interface's name from host to connect to the guest interfaces.
* `ifname[,mac,host_ifname,host_mac,[bridge]]`: For OpenVZ hypervisor, the network interface must be specified using the format above, where:
 * 'ifname' is the ethernet device name in the guest;
 * 'mac' is its MAC address;
 * 'host_ifname' is the ethernet device name on the host;
 * 'host_mac' is its MAC address. MAC addresses should be in the format like XX:XX:XX:XX:XX:XX.

Bridge is an optional parameter which can be used in custom network start scripts to automatically add the interface to a bridge. All parameters except ifname are optional and are automatically generated if not specified.

If the specified interfaces does not exist, it will be ignored and raises a warning.

##### macaddrs

Fixed MAC address for the guest; 
If this parameter is omitted, or the value \"RANDOM\" is specified a suitable address will be randomly generated.

For Xen virtual machines it is required that the first 3 pairs in the MAC address be the sequence '00:16:3e', while for QEMU or KVM virtual machines it must be '54:52:00'.
For OpenVZ virtual machine, the interface must exists previously.

##### network_cards 

Moves network device from the host system to a specified OpenVZ guest. Multiple network cards should be specified as an array.
Requires features `manages_devices`.

##### nameserver 

DNS name server(s). Multiple name servers should be specified as an array.

##### searchdomain

DNS search domain name(s).

##### iptables 

Requires features iptables.

##### arch

The domain's installation architecture. Not Changeable.
If not specified for OpenVZ guests, it will assume the same archtecture from host machine.

##### memory

The maximum amount of memory allocation for the guest domain.

##### cpus 

Number of virtual CPUs active in the guest domain.

##### cpuunits 

CPU weight for a guest. Argument is positive non-zero number, passed to and used in the kernel fair scheduler.
The larger the number is, the more CPU time this guest gets. Maximum value is 500000, minimal is 8. Number is relative to weights of all the other running guests. If cpuunits are not specified, default value of 1000 is used.
Requires features `cpu_fair`.

##### cpulimit 

Limit of CPU usage for the guest, in per cent. Note if the computer has 2 CPUs, it has total of 200% CPU time. Default CPU limit is 0 (no CPU limit).
Requires features `cpu_fair`.

##### ioprio 

Assigns  I/O priority to guest. Priority range is 0-7. The greater priority is, the more time for I/O activity guest has. By default each guest has priority of 4.
Requires features `cpu_fair`.

##### graphics

Setup a virtual console in the guest to be imported. If no graphics option is specified, will default to enable.
Available values:

* `enable`: Setup a virtual console in the guest and export it as a VNC server in the host. The VNC server will run on the first free port number at 5900 or above.
* `vnc:VNCPORT`: Request a permanent, statically assigned port number for the guest VNC console. Use of this option is discouraged as other guests may automatically choose to run on this port causing a clash.
* `disable`: No graphical console will be allocated for the guest.
Requires features `graphics`.

##### clocksync

The guest clock synchronization can assume three possible values, allowing fine grained control over how the guest clock is synchronized to the host. NB, not all hypervisors support all modes.
Available values:       

* `utc`: The guest clock will always be synchronized to UTC when booted
* `localtime`: The guest clock will be synchronized to the host's configured timezone when booted, if any.
* `timezone`: The guest clock will be synchronized to the requested timezone using the timezone attribute.
* `variable`: The guest clock will have an arbitrary offset applied relative to UTC. The delta relative to UTC is specified in seconds, using the adjustment attribute. The guest is free to adjust the RTC over time an expect that it will be honoured at next reboot. This is in contrast to 'utc' mode, where the RTC adjustments are lost at each reboot.
NB, at time of writing, only QEMU supports the variable clock mode, or custom timezones.

Requires features `clocksync`.

##### tmpl_repo

The URL from where download OpenVZ precreated templates. Default value: `http://download.openvz.org/template/precreated/`

##### boot_location

Installation source for guest virtual machine kernel+initrd pair.  The `url` can take one of the following forms:

* `DIRECTORY`: Path to a local directory containing an installable distribution image
* `nfs:host:/path or nfs://host/path`: An NFS server location containing an installable distribution image
* `http://host/path`: An HTTP server location containing an installable distribution image
* `ftp://host/path`: An FTP server location containing an installable distribution image

Requires features `boot_params`.

##### boot_options

Additional kernel command line arguments to pass to the installer when performing a guest install from declared location.
Requires features `boot_params`.

##### kickstart

The kickstart file location. Requires features `boot_params`.

##### virt_path

Path to disk image file. This field is mandatory for Xen and KVM guests. NB: Initially only import existing disk is available for this provider. Image files must end with `*.img`, `*.qcow` or `*.qcow2`

##### private

Whether specified to set the path to directory in which all the files and directories specific to this very guest are stored (default is VE_PRIVATE specified in vz.conf(5) file). Argument can contain string $VEID, which will be substituted with the numeric CT ID.

##### disk_size 

Size (in GB) to use if creating new guest storage. Not changeable.

##### quotatime 

Sets soft overusage time limit for disk quota (also known as grace period).
Requires features `disk_quota`.

##### quotaugidlimit 

Sets maximum number of user/group IDs in a guest for which disk quota inside the guest will be accounted. If this value is set to 0, user and group quotas inside the guest will not be accounted.

Note that if you have previously set value of this parameter to 0, changing it while the guest is running will not take effect.
Requires features `disk_quota`.

##### diskinodes 

Sets soft and hard disk quotas, in i-nodes. Must follow the format: `N:N` where first parameter is soft quota, second is hard quota.
Requires features `disk_quota`.

##### diskspace 

Sets soft and hard disk quotas, in blocks. Must follow the format: `N:N` where first parameter is soft quota, second is hard quota. One block is currently equal to 1Kb. Also suffixes G, M, K can be specified.
Requires features `disk_quota`.

##### devices 

Give the container an access (r - read only, w - write only, rw - read/write, none - no access) to:

* a device designated by the special file /dev/device. Device file is created in a container by vzctl. 
 * Use format: device:r|w|rw|none
* a block or character device designated by its major and minor numbers. Device file have to be created manually. 
 * Use format: b|c:major:minor|all:[r|w|rw|none]
Requires features `manages_devices`.

##### pxe 

Use the PXE boot protocol to load the initial ramdisk and kernel for starting the guest installation process. Valid values are `true`, `false`. Requires features `pxe`.

##### on_crash

The content of this element specifies the action to take when the guest crashes. Available values:

* `destroy`: The domain will be terminated completely and all resources released.
* `restart`: The domain will be terminated, and then restarted with the same configuration.
* `preserve`: The domain will be terminated, and its resource preserved to allow analysis.
* `rename-restart`: The domain will be terminated, and then restarted with a new name."
Requires features `manages_behaviour`.

##### on_poweroff

The content of this element specifies the action to take when the guest requests a poweroff. Valid values are the same of `on_crash` parameter.
Requires features `manages_behaviour`.

##### on_reboot

The content of this element specifies the action to take when the guest requests a reboot. Valid values are the same of `on_crash` parameter.
Requires features `manages_behaviour`.

##### autoboot

Determines if the guest should start when the host starts. Valid values are `true`, `false`.

##### disabled 

Disable guest star. Valid values are `true`, `false`. Requires features `disabled`.

##### noatime 

Sets noatime flag (do not update inode access times) on file system. Valid values are `true`, `false`. Requires features `manages_resources`.

##### features 

Enable or disable a specific guest feature.  Known features are: `sysfs`, `nfs`, `sit`, `ipip`. Requires features `manages_features`.

##### capability 

Sets a capability for a guest. Note that setting capability when the guest is running does not take immediate effect; restart the guest in order for the changes to take effect. Note a guest has default set of capabilities, thus any operation on capabilities is 'logical and' with the default capability mask.

You can use the following values for capname: `chown`, `dac_override`, `dac_read_search`, `fowner`, `fsetid`, `kill`, `setgid`, `setuid`, `setpcap`, `linux_immutable`, `net_bind_service`, `net_broadcast`, `net_admin`, `net_raw`, `ipc_lock`, `ipc_owner`, `sys_module`, `sys_rawio`, `sys_chroot`, `sys_ptrace`, `sys_pacct`, `sys_admin`, `sys_boot`, `sys_nice`, `sys_resource`, `sys_time`, `sys_tty_config`, `mknod`, `lease`, `setveid`, `ve_admin`.

Requires features `manages_capabilities`.
WARNING: setting some of those capabilities may have far reaching security implications, so do not do it unless you know what you are doing. Also note that setting setpcap:on for a guest will most probably lead to inability to start it.

##### resources_parameters

Requires one or two arguments. In case of one argument, vzctl sets barrier and limit to the same value. In case of two colon-separated arguments, the first is a barrier, and the second is a limit. Each argument is either a number, a number with a suffix, or the special value `unlimited`. UBC parameters description can be found at: `http://wiki.openvz.org/UBC_parameters_table`.

Valid values are: `vmguarpages`, `physpages`, `oomguarpages`, `lockedpages`, `privvmpages`, `shmpages`, `numproc`, `numtcpsock`, `numothersock`, `numfile`, `numflock`, `numpty`, `numsiginfo`, `dcachesize`, `numiptent`, `kmemsize`, `tcpsndbuf`, `tcprcvbuf`, `othersockbuf`, `dgramrcvbuf`.

Requires features `resources_management`.

----------------


## Future Work

For now, some parameters will have a few values acceptable:

  * Add to Facter facts about host's OpenVZ information;
  * Implement VServer provider;
  * `virt_path` will accept only existing .img, .qcow and .qcow2 files;
  * Input devices specification like mouse will not be supported for now;
  * The parameters `on_poweroff`, `on_reboot` and `on_crash` for libvirt provider are not changeable. They will be used only to create a new domain using Libvirt provider (not for import existing domain's image, because libvirt does not support modify those values).

## License

This module is released under GNU General Public License, version 3 (GPLv3) (http://www.opensource.org/licenses/gpl-3.0.html)
