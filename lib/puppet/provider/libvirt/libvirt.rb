require 'libvirt'

class Util

        @conn

        def connect
                @conn = Libvirt::open("qemu:///session")
        end

        def isRunning?(name)
        #if conn != null
                @conn.list_domains.include? name
        #raise error
        end

        def isDefined?(name)
                all = @conn.list_domains + @conn.list_defined_domains
                all.include? name
        end
end
