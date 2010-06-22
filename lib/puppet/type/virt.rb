module Puppet
	newtype(:virt) do
		@doc = "Create a new guest"
	
		newparam(:desc) do
			desc "The VM description."
		end
	
		newparam(:name) do
			desc ""
			isnamevar
		end
	
		newproperty(:ensure) do
			desc ""
		
			newvalue(:installed) do
			end
	
			newvalue(:stopped) do
			end
	
			newvalue(:running) do
			end
	
			newvalue(:absent) do
			end
			
			aliasvalue(:false, :stopped)
			aliasvalue(:true, :running)
			
			def retrieve
				return provider.status
			end
	
		end
	
		newparam(:memory) do
			desc ""
		end
	
		newparam(:cpus) do
			desc ""
		end
	
		newparam(:arch) do
			desc ""
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
			desc ""
		end
	
		newparam(:disk_size) do
			desc ""
		end
	
		newparam(:os_type) do
			desc ""
	
#			newvalue(:linux)
#			newvalue(:windows)
#			newvalue(:unix)
#			newvalue(:solaris)
#			newvalue(:other)
		end
	
		newparam(:os_variant) do
			desc ""
		end

#		newparam(:provider) do
#			desc ""
#		end	

		newproperty(:virt_type) do
			desc ""
	
			newvalue(:kvm) do
				resource[:provider] = :libvirt
			end
			newvalue(:xen_fullyvirt) do
				resource[:provider] = :libvirt
			end
			newvalue(:xen_paravirt) do
				resource[:provider] = :libvirt
			end
		end
		
		newparam(:interfaces) do
			desc ""
		end
	
		newparam(:on_poweroff) do
			desc ""
		end
	
		newparam(:on_reboot) do
			desc ""
		end
	
		newparam(:on_crash) do
			desc ""
		end
		
		newproperty(:autoboot) do
			desc ""
	
			newvalue(:true)
			newvalue(:false)
		end
	end
end
