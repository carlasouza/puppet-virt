require 'facter/util/plist'
Puppet::Type.type(:virt).provide(:openvz) do
	desc "Manages OpenVZ guests."
        # More information about OpenVZ at: openvz.org

	commands :vzctl  => "/usr/sbin/vzctl"
	commands :vzlist => "/usr/sbin/vzlist"
	commands :mkfs   => "/sbin/mkfs"

#	confine :true => modulo openvz up
	#defaultfor resource[:virt_type] => [:openvz]

	def self.instances
		guests = []
		vzlist = which('vzlist') or return []
		execpipe "#{vzlist} -a" do |process| #FIXME ensure it works
			process.collect do |line|
				next unless options = parse(line)
				guests << new(options)
			end
		end
		guests
	end

	def ostemplate 
		resource[:os_variant]
		arch = resource[:arch].nil? ? Facter.value(:architecture) : resource[:arch]
		arch = case arch.to_s
				 #when "i386","i686" then "x86"
				 when "amd64","ia64","x86_64" then "x86_64"
				 else "x86"
			 end

		return resource[:os_variant] + "-" + arch
	end

	def install
		#dev = "/dev/#{resource[:vgname]}/#{resource[:lvname]}"
		#scratch dev if resource[:scratchdevice]
		#mkfs '-t', resource[:fstype], "/dev/#{resource[:vgname]}/#{resource[:lvname]}"

		if resource[:os_variant].nil?
			fail "OS variant not specified"
		end


		args = [ 'create', resource[:ctid], '--ostemplate', ostemplate ]
		if priv = resource[:private]
			args << '--private' << priv
		end
		if hn = resource.should(:name)
			args << '--hostname' << hn
		end
		if nm = resource.should(:name)
			args << '--name' << nm
		end
		vzctl args

		args = [ 'set', resource[:ctid], '--save' ]
		if nss = resource.should(:nameserver)
			[nss].flatten.each do |ns|
				args << '--nameserver' << ns
			end
		end
		if ips = resource.should(:ipaddr)
			[ips].flatten.each do |ip|
				args << '--ipadd' << ip
			end
		end
		if sds = resource[:searchdomain]
			[sds].flatten.each do |sd|
				args << '--searchdomain' << sd
			end
		end
		vzctl args
		if resource.should(:status) == :running
			vzctl 'start', resource[:id]
		end
	end

	def destroy
		#dev = "/dev/#{@resource[:vgname]}/#{@resource[:lvname]}"
		#lvremove '--force', "#{@resource[:vgname]}/#{@resource[:name]}"
		#scratch dev if @resource[:scratchdevice]
      if status == "running"
			vzctl 'stop', resource[:ctid]
		end
		vzctl 'destroy', resource[:ctid]
	#	File.unlink("/etc/vz/conf/#{resource[:ctid]}.conf.destroyed")
	end

	def purge
	end

   def stop
      if status == "running"
			vzctl 'stop', resource[:ctid]
      end
   end

   def start
		if status == "stopped"
			vzctl 'start', resource[:ctid]
      end
   end

	def exists?
		stat = vzctl('status', resource[:ctid]).split(" ")
		if stat.nil? || stat[2] == "deleted"
			return false
		else
			return true
		end
	end

	# exist, deleted, mouted, umounted, running, down
	# running | stopped | absent
   def status
		stat = vzctl('status', resource[:ctid]).split(" ")
      if exists?
         if resource[:ensure].to_s == "installed"
            return "installed"
         elsif stat[4] == "running"
            return "running"
			elsif stat[4] == "down"
            return "stopped"
			else 
				return "absent"
         end
      else
         debug "Domain %s status: absent" % [resource[:name]]
         return "absent"
      end
   end

#	VE_ARGS = [ "onboot", "root", "userpasswd", "disabled", "name", "description", "setmode", "ipadd", "ipdel", "hostname", "nameserver", "searchdomain", "netid_add", "netif_del", "mac", "nost_ifname", "host_mac", "bridge", "mac_filter", "numproc", "numtcpsock", "numothersock", "vmguardpages", "kmemsize", "tcpsndbuf", "tcprcvbuf", "othersockbuf", "dgramrcvbuf", "oomguarpages", "lockedpages", "privvmpages", "shmpages", "numfile", "numflock", "numpty", "numsiginfo", "dcachesize", "numiptent", "physpages", "cpuunits", "cpulimit", "cpus", "meminfo", "iptables", "netdev_add", "netdev_del", "diskspace", "discinodes", "quotatime", "quotaugidlimit", "noatime", "capability", "devnodes", "devices", "features", "applyconfig", "applyconfig_map", "ioprio" ]
#
#	VE_ARGS.each do |arg|
#		define_method(arg.to_s.downcase) do
#			state_values[arg]
#		end
#	
#		define_method("#{arg}=".downcase) do |value|
#			vzctl('set', resource[:name], "--#{arg}", value, "--save")
#			state_values[arg] = value
#		end
#	end
end
