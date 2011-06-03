module Puppet
	newtype(:virt) do
		@doc = "Manages virtual machines using the 'libvirt' hypervisor management library. The guests may be imported using an existing image, configured to use one or more virtual disks, network interfaces and other options which we haven't included yet. Create a new xen, kvm or openvz guest."

		feature :disabled,
			"Disable guest start guests."

		feature :cpu_fair,
			"These parameters control CPU usage by guest."

		feature :disk_quota,
			"Specify disk usage quota."

		feature :resource_management,
			"A set of limits and guarantees controlled per guest. More information at http://wiki.openvz.org/UBC_parameter_properties"
	
		feature :capability_management,
			"A set of capabilities management for a guest."

		feature :pxe,
			"Supports guests creation using pxe."

		feature :features_management,
			"Enable or disable a specific guest feature."

		feature :devices_management,
			"Give the guest an access to a device "

		feature :user_management,
			"Manages guest's users"

		# A base class for numeric Virt parameters validation.
		class VirtNumericParam < Puppet::Property

			def numfix(num)
				if num =~ /^\d+$/
					return num.to_i
				elsif num.is_a?(Integer)
					return num
				else
					return false
				end
			end

			validate do |value|
				if numfix(value)
					return value
				else
					self.fail "%s is not a valid %s" % [value, self.class.name]
				end
			end

		end

		def self.instances()
			[]
		end

		def munge_boolean(value)
			case value
				when true, "true", :true
					:true
				when false, "false", :false
					:false
			else
				fail("munge_boolean only takes booleans")
			end
		end

		ensurable do
			desc "The guest's ensure field can assume one of the following values:
	`running`:
		Creates config file, and makes sure the domain is running.
	`installed`:
		Creates config file, but doesn't touch the state of the domain.
	`stopped`:
		Creates config file, and makes sure the domain is not running.
	`absent`:
		Removes config file, and makes sure the domain is not running.
	`purged`:
		Purge all files related."
			newvalue(:stopped) do
				provider.stop
			end
	
			newvalue(:running) do
				provider.start
			end

			newvalue(:installed) do
				provider.setpresent
			end

			newvalue(:absent) do
				provider.destroy
			end
			
			newvalue(:purged) do
				provider.purge
			end

			defaultto(:running)
			
			def retrieve
				provider.status
			end
	
		end
		
		newparam(:desc) do
			desc "The guest's description."
		end
	
		newparam(:name, :namevar => true) do
			desc "The guest's name."
		end

		newparam(:hostname) do
			desc "The guest's hostname."
		end

		newparam(:ctid, :parent => VirtNumericParam) do
			desc "OpenVZ CT ID. It must be an integer greater then 100. CT ID <= 100 are reserved for OpenVZ internal purposes."

				validate do |value|
					if value.to_i > 100
						return value
					else
						self.fail "%s is not a valid %s" % [value, self.class.name]
					end
				end
		end

		newproperty(:user, :required_features => :user_management) do
			desc "Sets password for the given user in the guest, creating the user if it does not exists. 
	In case guest is not running, it is automatically mounted, then all the appropriate file changes are applied, then it is unmounted."
		end

		newproperty(:ipaddr, :array_matching => :all) do
			desc "IP address(es) of the VE."

			validate do |ip|
				unless ip =~ /^\d+\.\d+\.\d+\.\d+$/
					raise ArgumentError, "\"#{ip}\" is not a valid IP address."
				end
			end

			def insync?(current)
				current.sort == @should.sort
			end
		end

		newproperty(:nameserver, :array_matching => :all) do
			desc "DNS name server(s)."
			validate do |val|
				unless val =~ /^\d+\.\d+\.\d+\.\d+( +\d+\.\d+\.\d+\.\d+)*$/
					raise ArgumentError, "\"#{val}\" is not a valid space-separated list of IP addresses."
				end
			end

			def insync?(current)
				current.sort == @should.sort
			end
		end

		newproperty(:iptables, :array_matching => :all) do
			desc "Restrict access to iptables modules inside a guest (by default all iptables modules that are loaded in the host system are accessible inside a guest).
	You can use the following values for name: iptable_filter, iptable_mangle, ipt_limit, ipt_multiport, ipt_tos, ipt_TOS, ipt_REJECT, ipt_TCPMSS, ipt_tcpmss, ipt_ttl, ipt_LOG, ipt_length, ip_conntrack, ip_conntrack_ftp, ip_conntrack_irc, ipt_conntrack, ipt_state, ipt_helper, iptable_nat, ip_nat_ftp, ip_nat_irc, ipt_REDIRECT, xt_mac, ipt_owner."
		end

		newproperty(:searchdomain) do
			desc "DNS search domain name(s)."
		end

		# This will change to properties
		newproperty(:memory, :parent => VirtNumericParam) do
			desc "The maximum amount of memory allocation for the guest domain.
					Specified in MB."

			isrequired #FIXME Bug #4049
		end

		newproperty(:cpus, :parent => VirtNumericParam) do
			desc "Number of virtual CPUs active in the guest domain."

			defaultto(1)
		end

		newproperty(:cpuunits, :parent => VirtNumericParam, :required_features => :cpu_fair) do
			desc "CPU weight for a guest. Argument is positive non-zero number, passed to and used in the kernel fair scheduler.
			The larger the number is, the more CPU time this guest gets.
			Maximum value is 500000, minimal is 8. Number is relative to weights of all the other running guests.
			If cpuunits are not specified, default value of 1000 is used."
		end
	
		newproperty(:cpulimit, :parent => VirtNumericParam, :required_features => :cpu_fair) do
			desc "Limit of CPU usage for the guest, in per cent. Note if the computer has 2 CPUs, it has total of 200% CPU time. Default CPU limit is 0 (no CPU limit)."
		end
	
