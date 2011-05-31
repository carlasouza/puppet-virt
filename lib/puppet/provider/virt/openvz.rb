require 'facter/util/plist'
Puppet::Type.type(:virt).provide(:openvz) do
	desc "Manages OpenVZ guests."
        # More information about OpenVZ at: openvz.org

	commands :vzctl  => "/usr/sbin/vzctl"
	commands :vzlist => "/usr/sbin/vzlist"
	commands :mkfs   => "/sbin/mkfs"

#	if [ "Ubuntu", "Debian" ].any? { |os|  Facter.value(:operatingsystem) == os }
#		:vzcache => "/var/lib/vz/template/cache"
#		:vzconf => "/etc/vz/conf/"
#	else
#		:vzcache => ""
#		:vzconf => ""
#	end

	class VzConfigProperty < Puppet::Property
		def retrieve
			#get from vzconf / ctid.conf file
		end

		def sync
			#map parameter -> conf parameter name
		end
	end


	# TODO if openvz module is up
	#confine :true => 
	
	#Must return all host's guests
	# FIXME ensure it works
	def self.instances
		guests = []
		execpipe "#{vzlist} -a" do |process|
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

	# private method to download openvz template
	def download full_url, to_here
		require 'open-uri'
		writeOut = open(to_here, "wb")
		writeOut.write(open(full_url).read)
		writeOut.close
	end

	# If CTID not specified, it will assign the first possible value
	# Note that CT ID <= 100 are reserved for OpenVZ internal purposes.
	def ctid
		id = resource[:ctid]
		if tmp = vzlist('-a','-N',resource[:name]).split(" ")[5]
			id = tmp
		else
			out = vzlist('-a', '-o','ctid')
			tmp = Integer(out.split(' ')[1])
			if tmp <= 100
				id = 101
			else
				id = tmp+1
			end
		end
		if id
			return id
		else
			fail "CTID not specified"
		end

	end

	def install
		#dev = "/dev/#{resource[:vgname]}/#{resource[:lvname]}"
		#scratch dev if resource[:scratchdevice]
		#mkfs '-t', resource[:fstype], "/dev/#{resource[:vgname]}/#{resource[:lvname]}"

		if resource[:os_variant].nil?
			fail "OS variant is required"
		end

		args = [ 'create', ctid, '--ostemplate', ostemplate ]
		if priv = resource[:private]
			args << '--private' << priv
		end
		
		if hn = resource[:name]
#		if hn = resource.should(:name)
			args << '--hostname' << hn
			args << '--name' << hn
		end
		vzctl args

#		args = [ 'set', ctid, '--save' ]
#		if nss = resource.should(:nameserver)
#			[nss].flatten.each do |ns|
#				args << '--nameserver' << ns
#			end
#		end
#		if ips = resource.should(:ipaddr)
#			[ips].flatten.each do |ip|
#				args << '--ipadd' << ip
#			end
#		end
#		if sds = resource[:searchdomain]
#			[sds].flatten.each do |sd|
#				args << '--searchdomain' << sd
#			end
#		end
#		vzctl args
#
		if resource[:ensure] == :running
			vzctl 'start', ctid
		end
	end

	def setpresent
		case resource[:ensure]
			when :absent then return #do nothing
			else install
		end
	end


	def destroy
		#dev = "/dev/#{@resource[:vgname]}/#{@resource[:lvname]}"
		#lvremove '--force', "#{@resource[:vgname]}/#{@resource[:name]}"
		#scratch dev if @resource[:scratchdevice]
      if status == "running"
			vzctl 'stop', ctid
		end
		vzctl 'destroy', ctid
	#	File.unlink("/etc/vz/conf/#{resource[:ctid]}.conf.destroyed")
	end

	def purge
	end

   def stop
      if !exists?
			install
		elsif status == "running"
			vzctl 'stop', ctid
		end
   end

   def start
      if exists? && status != "running"
			vzctl 'start', ctid
		elsif status == "absent"
			install
		end
   end

	def exists?
		stat = vzctl('status', ctid).split(" ")
		if stat.nil? || stat[2] == "deleted"
			return false
		else
			return true
		end
	end

	# exist, deleted, mouted, umounted, running, down
	# running | stopped | absent
   def status

		stat = vzctl('status', ctid).split(" ")
      if exists?
         if resource[:ensure].to_s == "installed"
            return ":installed"
         elsif stat[4] == "running"
            return ":running"
			elsif stat[4] == "down"
            return ":stopped"
			else 
				return ":absent"
         end
      else
         debug "Domain %s status: absent" % [resource[:name]]
			debug resource.should(:ensure)
         return ":absent"
      end
   end
	
#	VE_ARGS = [ ":onboot", ":userpasswd", ":disabled", ":name", ":description", ":setmode", ":ipadd", ":ipdel", ":hostname", ":nameserver", ":searchdomain", ":netid_add", ":netif_del", ":mac", ":nost_ifname", ":host_mac", ":bridge", ":mac_filter", ":numproc", ":numtcpsock", ":numothersock", ":vmguardpages", ":kmemsize", ":tcpsndbuf", ":tcprcvbuf", ":othersockbuf", ":dgramrcvbuf", ":oomguarpages", ":lockedpages", ":privvmpages", ":shmpages", ":numfile", ":numflock", ":numpty", ":numsiginfo", ":dcachesize", ":numiptent", ":physpages", ":cpuunits", ":cpulimit", ":cpus", ":meminfo", ":iptables", ":netdev_add", ":netdev_del", ":diskspace", ":discinodes", ":quotatime", ":quotaugidlimit", ":noatime", ":capability", ":devnodes", ":devices", ":features", ":applyconfig", ":applyconfig_map", ":ioprio" ]

	SET_PARAMS = ["name", "capability", "applyconfig", "applyconfig_map", "iptables", "features", "searchdomain", "hostname", "onboot", "disabled", "noatime", "setmode", "userpasswd", "nameserver", "ipadd", "ipdel", "cpuunits", "cpulimit", "quotatime", "quotaugidlimit", "ioprio", "cpus", "netif_add", "netif_del", "diskspace", "diskinodes", "devices", "devnodes"]

	SET_PARAMS.each do |arg|
		define_method(arg.to_s.downcase) do
			get_value(arg)
		end
	
		define_method("#{arg}=".downcase) do |value|
			vzctl('set', ctid, "--#{arg}", value, "--save")
		end
	end

	# private method
	def get_value(arg)
		debug "Getting parameter #{arg} value"
		conf = "/etc/vz/conf/" << ctid << ".conf"
		value = open(conf).grep(/^#{arg.upcase}/)
		value[0].split('"')[1]
	end

#	class IPProperty < Puppet::Property
#		def ipsplit(str)
#			interface, address, defrouter = str.split(':')
#			return interface, address, defrouter
#		end
#	end

end
