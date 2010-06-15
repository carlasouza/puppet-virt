Puppet::Type.newtype(:xen_fullyvirt) do
	@doc = "Create a new xen fullyvirtualizated guest"

	newproperty(:desc) do
		desc "The VM description."
	end

	newproperty(:memory) do
		desc " "
	end

	newproperty(:cpus) do
		desc " "
	end

	newproperty(:arch) do
		desc " "
	end

	newproperty(:clocksync) do
		desc " "
	end

	newproperty(:install_kernel) do
		desc " "
	end

	newproperty(:install_initrd) do
		desc " "
	end

	newproperty(:install_options) do
		desc " "
	end

	newproperty(:virt_path) do
		desc " "
	end

	newproperty(:disk_size) do
		desc " "
	end

	newproperty(:os_type) do
		desc " "
	end

	newproperty(:os_variant) do
		desc " "
	end

	newproperty(:provider) do
		desc " "
	end

	newproperty(:interfaces) do
		desc " "
	end

	newproperty(:ensure) do
		desc " "
	end

	newproperty(:on_poweroff) do
		desc " "
		defaultto :destroy

		newvalue :destroy
		newvalue :restart
		newvalue :preserv
		newvalue :remame_restart

	end

	newproperty(:on_reboot) do
		desc " "
		defaultto :restart

		newvalue :destroy
		newvalue :restart
		newvalue :preserv
		newvalue :remame_restart
	end

	newproperty(:on_crash) do
		desc " "
		defaultto :restart

		newvalue :destroy
		newvalue :restart
		newvalue :preserv
		newvalue :remame_restart 
	end

	newproperty(:autoboot) do
		desc " "

		newvalue(:true)
		newvalue(:false)
	end
end
