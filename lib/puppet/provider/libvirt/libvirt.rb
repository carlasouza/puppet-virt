require 'libvirt'
Puppet::Type.type(:virt2).provide(:libvirt) do

        desc "   -v, --hvm: full virtualization, 
                -p, --paravirt: paravirtualizatoin"

        commands :install => "/usr/bin/virt-install"

        def create
                p "*** Create"
                @memory=512 # get it from manifest
                @path="path=/local/carla/gsoc/vm10.qcow2" #get it from manifest

                install "--name", @resource[:name],"--ram",@memory, "--disk" ,@path,"--import","--noautoconsole","--force"
        end

        def destroy
                p "** Destroy"
        end

        def exists?
                p "** Exists?"
                @@conn = Libvirt::open("qemu:///session")
                all = @@conn.list_domains + @@conn.list_defined_domains
                p @resource[:name]
                p all.include? @resource[:name]
                all.include? @resource[:name]
        end

end
~              
