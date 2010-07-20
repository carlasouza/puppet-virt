module Puppet
	newtype(:virt) do
		@doc = "Create a new xen or kvm guest"


		# A base class for Virt parameters validation.
		class VirtParam < Puppet::Property

			def numfix(num)
				if num =~ /^\d+$/
					return num.to_i
				elsif num.is_a?(Integer)
					return num
				else
					return false
				end
			end

			munge do |value|
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

		newparam(:memory, :parent => VirtParam) do
			desc "The maximum amount of memory allocation for the guest domain.
			      Specified in MB and is changeable."

			isrequired #FIXME Bug #4049
		end

		newparam(:cpus, :parent => VirtParam) do
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

		# Path para o kernel para realizar o boot
		newparam(:boot_kernel) do
			desc ""
		end
	
		newparam(:boot_initrd) do
			desc ""
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
			munge do |value|
				case value
				when String
					if (value =~ /.(img|qcow|qcow2)$/).nil?
						self.fail "%s is not a valid %s" % [value, self.class.name]
					end
				end
				return value
			end

		end
	
		newparam(:disk_size, :parent => VirtParam) do
			desc "Not changeable."
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
			desc "Network interface(s)  bridge"
		end
	
		newparam(:on_poweroff) do
			desc ""

			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:destroy)
		end
	
		newparam(:on_reboot) do
			desc ""

			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:preserv)
		end
	
		newparam(:on_crash) do
			desc ""

			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:restart)
		end
		
		newparam(:autoboot) do
			desc ""

			newvalues(true, false)
			defaultto(true)
			
#			def retrieve
#				provider.isautoboot?
#			end
		end

	end
end
