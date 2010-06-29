require 'libvirt'
Puppet::Type.type(:virt).provide(:libvirt) do

        commands :install => "/usr/bin/virt-install"

        desc "  -v, --hvm: full virtualization 
                -p, --paravirt: paravirtualizatoin"

        def create
                p "** Create"
                @memory=512 # get it from manifest
                @path="path=".concat(@resource[:virt_path]) #get it from manifest

                install "--name", @resource[:name],"--ram", @resource[:memory], "--disk" , @path,"--import","--noautoconsole","--force"
        end

        def destroy
                p "** Destroy"
                @@conn = Libvirt::open("qemu:///session")
                @@dom = @@conn.lookup_domain_by_name(@resource[:name])
                @@dom.undefine
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
			p "**** Exists? true"
			true
                rescue Libvirt::RetrieveError => e
                        p e.to_s #debug
			p "**** Exists? false"
                        false # The vm with that name doesnt exist
                end
        end

	#running | stopped | installed | absent,				
	def status
		p "*** Status"
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
