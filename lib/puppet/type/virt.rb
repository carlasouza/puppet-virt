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
		
			defaultvalues
	
			newvalue(:stopped) do
				provider.stop
			end
	
			newvalue(:running) do
				provider.start
			end

			newvalue(:installed) do
				provider.setinstalled
			end

			aliasvalue(:present, :installed)

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
			desc "The amount of memory reserved for the virtual machine.
			      Specified in MB and is changeable."

			isrequired #FIXME Bug #4049
		end
	
		newparam(:cpus, :parent => VirtParam) do
			desc "Changeable"

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
			desc "Path to .img file"

			isrequired #FIXME Bug #4049
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
