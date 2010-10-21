module Puppet
	newtype(:virt) do
		@doc = "Manages virtual machines using the 'libvirt' hypervisor management library. The guests may be imported using an existing image, configured to use one or more virtual disks, network interfaces and other options which we haven't included yet. Create a new xen, kvm or openvz guest."

		feature :buildable, "The provider can build a new guest from scratch",
			:methods => [:build]
		
		feature :importable, "The provider can import and existing guest image",
			:methods => [:import]

		feature :livemigrable, "The provider supports live migration",
			:methods => [:migrate]

		# A base class for numeric Virt parameters validation.
		class VirtNumericParam < Puppet::Parameter

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


		ensurable do
			desc "The guest's ensure field can assume one of the following values:
	`running`:
		Creates config file, and makes sure the domain is running.
	`installed`:
		Creates config file, but doesn't touch the state of the domain.
	`stopped`:
		Creates config file, and makes sure the domain is not running.
	`absent`:
		Removes config file, and makes sure the domain is not running."
		
			newvalue(:stopped) do
				provider.stop
			end
	
			newvalue(:running) do
				provider.start
			end

			newvalue(:installed) do
				provider.setinstalled
			end

			newvalue(:absent) do
				provider.destroy
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

		# This will change to properties
		newparam(:memory, :parent => VirtNumericParam) do
			desc "The maximum amount of memory allocation for the guest domain.
			      Specified in MB."

			isrequired #FIXME Bug #4049
		end

		newparam(:cpus, :parent => VirtNumericParam) do
			desc "Number of virtual CPUs active in the guest domain."

			defaultto(1)
		end
	
		newparam(:graphic) do
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
	
		newparam(:disk_size, :parent => VirtNumericParam) do
			desc "Size (in GB) to use if creating new guest storage. Not changeable."

			munge do |value|
				"size=" + value
			end

		end

	
		# VM parameters 
		
		newparam(:os_type) do
			desc "Optimize the guest configuration for a type of operating system (ex. 'linux', 'windows'). Not changable."

			newvalues(:linux, :windows, :unix, :solaris, :other)
		end
	
		newparam(:os_variant) do
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
		When defining an OpenVZ container, the template cache to be used must be defined using tmpl_cache and you must explicitly specify the use of openvz with this attribute (for now)."

			isrequired #FIXME Bug #4049
			newvalues(:kvm, :xen_fullyvirt, :xen_paravirt, :qemu, :openvz) 
		end

		newparam(:tmpl_cache) do
			desc "When using OpenVZ this defines the os template cache file to be used (ex. 'debian-5.0-i386-minimal', 'fedora-13-x86_64')."

		end

		newparam(:xml_path) do
			desc "This is the path to a predefined xml config file, to be used with the import function."

			munge do |value| 
				"path=" + value
			end

		end
		
		newparam(:interfaces) do
			desc " Connect the guest network to the host using the specified network as a bridge. The value can take one of 2 formats:
	`disable`:
		The guest will have no network.
	`[ \"ethX\", ... ] | \"ethX\" `
		The guest can receive one or an array with interface's name from host to connect to the guest interfaces.
	If the specified interfaces does not exist, it will be ignored and raises a warning."

			validate do |value|
				unless value.is_a?(Array) or value.is_a?(String)
					self.devfail "interfaces field must be a String or an Array"
				end
			end
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
			defaultto(:destroy)

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
			defaultto(:restart)

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
			defaultto(:restart)

		end
		
		newproperty(:autoboot) do
			desc "Determines if the guest should start when the host starts."

			newvalue(true)
			newvalue(false)

		end

	end
end
