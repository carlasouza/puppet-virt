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

		debug "Creating a new virtual machine " % [resource[:name]]

		@virt_parameter = case resource[:virt_type]
					when :xen_fullyvirt then "--hvm" #must validate kernel support
					when :xen_paravirt then "--paravirt" #Must validate kernel support
					when :kvm then "--accelerate" #Must validate hardware support
					else "Invalid value" # FIXME Raise something here?
		end

		debug "Boot on install: %s" % bootoninstall
		debug "VM type: %s" % [resource[:virt_type]]

		@path="path=".concat(resource[:virt_path])

		arguments = ["--name", resource[:name], "--ram", resource[:memory], "--vcpus" , resource[:cpus] , "--disk" , @path, "--import", "--noautoconsole", "--force", @virt_parameter]

		if !bootoninstall
			arguments << "--noreboot"
		end
		virtinstall arguments 

	end

	# Changing ensure to absent
	def destroy #Changing ensure to absent

		debug "Trying to destroy the virtual machine %s" % [resource[:name]]

		begin
			dom.destroy
		rescue Libvirt::Error => e
			debug "Machine %s already Stopped" % [resource[:name]]
		end
		dom.undefine

	end


	# Stop the virtual machine
	def stop

		debug "Stopping VM %s" % [resource[:name]]

		if !exists?
			install(false)
		elsif status == "running"
#			dom.shutdown #FIXME Sometimes it doesn't shutdown
			dom.destroy
		end

	end


	# Start the virtual machine only if it is stopped
	def start

		debug "Starting VM %s" % [resource[:name]]

		if exists? && status == "stopped"
			dom.create # Start the vm
		else
			install
		end

	end

	#
	def exists?

		begin
			dom
			debug "VM %s exists? true" % [resource[:name]]
			true
		rescue Libvirt::RetrieveError => e
			debug "VM %s exists? false" % [resource[:name]]
			false # The vm with that name doesnt exist
		end

	end


	# running | stopped | installed | absent,				
	def status

		if exists? 
			# 1 = running, 3 = paused|suspend|freeze, 5 = stopped 
			if dom.info.state != 5
				debug "VM %s status: running" % [resource[:name]]
				return "running"
			else
				debug "VM %s status: stopped" % [resource[:name]]
				return "stopped"
			end
		else
			debug "VM %s status: absent" % [resource[:name]]
			return "absent"
		end

	end


	def isautoboot?
		dom.autostart
	end


	# FIXME not working yet
	def autoboot
		debug "VM trying to set autoboot: %s" % [resource[:autoboot]]
		begin
			dom.autostart=(resource[:autoboot])
		rescue Exception => e
			debug "VM %s not defined" % [resource[:name]]
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
