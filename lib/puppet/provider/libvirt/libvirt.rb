require 'libvirt'

Puppet::Type.type(:virt).provide(:libvirt) do

	commands :install => "/usr/bin/virt-install"

	desc "-v, --hvm: full virtualization 
         -p, --paravirt: paravirtualizatoin"

	def create
		p "** Create"

		@virt_parameter = case @resource[:virt_type]
					when :xen_fullyvirt then "--hvm"
					when :xen_paravirt then "--paravirt"
					when :kvm then "--accelerate" #must validate hardware support
					else "invalid value"
		end

		p @resource[:virt_type]
		p @virt_parameter

		@path="path=".concat(@resource[:virt_path])

		install "--name", @resource[:name], "--ram", @resource[:memory], "--disk" , @path, "--import", "--noautoconsole", "--force", @virt_parameter

	end

	def destroy #set absent
		p "** Destroy"

		@@conn = Libvirt::open("qemu:///session")
		@@dom = @@conn.lookup_domain_by_name(@resource[:name])
		@@dom.destroy
		@@dom.undefine

	end

	def stopvm
		desc "" 

		# if exists? and is running
		#   start
		# else create and stop
		
		@@conn = Libvirt::open("qemu:///session")
		@@dom = @@conn.lookup_domain_by_name(@resource[:name])
		@@dom.shutdown
	end

	def startvm
		desc "Start the virtual machine only if it is stopped (duh)"

		# if exists? and is stopped
		#    start
		# else create

		@@conn = Libvirt::open("qemu:///session")
		@@dom = @@conn.lookup_domain_by_name(@resource[:name])
		@@dom.create		
	end

	def exists?

	p "** Exists?"
		@@conn = Libvirt::open("qemu:///session")

		# Ugly way
		# all = @@conn.list_domains + @@conn.list_defined_domains
		# p @resource[:name] 
		# p all.include? @resource[:name]
		# all.include? @resource[:name]

		# Beautifull way
		begin
			@@dom = @@conn.lookup_domain_by_name(@resource[:name])
			p "**** Exists?  true"
			true
		rescue Libvirt::RetrieveError => e
			p e.to_s #debug
			p "**** Exists? false"
			false # The vm with that name doesnt exist
		end
	end

	#running | stopped | installed | absent,				
	def status

		p "** Status"
		@@conn = Libvirt::open("qemu:///session")
		if exists? 
			# 1 = running, 3 = paused|suspend|freeze, 5 = stopped 
			if @@conn.lookup_domain_by_name(@resource[:name]).info.state != 5
				p "**** Status: running"
				return "running"
			else
				p "**** Status: stopped"
				return "stopped"
			end
		else
			p "**** Status: absent"
			return "absent"
		end

	end
end