#		newproperty(:ioprio, :parent => VirtNumericParam, :required_features => :manages_password_age) do
		#XXX	:required_features => 
		newproperty(:ioprio, :parent => VirtNumericParam) do
			desc "Assigns  I/O priority to guest.
			Priority range is 0-7.
			The greater priority is, the more time for I/O activity guest has.
			By default each guest has priority of 4."
		end
	
		newparam(:graphics) do
			desc "Setup a virtual console in the guest to be imported. If no graphics option is specified, will default to enable.
	Available values:
	`enable`:
		Setup a virtual console in the guest and export it as a VNC server in the host. The VNC server will run on the first free port number at 5900 or above.
	`vnc:VNCPORT`:
		Request a permanent, statically assigned port number for the guest VNC console. Use of this option is discouraged as other guests may automatically choose to run on this port causing a clash.
	`disable`:
		No graphical console will be allocated for the guest."

			newvalues(:enable,:disable,/^vnc:[0-9]+$/)
			defaultto(:enable)

		end

		newparam(:arch) do
			desc "The domain's installation architecture. Not Changeable"

			newvalues("i386","i686","amd64","ia64","powerpc","hppa")
		end
	
		newparam(:clocksync) do
			desc "The guest clock synchronization can assume three possible values, allowing fine grained control over how the guest clock is synchronized to the host. NB, not all hypervisors support all modes.
	Available values:			
	`utc`:
		The guest clock will always be synchronized to UTC when booted
	`localtime`:
		The guest clock will be synchronized to the host's configured timezone when booted, if any.
	`timezone`:
		The guest clock will be synchronized to the requested timezone using the timezone attribute.
	`variable`:
		The guest clock will have an arbitrary offset applied relative to UTC. The delta relative to UTC is specified in seconds, using the adjustment attribute. The guest is free to adjust the RTC over time an expect that it will be honoured at next reboot. This is in contrast to 'utc' mode, where the RTC adjustments are lost at each reboot.
		NB, at time of writing, only QEMU supports the variable clock mode, or custom timezones."

			newvalues("UTC", "localtime", "timezone", "variable")
		end
	

		# Installation method

		# Location of kernel+initrd pair
		newparam(:boot_location) do
			desc "Installation source for guest virtual machine kernel+initrd pair.  The `url` can take one of the following forms:

	`DIRECTORY`
		Path to a local directory containing an installable distribution image
	`nfs:host:/path or nfs://host/path`
		An NFS server location containing an installable distribution image
	`http://host/path`
		An HTTP server location containing an installable distribution image
	`ftp://host/path`
		An FTP server location containing an installable distribution image"

		end

		#Kickstart file location on the network
		newparam(:kickstart) do
			desc "Kickstart file location. "
			
			munge do |value|
				"ks=" + value
			end	
		
		end

		newparam(:boot_options) do
			desc "Additional kernel command line arguments to pass to the installer when performing a guest install from declared location."
		end

		newparam(:virt_path) do
			desc "Path to disk image file. This field is mandatory. NB: Initially only import existing disk is available.
