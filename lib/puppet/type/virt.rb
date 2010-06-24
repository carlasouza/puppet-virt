module Puppet
	newtype(:virt) do
		@doc = "Create a new xen or kvm guest"
	
		newparam(:desc) do
			desc "The VM description."
		end
	
		newparam(:name) do
			desc "The virtual machine name."
			isnamevar
		end

		newproperty(:ensure) do
			desc "One of \"running\", \"installed\", \"stopped\" or \"absent\".
			     - running:
			         Creates config file, and makes sure the domU is running.
			     - installed:
			         Creates config file, but doesn't touch the state of the domU.
			     - stopped:
			         Creates config file, and makes sure the domU is not running.
			     - absent:
			         Removes config file, and makes sure the domU is not running."
		
			newvalue(:installed) do
				provider.create
			end
	
			newvalue(:stopped) do
			end
	
			newvalue(:running) do
			end
	
			newvalue(:absent) do
				provider.destroy	
			end
			
			aliasvalue(:false, :stopped)
			aliasvalue(:true, :running)

			defaultto(:installed)
			
			def retrieve
				provider.status
			end
	
		end
	
		newparam(:memory) do
#			desc "The amount of memory reserved for the virtual machine.
#			      Specified in MB and is changeable."
		end
	
		newparam(:cpus) do
			desc "Changeable"
		end
	
		newparam(:arch) do
			desc "Not Changeable"
		end
	
		newparam(:clocksync) do
			desc ""
		end
	
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
		end
	
		newparam(:disk_size) do
			desc "Not changeable."
		end
	
		newproperty(:os_type) do
			desc "Not changable."
	
			newvalues(:linux, :windows, :unix, :solaris, :other)
		end
	
		newproperty(:os_variant) do
			desc ""
		end

		newproperty(:virt_type) do
			desc "Mandatory field"
			newvalues(:kvm, :xen_fullyvirt, :xen_paravirt) 
			defaultto(:xen_paravirt)
		end
		
		newparam(:interfaces) do
			desc "Network interface(s)  bridge"
		end
	
		newproperty(:on_poweroff) do
			desc ""
			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:destroy)
		end
	
		newproperty(:on_reboot) do
			desc ""
			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:preserv)
		end
	
		newproperty(:on_crash) do
			desc ""
			newvalues(:destroy, :restart, :preserv, :renamerestart)
			defaultto(:restart)
		end
		
		newproperty(:autoboot) do
			desc ""
			newvalues(:true, :false)
			defaultto(:true)
		end
	end
end
