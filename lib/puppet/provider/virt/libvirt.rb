Puppet::Type.type(:virt).provide(:libvirt) do
	desc "Creates a new Xen (fully or para-virtualized), KVM, or OpenVZ guest using libvirt."
        # Ruby-Libvirt API Reference: http://libvirt.org/ruby/api/index.html

	commands :virtinstall => "/usr/bin/virt-install"
	commands :virsh => "/usr/bin/virsh"
	commands :grep => "/bin/grep"
	commands :ip => "/sbin/ip"

	# The provider is chosen by virt_type, not by operating system
	confine :feature => :libvirt

	#defaultfor @resource[:virt_type] => [:xen_fullyvirt, :xen_paravirt, :kvm, :openvz]

	# Executes operation over guest
	def exec
		hypervisor = case resource[:virt_type]
			when :openvz then "openvz:///system"
			else "qemu:///session"
		end
		conn = Libvirt::open(hypervisor)
		@guest = conn.lookup_domain_by_name(resource[:name]) 
		ret = yield if block_given?
		conn.close
		return ret
	end

	# Import the declared image file as a new domain.
	def install(bootoninstall = true)
		debug "Installing new vm"
		debug "Boot on install: %s" % bootoninstall

		if resource[:xml_file]
			xmlinstall
		else
			debug "Virtualization type: %s" % [resource[:virt_type]]
			virtinstall generalargs(bootoninstall) + network + graphic + bootargs
		
		end

		resource.properties.each do |prop|
			if self.class.supports_parameter? :"#{prop.to_s}" and prop.to_s != 'ensure'
				eval "self.#{prop.to_s}=('#{prop.should}')"
			end
		end

	end

	def generalargs(bootoninstall)
		debug "Building general arguments"

		virt_parameter = case resource[:virt_type]
			when :xen_fullyvirt then "--hvm" #must validate kernel support
			when :xen_paravirt then "--paravirt" #Must validate kernel support
			when :kvm then "--accelerate" #Must validate hardware support
		end

		arguments = ["--name", resource[:name], "--ram", resource[:memory], "--vcpus" , resource[:cpus], "--noautoconsole", "--force", virt_parameter]

		if !bootoninstall
			arguments << "--noreboot"
		end
		
		arguments << diskargs

		if File.exists?(resource[:virt_path].split('=')[1])
			if resource[:pxe]
				warnonce("Ignoring PXE boot. Domain image already exists")
			end		
			debug "File already exists. Importing domain"
			arguments << "--import"
		elsif resource[:pxe]
			debug "Creating new domain. Using PXE"
			# Only works with hvm virtualization
			arguments << "--pxe" 
		else
			fail "Only existing domain images importing and PXE boot are supported."

			# Future work
			# ["--location", resource[:boot_location]] #initrd+kernel location

		end

		arguments
	end

	def diskargs
		args = []
		parameters = ""

		if resource[:virt_path]
			parameters = resource[:virt_path]
		end
		if resource[:disk_size]
			parameters.concat("," + resource[:disk_size])
		end
		if !parameters.nil?
			args = ["--disk", parameters]
		end
		args
	end

	# Additional boot arguments
	def bootargs
		debug "Bootargs"

		bootargs = []
		if !resource[:kickstart].nil? #kickstart support
			bootargs = ["-x", resource[:kickstart]]
		end
		bootargs
	end

	# Creates network arguments for virt-install command
	def network

		debug "Network paramentrs"
		network = []
		iface = resource[:interfaces]
		if iface.nil? 
			network = ["--network", "network=default"]
		elsif iface == "disable"
			network = ["--nonetworks"]
		else
			iface.each do |iface|
				if interface?(iface)	
					network << ["--network","bridge="+iface]
				end
			end
		end
		
		macs = resource[:macaddrs]
		if macs
			resource[:macaddrs].each do |macaddr|
				#FIXME -m is decrepted
				network << "-m"
				network << macaddr
			end
		end

		return network
	end

	# Auxiliary method. Checks if declared interface exists.
	def interface?(ifname)

		ip('link', 'list',  ifname)
		rescue Puppet::ExecutionFailure
			warnonce("Network interface " + ifname + " does not exist")

	end

	# Setup the virt-install graphic configuration arguments
	def graphic

		opt = resource[:graphics]
		case opt
			when :enable || nil then args = ["--vnc"]
			when :disable then args = ["--nographics"]
			else args = ["--vncport=" + opt.split(':')[1]]
		end
		args

  end

	# Install guests using virsh with xml when virt-install is still not yet supported.
        # Libvirt XML <domain> specification: http://libvirt.org/formatdomain.html
	def xmlinstall

		if !File.exists?(resource[:xml_file])
			debug "Creating the XML file: %s " % resource[:xml_file]

			case resource[:virt_type]
				when :openvz then
					debug "Detected hypervisor type: %s " % resource[:virt_type]
					tmplcache = resource[:tmpl_cache]
					xargs = "-c openvz:///system define --file "
					if !tmplcache.nil?
						require "erb"
						xmlovz = File.new(resource[:xml_file], APPEND)
						xmlwrite = ERB.new("puppet-virt/templates/ovz_xml.erb")
						xmlovz.puts = xmlwrite.result
						xmlovz.close
					else
						fail("OpenVZ Error: No template cache define!")
					end
				else debug "Detected hypervisor type: %s " % resource[:virt_type]
					xargs = "-c qemu:///session define --file "
					require "erb"
					xmlqemu = File.new(resource[:xml_file], APPEND)
					xmlwrite = ERB.new("puppet-virt/templates/qemu_xml.erb")
					xmlqemu.puts = xmlwrite.result
					xmlqemu.close
				end
	
			debug "Creating the domain: %s " % [resource[:name]]
			virsh xargs + resource[:xml_file]
		else
			fail("Error: XML already exists on disk " + resource[:xml_file] + "." )	
		end
	end

	# Changing ensure to absent
	def destroy #Changing ensure to absent

		debug "Trying to destroy domain %s" % [resource[:name]]

		begin
			exec { @guest.destroy }
		rescue Libvirt::Error => e
			debug "Domain %s already Stopped" % [resource[:name]]
		end
		exec { @guest.undefine } 

	end


	# Creates config file if absent, and makes sure the domain is not running.
	def stop

		debug "Stopping domain %s" % [resource[:name]]

		if !exists?
			install(false)
		elsif status == :running
			case resource[:virt_type]
         			when :kvm,:qemu then exec { @guest.destroy }
				else exec { @guest.shutdown }
			end
		end

	end


	# Creates config file if absent, and makes sure the domain is running.
	def start

		debug "Starting domain %s" % [resource[:name]]

		if exists? && status != :running
			exec { @guest.create }
		elsif status == :absent
			install
		end

	end

	# Auxiliary method to make sure the domain exists before change it's properties.
			#dom.create # Start the domain
			#dom.create # Start the domain
	def setpresent
		case resource[:ensure]
			when :absent then return #do nothing
			when :running then install(true)
			else install(false)
		end
	end

	# Check if the domain exists.
	def exists?
		begin
			exec
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
			if resource[:ensure].to_s == :installed
				return :installed
			elsif exec { @guest.info.state } != 5
				debug "Domain %s status: running" % [resource[:name]]
				return :running
			else
				debug "Domain %s status: stopped" % [resource[:name]]
				return :stopped
			end
		else
			debug "Domain %s status: absent" % [resource[:name]]
			return :absent
		end

	end

	# Is the domain autostarting?
	def autoboot

		if !exists?
			setpresent
		end
	
		return exec { @guest.autostart.to_s }

	end


	# Set true or false to autoboot property
	def autoboot=(value)
		debug "Setting autoboot %s at domain %s." % [resource[:autoboot], resource[:name]]
		begin
			# FIXME
			if value.to_s == "false"
				exec { @guest.autostart=(false) }
			else
				exec { @guest.autostart=(true) }
			end
		rescue Libvirt::RetrieveError => e
			debug "Domain %s not defined" % [resource[:name]]
		end

	end

	# Not implemented by libvirt yet
	def on_poweroff

		path = "/etc/libvirt/qemu/" #Debian/ubuntu path for qemu's xml files
		extension = ".xml"
		xml = path + resource[:name] + extension

		if File.exists?(xml)
			arguments =  ["poweroff", xml]
			line = ""
			debug "Line: %s" % [line]
			line = grep arguments
			return line.split('>')[1].split('<')[0]	
		else
			return :absent
		end

	end

	#
	def on_poweroff=(value)
		# Not implemented by libvirt yet
	end

	#
	def on_reboot
		# Not implemented by libvirt yet
		resource[:on_reboot]
	end

	#
	def on_reboot=(value)
		# Not implemented by libvirt yet
	end

	#
	def on_crash
		# Not implemented by libvirt yet
		resource[:on_crash]
	end

	#
	def on_crash=(value)
		# Not implemented by libvirt yet
	end

end