Image files must end with `*.img`, `*.qcow` or `*.qcow2`"

			isrequired #FIXME Bug #4049

			# Value must end with .img or .qcow or .qcow2
			validate do |value|
				case value
				when String
					if (value =~ /.(img|qcow|qcow2)$/).nil?
						self.fail "%s is not a valid %s" % [value, self.class.name]
					end
				end
				return value
			end

			munge do |value| 
				"path=" + value
			end

		end
	
		####
		# Disk properties
		# Disk size (only used for creating new guests
		newparam(:disk_size, :parent => VirtNumericParam) do
			desc "Size (in GB) to use if creating new guest storage. Not changeable."

			munge do |value|
				"size=" + value
			end
		end

		newproperty(:quotatime, :parent => VirtNumericParam, :required_features => :disk_quota) do
			desc "Sets soft overusage time limit for disk quota (also known as grace period)."
		end
	
		newproperty(:quotaugidlimit, :parent => VirtNumericParam, :required_features => :disk_quota) do
			desc "Sets maximum number of user/group IDs in a guest for which disk quota inside the guest will be accounted. If this value is set to 0, user and group quotas inside the guest will not be accounted.
			Note that if you have previously set value of this parameter to 0, changing it while the guest is running will not take effect."
		end

		newproperty(:diskinodes, :required_features => :disk_quota) do
			desc "Sets soft and hard disk quotas, in i-nodes. First parameter is soft quota, second is hard quota."
		end

		newproperty(:diskspace, :required_features => :disk_quota) do
			desc "Sets soft and hard disk quotas, in blocks. First parameter is soft quota, second is hard quota. One block is currently equal to 1Kb. Also suffixes G, M, K can be specified"
		end

		# Device access management

		newproperty(:devices, :array_matching => :all, :required_features => :devices_management) do
			desc "Give the container an access (r - read only, w - write only, rw - read/write, none - no access) to:
	1) a device designated by the special file /dev/device. Device file is created in a container by vzctl. 
		Use format: device:r|w|rw|none
	2) a block or character device designated by its major and minor numbers. Device file have to be created manually. 
		Use format: b|c:major:minor|all:[r|w|rw|none]"
			def insync?(current)
				current.sort == @should.sort
			end

		end

		# Will it install using PXE?
		newparam(:pxe, :required_features => :pxe) do
			desc "Use the PXE boot protocol to load the initial ramdisk and kernel for starting the guest installation process. PXE is only available for Xen fullyvirtualizated guests"
			newvalues(:true)
			newvalues(:false)

			munge do |value|
				@resource.munge_boolean(value)
			end

			defaultto(:false)
		end
	
		newparam(:os_type) do
			desc "Optimize the guest configuration for a type of operating system (ex. 'linux', 'windows'). Not changable."

			newvalues(:linux, :windows, :unix, :solaris, :other)
		end
	
		newparam(:os_variant) do #TODO change 'os_variant' to 'os'
			desc "Further optimize the guest configuration for a specific operating system variant (ex. 'fedora8', 'winxp'). This parameter is optional, and does not require an `os-type` to be specified.
	Available values:
	`linux`
		`debianetch`: Debian Etch
		`debianlenny`: Debian Lenny
		`debiansqueeze`: Debian Squeeze
		`fedora5`: Fedora Core 5
		`fedora6`:  Fedora Core 6
		`fedora7`: Fedora 7
		`fedora8`: Fedora 8
		`fedora9`: Fedora 9
		`fedora10`: Fedora 10
		`fedora11`: Fedora 11
		`generic24`: Generic 2.4.x kernel
		`generic26`: Generic 2.6.x kernel
		`virtio26`: Generic 2.6.25 or later kernel with virtio
		`rhel2.1`: Red Hat Enterprise Linux 2.1
		`rhel3`: Red Hat Enterprise Linux 3
		`rhel4`: Red Hat Enterprise Linux 4
		`rhel5`: Red Hat Enterprise Linux 5
		`sles10`: Suse Linux Enterprise Server
		`ubuntuhardy`: Ubuntu 8.04 LTS (Hardy Heron)
		`ubuntuintrepid`: Ubuntu 8.10 (Intrepid Ibex)
		`ubuntujaunty`: Ubuntu 9.04 (Jaunty Jackalope)

	`other`
		`generic`: Generic
		`msdos`: MS-DOS
		`netware4`: Novell Netware 4
		`netware5`: Novell Netware 5
		`netware6`: Novell Netware 6

	`solaris`
		`opensolaris`: Sun OpenSolaris
		`solaris10`: Sun Solaris 10
		`solaris9`: Sun Solaris 9

	`unix`
		`freebsd6`: Free BSD 6.x
		`freebsd7`: Free BSD 7.x
		`openbsd4`: Open BSD 4.x

	`windows`
		`vista`: Microsoft Windows Vista
		`win2k`: Microsoft Windows 2000
		`win2k3`: Microsoft Windows 2003
		`win2k8`: Microsoft Windows 2008
		`winxp`: Microsoft Windows XP (x86)
		`winxp64`: Microsoft Windows XP (x86_64)"
		end

		newparam(:virt_type) do
			desc "Specify the guest virtualization type. Mandatory field.
	Available values:
	`xen_fullyvirt`:
		Request the use of full virtualization, if both para & full virtualization are available on the host. This parameter may not be available if connecting to a Xen hypervisor on a machine without hardware virtualization support. This parameter is implied if connecting to a QEMU based hypervisor.
	`xen_paravirt`:
		This guest should be a paravirtualized guest. 
	`kvm`:
		When installing a QEMU guest, make use of the KVM or KQEMU kernel acceleration capabilities if available. Use of this option is recommended unless a guest OS is known to be incompatible with the accelerators.
	`openvz`:
		When defining an OpenVZ guest, the template cache to be used must be defined using tmpl_cache and you must explicitly specify the use of openvz with this attribute (for now)."

			isrequired #FIXME Bug #4049
			newvalues(:kvm, :xen_fullyvirt, :xen_paravirt, :qemu, :openvz) 
			
			munge do |value| 
				if value == "openvz"
					@resource[:provider] = value
				else
					@resource[:provider] = libvirt
				end
			end


		end

		newparam(:xml_file) do
			desc "This is the path to a predefined xml config file, to be used with the import function."

			munge do |value| 
				"path=" + value
			end

		end
		
		newproperty(:interfaces) do
			desc "Connect the guest network to the host using the specified network as a bridge. The value can take one of 2 formats:
	`disabled`:
		The guest will have no network.
	`[ \"ethX\", ... ] | \"ethX\" `
		The guest can receive one or an array with interface's name from host to connect to the guest interfaces.
	'ifname[,mac,host_ifname,host_mac,[bridge]]'
		For OpenVZ hypervisor, the network interface must be specified using the format above, where:
		* 'ifname' is the ethernet device name in the guest;
		* 'mac' is its MAC address;
		* 'host_ifname' is the ethernet device name on the host;
		* 'host_mac' is its MAC address. MAC addresses should be in the format like XX:XX:XX:XX:XX:XX.

		Bridge is an optional parameter which can be used in custom network start scripts to automatically add the interface to a bridge. All parameters except ifname are optional and are automatically generated if not specified.

	If the specified interfaces does not exist, it will be ignored and raises a warning."
			validate do |value|
				unless value.is_a?(Array) or value.is_a?(String)
					self.devfail "interfaces field must be a String or an Array"
				end
			end
		end

		newparam(:macaddrs) do
			desc "Fixed MAC address for the guest; 
