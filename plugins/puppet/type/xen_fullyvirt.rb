Puppet::Type.newtype(:xen_fullyvirt) do
	@doc = "create a new xen fullyvirtualizated guest"

	newproperty(:desc) do
		desc "The VM description."
	end

	newproperty(:memory) do
	end

	newproperty(:cpus) do
	end

	newproperty(:arch) do
	end

	newproperty(:clocksync) do
	end

	newproperty(:install_kernel) do
	end

	newproperty(:install_initrd) do
	end

	newproperty(:install_options) do
	end

	newproperty(:virt_path) do
	end

	newproperty(:disk_size) do
	end

	newproperty(:os_type) do
	end

	newproperty(:os_variant) do
	end

	newproperty(:provider) do
	end

	newproperty(:interfaces) do
	end

	newproperty(:ensure) do
	end

	newproperty(:on_poweroff) do
	end

	newproperty(:on_reboot) do
	end

	newproperty(:on_crash) do
	end

	newproperty(:autoboot) do
		newvalue(:true)
		newvalue(:false)
	end
end
