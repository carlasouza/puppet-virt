require 'libvirt'
Puppet::Type.type(:virt).provide(:libvirt) do
	desc "Libvirt provider"
	
	defaultfor :operatinsystem => [:debian, :ubuntu]

	def create
		p "created"
	end

	def destroy
		p "destroied"
	end

	def status 
		@@conn = Libvirt::open("qemu:///session")
                all = @@conn.list_domains + @@conn.list_defined_domains
                p all.include? @resource[:name] #debuging
		all.include? @resource[:name]
	end
	
	def virt_type
	end

end