If this parameter is omitted, or the value \"RANDOM\" is specified a suitable address will be randomly generated.
For Xen virtual machines it is required that the first 3 pairs in the MAC address be the sequence '00:16:3e', while for QEMU or KVM virtual machines it must be '54:52:00'."
		end
	
		newproperty(:on_poweroff) do
			desc "The content of this element specifies the action to take when the guest requests a poweroff.
	Available values:
	`destroy`:
		The domain will be terminated completely and all resources released.
	`restart`:
		The domain will be terminated, and then restarted with the same configuration.
	`preserve`:
		The domain will be terminated, and its resource preserved to allow analysis.
`rename-restart`:
	The domain will be terminated, and then restarted with a new name."

			newvalues(:destroy, :restart, :preserv, :renamerestart)

		end

		newproperty(:on_reboot) do
			desc "The content of this element specifies the action to take when the guest requests a reboot.
Available values:
`destroy`:
	The domain will be terminated completely and all resources released.
`restart`:
	The domain will be terminated, and then restarted with the same configuration.
`preserve`:
	The domain will be terminated, and its resource preserved to allow analysis.
`rename-restart`:
	The domain will be terminated, and then restarted with a new name."

			newvalues(:destroy, :restart, :preserv, :renamerestart)

		end

		newproperty(:on_crash) do
			desc "The content of this element specifies the action to take when the guest crashes.
