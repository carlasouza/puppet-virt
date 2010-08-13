module Puppet
	newtype(:virt) do
		@doc = "Create a new xen or kvm guest"


		# A base class for Virt parameters validation.
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
			desc "One of \"running\", \"installed\", \"stopped\" or \"absent\".
			     - running:
			         Creates config file, and makes sure the domU is running.
			     - installed:
			         Creates config file, but doesn't touch the state of the domU.
			     - stopped:
			         Creates config file, and makes sure the domU is not running.
			     - absent:
			         Removes config file, and makes sure the domU is not running."
		
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
			desc "The VM description."
		end
	
		newparam(:name, :namevar => true) do
			desc "The virtual machine name."
		end

		# This will change to properties
		newparam(:memory, :parent => VirtNumericParam) do
			desc "The maximum amount of memory allocation for the guest domain.
			      Specified in MB and is changeable."

			isrequired #FIXME Bug #4049
		end

		newparam(:cpus, :parent => VirtNumericParam) do
			desc "Number of virtual CPUs active in the guest domain.
					This value is changeable"

			defaultto(1)
		end
	
		newparam(:arch) do
			desc "Not Changeable"

			newvalues("i386","amd64","ia64","powerpc","hppa")
		end
	
		newparam(:clocksync) do
			desc ""

			newvalues("UTC", "localtime", "timezone", "variable")
		end
	

		# Instalation method

		# Location of kernel+initrd pair

		newparam(:boot_location) do
			desc "Installation source for guest virtual machine kernel+initrd pair.  The 'url' can take one of the following forms:

			DIRECTORY
             Path to a local directory containing an installable distribution image

         nfs:host:/path or nfs://host/path
             An NFS server location containing an installable distribution image

         http://host/path
             An HTTP server location containing an installable distribution image

         ftp://host/path
             An FTP server location containing an installable distribution image"

		end

		newparam(:boot_options) do
			desc ""
		end

		newparam(:virt_path) do
			desc "Path do disk image file. This field is mandatory.
					Initially only import existing disk is available.
					Image files must end with *.img, *.qcow or *.qcow2"

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
			desc "Not changeable."

			munge do |value|
				"size=" + value
			end

		end

	
		# VM parameters 
		
		newparam(:os_type) do
			desc "Not changable."

			newvalues(:linux, :windows, :unix, :solaris, :other)
		end
	
		newparam(:os_variant) do
			desc ""
		end

		newparam(:virt_type) do
			desc "Mandatory field"

			isrequired #FIXME Bug #4049
			newvalues(:kvm, :xen_fullyvirt, :xen_paravirt) 
#			defaultto(:xen_paravirt)
		end
		
		newparam(:interfaces) do
			desc "Network interface(s)"

			validate do |value|
				unless value.is_a?(Array) or value.is_a?(String)
					self.devfail "Ignore must be a string or an Array"
				end
			end
		end
	
		newproperty(:on_poweroff) do
			desc ""

			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:destroy)

		end
	
		newproperty(:on_reboot) do
			desc ""

			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:restart)

		end
	
		newproperty(:on_crash) do
			desc ""

			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:restart)

		end
		
		newproperty(:autoboot) do
			desc ""

			newvalue(true)
			newvalue(false)

		end

	end
end
