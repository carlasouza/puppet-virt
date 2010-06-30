require 'libvirt'

Puppet::Type.type(:virt).provide(:libvirt) do

	commands :install => "/usr/bin/virt-install"

	defaultfor :operatingsystem => [:debian, :ubuntu]

	def create
		Puppet.debug "Creating a new virtual machine " % [@resource[:name]]

		@virt_parameter = case @resource[:virt_type]
					when :xen_fullyvirt then "--hvm" #must validate kernel support
					when :xen_paravirt then "--paravirt" #Must validate kernel support
					when :kvm then "--accelerate" #must validate hardware support
					else "Invalid value" #raise something here
		end

		Puppet.debug "VM type: %s" % [@resource[:virt_type]]

		@path="path=".concat(@resource[:virt_path])

#		begin
			install "--name", @resource[:name], "--ram", @resource[:memory], "--disk" , @path, "--import", "--noautoconsole", "--force", @virt_parameter
#		rescue Puppet::ExecutionFailure => e
#			#Should I catch this exception here?
#		end

	end

	def destroy #Changing ensure to absent
		Puppet.debug "Trying to destroy the virtual machine %s" % [@resource[:name]]

		@conn = Libvirt::open("qemu:///session")
		@dom = @conn.lookup_domain_by_name(@resource[:name])
		begin
			@dom.destroy
		rescue Libvirt::Error => e
			Puppet.debug "Machine %s already Stopped" % [@resource[:name]]
		end
		@dom.undefine

	end

	def stopvm
		Puppet.debug "Stopping VM %s" % [@resource[:name]]
		#desc Stop the virtual machine

		# TODO if exists? and is running
		#   start
		# else create and stop
		
		@conn = Libvirt::open("qemu:///session")
		@dom = @conn.lookup_domain_by_name(@resource[:name])
#		@dom.shutdown #Sometimes it doesn't shutdown :(
		@dom.destroy
	end

	def startvm
		Puppet.debug "Starting VM %s" % [@resource[:name]]
		# Start the virtual machine only if it is stopped (duh)

		# TODO if exists? and is stopped
		#    start
		# else create

		@conn = Libvirt::open("qemu:///session")
		@dom = @conn.lookup_domain_by_name(@resource[:name])
		@dom.create		
	end

	def exists?

		@conn = Libvirt::open("qemu:///session")

		# Ugly way
		# all = @@conn.list_domains + @@conn.list_defined_domains
		# p @resource[:name] 
		# p all.include? @resource[:name]
		# all.include? @resource[:name]

		# Beautifull way
		begin
			@dom = @conn.lookup_domain_by_name(@resource[:name])
			Puppet.debug "VM %s exists? true" % [@resource[:name]]
			true
		rescue Libvirt::RetrieveError => e
			Puppet.debug "VM %s exists? false" % [@resource[:name]]
			false # The vm with that name doesnt exist
		end
	end

	#running | stopped | installed | absent,				
	def status

		p "** Status"
		@conn = Libvirt::open("qemu:///session")
		if exists? 
			# 1 = running, 3 = paused|suspend|freeze, 5 = stopped 
			if @conn.lookup_domain_by_name(@resource[:name]).info.state != 5
				Puppet.debug "VM %s status: running" % [@resource[:name]]
				return "running"
			else
				Puppet.debug "VM %s status: stopped" % [@resource[:name]]
				return "stopped"
			end
		else
			Puppet.debug "VM %s status: absent" % [@resource[:name]]
			return "absent"
		end

	end
end
