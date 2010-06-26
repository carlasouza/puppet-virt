require 'libvirt'
Puppet::Type.type(:virt2).provide(:libvirt) do

        commands :install => "/usr/bin/virt-install"

        desc "  -v, --hvm: full virtualization 
                -p, --paravirt: paravirtualizatoin"

        def create
                p "*** Create"
                @memory=512 # get it from manifest
                @path="path=/local/carla/gsoc/vm10.qcow2" #get it from manifest

                install "--name", @resource[:name],"--ram", @resource[:memory], "--disk" ,@path,"--import","--noautoconsole","--force"
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
                rescue Exception => e
                        false # The vm with that name doesnt exist
                end
        end
end
