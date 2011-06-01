require 'facter/util/plist'
Puppet::Type.type(:virt).provide(:openvz) do
	desc "Manages OpenVZ guests."
	# More information about OpenVZ at: openvz.org
	
	commands :vzctl  => "/usr/sbin/vzctl"
	commands :vzlist => "/usr/sbin/vzlist"
	commands :mkfs   => "/sbin/mkfs"

	has_feature :disabled

	# TODO if openvz module is up
	# confine :true => 
	
	if [ "Ubuntu", "Debian" ].any? { |os|  Facter.value(:operatingsystem) == os }
		@@vzcache = "/var/lib/vz/template/cache/"
		@@vzconf = "/etc/vz/conf/"
	else
		fail "Sorry, this provider is not supported for your Operation System, yet :)"
	end

	# FIXME Must return all host's guests
	def self.instances
		guests = []
		execpipe "#{vzlist} --no-header -a" do |process|
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
	
	# Private method to download openvz template
	# XXX Download the template from OpenVZ repository
	def download full_url
		require 'open-uri'
		writeOut = open(@@vzcache, "wb")
		writeOut.write(open(full_url).read)
		writeOut.close
	end
	
	# If CTID not specified, it will assign the first possible value
	# Note that CT ID <= 100 are reserved for OpenVZ internal purposes.
	def ctid
		if tmp = vzlist('--no-header', '-a','-N',resource[:name]).split(" ")[0]
			id = tmp
		elsif !resource[:ctid]
			out = vzlist('-a', '-o','ctid')
			tmp = Integer(out.split.last)
			id = tmp <= 100 ? 101 : tmp + 1
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
	
		if hn = resource[:hostname]
			args << '--hostname' << hn
		end

		args << '--name' << resource[:name]
		vzctl args
	
		if resource[:ensure] == :running
			vzctl('start', ctid)
		end
	end
	
	def setpresent
#		case resource[:ensure]
#			when :absent then return #do nothing
#			else install
#		end
		install
	end
	
	def destroy
		if status == :running
			vzctl('stop', ctid)
		end
		vzctl('destroy', ctid)
	end
	
	def purge
		#	File.unlink("#{@@vzconf}/#{ctid}.conf.destroyed")
	end
	
	def stop
		if !exists?
			install
		end
		vzctl('stop', ctid)
	end
	
	def start
		if !exists?
			install
		end
		vzctl('start', ctid)
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
				return :installed
			elsif stat[4] == "running"
				return :running
			elsif stat[4] == "down"
				return :stopped
			else 
				return :absent
			end
		else
			debug "Domain %s status: absent" % [resource[:name]]
			debug resource.should(:ensure)
			return :absent
		end
	end
	
	#	VE_ARGS = [ ":onboot", ":userpasswd", ":disabled", ":name", ":description", ":setmode", ":ipadd", ":ipdel", ":hostname", ":nameserver", ":searchdomain", ":netid_add", ":netif_del", ":mac", ":nost_ifname", ":host_mac", ":bridge", ":mac_filter", ":numproc", ":numtcpsock", ":numothersock", ":vmguardpages", ":kmemsize", ":tcpsndbuf", ":tcprcvbuf", ":othersockbuf", ":dgramrcvbuf", ":oomguarpages", ":lockedpages", ":privvmpages", ":shmpages", ":numfile", ":numflock", ":numpty", ":numsiginfo", ":dcachesize", ":numiptent", ":physpages", ":cpuunits", ":cpulimit", ":cpus", ":meminfo", ":iptables", ":netdev_add", ":netdev_del", ":diskspace", ":discinodes", ":quotatime", ":quotaugidlimit", ":noatime", ":capability", ":devnodes", ":devices", ":features", ":applyconfig", ":applyconfig_map", ":ioprio" ]
	
	SET_PARAMS = ["name", "capability", "applyconfig", "applyconfig_map", "iptables", "features", "searchdomain", "hostname", "disabled", "noatime", "setmode", "userpasswd", "cpuunits", "cpulimit", "quotatime", "quotaugidlimit", "ioprio", "cpus", "netif_add", "netif_del", "diskspace", "diskinodes", "devices", "devnodes"]
	
	UBC_PARAMS = ["vmguarpages", "physpages", "oomguarpages", "lockedpages", "privvmpages", "shmpages", "numproc", "numtcpsock", "numothersock", "numfile", "numflock", "numpty", "numsiginfo", "dcachesize", "numiptent", "avnumproc", "kmemsize", "tcpsndbuf", "tcprcvbuf", "othersockbuf", "dgramrcvbuf"]

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
		conf = @@vzconf + ctid + '.conf'
		value = open(conf).grep(/^#{arg.upcase}/)
		result = value.size == 0 ? '' : value[0].split('"')[1]
		p "Actual value: " << result
		p "Should value: " << String(resource.should(arg))
		return result
	end
	
	#	class IPProperty < Puppet::Property
	#		def ipsplit(str)
	#			interface, address, defrouter = str.split(':')
	#			return interface, address, defrouter
	#		end
	#	end

	def autoboot
		return get_value("onboot") == "yes" ? true : false
	end

	def autoboot=(value)
		result = value == 'true' ? 'yes' : 'no'
		vzctl 'set', ctid, '--onboot', result, '--save'
	end

	def ipaddr
		get_value("IP_ADDRESS").split
	end

	def ipaddr=(value)
		id = ctid
		vzctl 'set', id, '--ipdel', 'all', '--save'
		args = ['set', id]
		[value].flatten.each do |ip|
			args << '--ipadd' << ip
		end
		vzctl args, '--save'
	end

	def nameserver
		get_value("nameserver").split
	end

	def nameserver=(value)
		id = ctid
		args = ['set', id]
		[value].flatten.each do |ip|
			args << '--nameserver' << ip
		end
		vzctl args, '--save'
	end

end
