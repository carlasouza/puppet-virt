require 'libvirt'
Puppet::Type.type(:virt).provide(:libvirt) do
	desc "Libvirt provider"
	
	defaultfor :operatinsystem => [:debian, :ubuntu]

	commands :install => "virt-install" 



	def create
		p "*** Executing provider.create"
#		install "--name", :name, " --ram ", :memory, " --disk path=",:virt_path," --import  --force"
	
		# Testing
		# err: //virttest/Virt[guestxen]/ensure: change from false to installed failed: Execution of '/usr/bin/virt-install --name "Jun24" --ram 1024 --disk path="/local/carla/gsoc/vm10.qcow2" --import  --force' returned 2: Usage: virt-install --name NAME --ram RAM STORAGE INSTALL [options]
		# virt-install: error: no such option: --name "Jun24" --ram 1024 --disk path
 		# But if I execute this line, it works
		install "--name Jun24 --ram 512 --disk path=/local/carla/gsoc/vm10.qcow2 --import"
	end

	def destroy
		p "*** Executing provider.destroy " #Debuging
		@@conn = Libvirt::open("qemu:///session")
                @@dom = @@conn.lookup_domain_by_name("Jun24")
                @@dom.undefine
	end

	def status
		p "*** Executing provider.status: " #Debuging
		@@conn = Libvirt::open("qemu:///session")
                all = @@conn.list_domains + @@conn.list_defined_domains
		p all.include? @resource[:name]
		all.include? @resource[:name]
	end
	
	def virt_type
	end

	def on_poweroff
		#<on_poweroff>
	end

	def on_reboot
		#<on_reboot>
	end

	def on_crash
		#<on_crash>
	end

	def autoboot
		@@conn = Libvirt::open("qemu:///session") #testing
                @@dom = @@conn.lookup_domain_by_name("Jun24") #testing
                @@dom.autostart = value
	end
end
