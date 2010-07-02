Puppet::Type.type(:virt).provide(:libvirt) do

	commands :virtinstall => "/usr/bin/virt-install"

	defaultfor :operatingsystem => [:debian, :ubuntu]
	
#	has_features :libvirt
	confine :feature => :libvirt

	# 
	def dom
		Libvirt::open("qemu:///session").lookup_domain_by_name(resource[:name])
	end


	#
	def install

		debug "Creating a new virtual machine " % [resource[:name]]

		@virt_parameter = case resource[:virt_type]
					when :xen_fullyvirt then "--hvm" #must validate kernel support
					when :xen_paravirt then "--paravirt" #Must validate kernel support
					when :kvm then "--accelerate" #Must validate hardware support
					else "Invalid value" # FIXME Raise something here?
		end

		debug "VM type: %s" % [resource[:virt_type]]

		@path="path=".concat(resource[:virt_path])

#		begin
			virtinstall "--name", resource[:name], "--ram", resource[:memory], "--disk" , @path, "--import", "--noautoconsole", "--force", @virt_parameter
#		rescue :ExecutionFailure => e
#			# FIXME Should I catch this exception here or raise it?
#		end

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
			install
			dom.destroy
		elsif status == "running"
#			@dom.shutdown #FIXME Sometimes it doesn't shutdown
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
end