Available values:
`destroy`:
	The domain will be terminated completely and all resources released.
`restart`:
	The domain will be terminated, and then restarted with the same configuration.
`preserve`:
	The domain will be terminated, and its resource preserved to allow analysis.
`rename-restart`:
	The domain will be terminated, and then restarted with a new name."

			newvalues(:destroy, :restart, :preserv, :renamerestart)

		end
	
		newproperty(:autoboot) do
			desc "Determines if the guest should start when the host starts."

			newvalue(:true)
			newvalue(:false)

			munge do |value|
				@resource.munge_boolean(value)
			end

		end

		newproperty(:disabled, :required_features => :disabled) do
			desc "Disable guest start for OpenVZ guests.
To force the start of a disabled guest, use vzctl start with --force option."

			newvalue(:true)
			newvalue(:false)

			munge do |value|
				return value == :true ? :yes : :no
			end

		end

		newparam(:private) do
			desc "You can use this parameter to set the path to directory in which all the files and directories specific to this very guest are stored (default is VE_PRIVATE specified in vz.conf(5) file). Argument can contain string $VEID, which will be substituted with the numeric CT ID."
		end

		newproperty(:noatime, :required_features => :resource_management) do
			desc "Sets noatime flag (do not update inode access times) on file system for OpenVZ guests."

			newvalue(:true)
			newvalue(:false)

			munge do |value|
				return value == :true ? :yes : :no
			end

		end

		newproperty(:features, :array_matching => :all, :required_features => :features_management) do
			desc "Enable or disable a specific guest feature.  Known features are: sysfs, nfs, sit, ipip. Available for OpenVZ hypervisor."

			validate do |value|
				feature, mode = value.split(':')
				if !["sysfs", "nfs", "sit", "ipip"].include?(feature)
					raise ArgumentError, "\"#{feature}\" is not a valid feature."
				end
				if !["on", "off"].include?(mode)
					raise ArgumentError, "Feature \"#{feature}\" only accepts \"on\" or \"off\" modes."
				end
			end
		end

		newproperty(:capability, :array_matching => :all, :required_features => :capability_management) do
			desc "Sets a capability for a guest. Note that setting capability when the guest is running does not take immediate effect; restart the guest in order for the changes to take effect. Note a guest has default set of capabilities, thus any operation on capabilities is 'logical and' with the default capability mask.
	You can use the following values for capname: chown, dac_override, dac_read_search, fowner, fsetid, kill, setgid, setuid, setpcap, linux_immutable, net_bind_service, net_broadcast, net_admin, net_raw, ipc_lock, ipc_owner, sys_module, sys_rawio, sys_chroot, sys_ptrace, sys_pacct, sys_admin, sys_boot, sys_nice, sys_resource, sys_time, sys_tty_config, mknod, lease, setveid, ve_admin.
	WARNING: setting some of those capabilities may have far reaching security implications, so do not do it unless you know what you are doing. Also note that setting setpcap:on for a guest will most probably lead to inability to start it."
	
			validate do |value|
				capability, mode = value.split(':')
				if !["chown", " dac_override", " dac_read_search", " fowner", " fsetid", " kill", " setgid", " setuid", " setpcap", " linux_immutable", " net_bind_service", " net_broadcast", " net_admin", " net_raw", " ipc_lock", " ipc_owner", " sys_module", " sys_rawio", " sys_chroot", " sys_ptrace", " sys_pacct", " sys_admin", " sys_boot", " sys_nice", " sys_resource", " sys_time", " sys_tty_config", " mknod", " lease", " setveid", " ve_admin"].include?(capability)
					raise ArgumentError, "\"#{capability}\" is not a valid capability."
				end
				if !["on", "off"].include?(mode)
					raise ArgumentError, "Capability \"#{capability}\" only accepts \"on\" or \"off\" modes."
				end
			end	
		end


		### 
		# UBC parameters (in form of barrier:limit)
		# Requires one or two arguments. In case of one argument, vzctl sets barrier and limit to the same value. In case of two colon-separated arguments, the first is a barrier, and the second is a limit. Each argument is either a number, a number with a suffix, or the special value 'unlimited'."
	
		newproperty(:resources_parameters, :array_matching => :all, :required_features => :resource_management) do
			validate do |value|
				feature = value.split("=")[0].downcase
				features = ["vmguarpages", "physpages", "oomguarpages", "lockedpages", "privvmpages", "shmpages", "numproc", "numtcpsock", "numothersock", "numfile", "numflock", "numpty", "numsiginfo", "dcachesize", "numiptent", "kmemsize", "tcpsndbuf", "tcprcvbuf", "othersockbuf", "dgramrcvbuf"]
				raise ArgumentError, "Feature #{feature} is not valid." unless features.include? feature
			end
			
			def insync?(current)
				current.sort == @should.sort
			end

		end

		newproperty(:vmguarpages, :required_features => :resource_management) do
			desc "This parameter controls how much memory is available to the Virtual Environment (i.e. how much memory its applications can allocate by malloc(3) or other standard Linux memory allocation mechanisms). "
		end

		newproperty(:physpages, :required_features => :resource_management) do
			desc "Total number of RAM pages used by processes in this guest."
		end
		
		newproperty(:oomguarpages, :required_features => :resource_management) do
			desc "The guaranteed amount of memory for the case the memory is “over-booked” (out-of-memory kill guarantee)."
		end
		
		newproperty(:lockedpages, :required_features => :resource_management) do
			desc "Process pages not allowed to be swapped out."
		end
		
		newproperty(:privvmpages, :required_features => :resource_management) do
			desc "Allows controlling the amount of memory allocated by applications."
		end
		
		newproperty(:shmpages, :required_features => :resource_management) do
			desc "The total size of shared memory (IPC, shared anonymous mappings and tmpfs objects). The barrier should be set equal to the limit."
		end
		
		newproperty(:numproc, :required_features => :resource_management) do
			desc "Maximum number of processes and kernel-level threads allowed for this guest."
		end
	
		newproperty(:numtcpsock, :required_features => :resource_management) do
			desc "Maximum number of TCP sockets."
		end
		
		newproperty(:numothersock, :required_features => :resource_management) do
			desc "Maximum number of non-TCP sockets (local sockets, UDP and other types of sockets)."
		end
		
		newproperty(:numfile, :required_features => :resource_management) do
			desc "Maximum number of open files."
		end
		
		newproperty(:numflock, :required_features => :resource_management) do
			desc "Maximum number of file locks."
		end
		
		newproperty(:numpty, :required_features => :resource_management) do
			desc "Maximum number of pseudo-terminals."
		end
		
		newproperty(:numsiginfo, :required_features => :resource_management) do
			desc "Maximum number of siginfo structures."
		end
		
		newproperty(:dcachesize, :required_features => :resource_management) do
			desc "The total size of dentry and inode structures locked in memory."
		end
		
		newproperty(:numiptent, :required_features => :resource_management) do
			desc "The number of NETFILTER (IP packet filtering) entries."
		end
		
		newproperty(:kmemsize, :required_features => :resource_management) do
			desc "Size of unswappable memory in bytes, allocated by the operating system kernel."
		end
		
		newproperty(:tcpsndbuf, :required_features => :resource_management) do
			desc "The total size of buffers used to send data over TCP network connections."
		end
		
		newproperty(:tcprcvbuf, :required_features => :resource_management) do
			desc "The total size of buffers used to temporary store the data coming from TCP network connections."
		end
		
		newproperty(:othersockbuf, :required_features => :resource_management) do
			desc "The total size of buffers used by local (UNIX-domain) connections between processes inside the system (such as connections to a local database server) and send buffers of UDP and other datagram protocols."
		end
		
		newproperty(:dgramrcvbuf, :required_features => :resource_management) do
			desc "The total size of buffers used to temporary store the incoming packets of UDP and other datagram protocols."
		end
		
	end
end
