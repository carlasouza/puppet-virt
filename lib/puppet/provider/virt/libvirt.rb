Puppet::Type.type(:virt).provide(:libvirt) do
	@doc = ""

	commands :virtinstall => "/usr/bin/virt-install"

	# The provider is choosed by virt_type, not by operating system
#	defaultfor :operatingsystem => [:debian, :ubuntu] 
	
	confine :feature => :libvirt

	# 
	def dom
		Libvirt::open("qemu:///session").lookup_domain_by_name(resource[:name])
	end

	#
	def install(bootoninstall = true)

		debug "Creating a new domain %s " % [resource[:name]]

		@virt_parameter = case resource[:virt_type]
					when :xen_fullyvirt then "--hvm" #must validate kernel support
					when :xen_paravirt then "--paravirt" #Must validate kernel support
					when :kvm then "--accelerate" #Must validate hardware support
					else "Invalid value" # FIXME Raise something here?
		end

		debug "Boot on install: %s" % bootoninstall
		debug "Virtualization type: %s" % [resource[:virt_type]]

		@path="path=".concat(resource[:virt_path])

		arguments = ["--name", resource[:name], "--ram", resource[:memory], "--vcpus" , resource[:cpus] , "--disk" , @path, "--import", "--noautoconsole", "--force", @virt_parameter]

		if !bootoninstall
			arguments << "--noreboot"
		end

		virtinstall arguments 

	end

	# Changing ensure to absent
	def destroy #Changing ensure to absent

		debug "Trying to destroy domain %s" % [resource[:name]]

		begin
			dom.destroy
		rescue Libvirt::Error => e
			debug "Domain %s already Stopped" % [resource[:name]]
		end
		dom.undefine

	end


	# Creates config file if absent, and makes sure the domain is not running.
	def stop

		debug "Stopping domain %s" % [resource[:name]]

		if !exists?
			install(false)
		elsif status == "running"
#			dom.shutdown #FIXME Sometimes it doesn't shutdown
			dom.destroy
		end

	end


	# Creates config file if absent, and makes sure the domain is running.
	def start

		debug "Starting domain %s" % [resource[:name]]

		if exists? && status == "stopped"
			dom.create # Start the domain
		else
			install
		end

	end


	# Creates config file if absent, but doesn't touch the domain's state.
	# FIXME I dont like this method name
	def setinstalled

		debug "Checking if the domain %s already exists." % [resource[:name]]

		if !exists?
			install(false)
		end

	end

	# Check if the domain exists.
	def exists?

		begin
			dom
			debug "Domain %s exists? true" % [resource[:name]]
			true
		rescue Libvirt::RetrieveError => e
			debug "Domain %s exists? false" % [resource[:name]]
			false # The vm with that name doesnt exist
		end

	end


	# running | stopped | absent,				
	def status

		if exists? 
			# 1 = running, 3 = paused|suspend|freeze, 5 = stopped 
			if dom.info.state != 5
				debug "Domain %s status: running" % [resource[:name]]
				return "running"
			else
				debug "Domain %s status: stopped" % [resource[:name]]
				return "stopped"
			end
		else
			debug "Domain %s status: absent" % [resource[:name]]
			return "absent"
		end

	end


	def isautoboot?
		dom.autostart
	end


	# FIXME not working yet
	def autoboot

		debug "Trying to set autoboot %s at domain." % [resource[:autoboot]]

		begin
			dom.autostart=(resource[:autoboot])
		rescue Exception => e
			debug "Domain %s not defined" % [resource[:name]]
		end

	end

	#
#	def on_poweroff
#	end

	#
#	def on_reboot
#	end

	#
#	def on_crash
#	end

end
