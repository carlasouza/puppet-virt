#require 'facter/util/plist'
Puppet::Type.type(:virt).provide(:openvz) do
	desc "Manages OpenVZ guests."
	# More information about OpenVZ at: openvz.org
	
	commands :vzctl  => "/usr/sbin/vzctl"
	commands :vzlist => "/usr/sbin/vzlist"
	commands :mkfs   => "/sbin/mkfs"

	has_features :disabled, :cpu_fair, :disk_quota, :resource_management, :capability_management, :features_management, :devices_management

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
	
	# Private method to download OpenVZ template if don't already exists
	def download 
		template = ostemplate
		file = @@vzcache + template + '.tar.gz'
		if !File.file? file
			require 'open-uri'
			debug "Downloading template '" + template + "' to directory: '" + @@vzcache + "'"
			writeOut = open(file, "wb")
			writeOut.write(open('http://download.openvz.org/template/precreated/' + template + '.tar.gz').read)
			writeOut.close
		end
	end
	
	# If CTID not specified, it will assign the first possible value
	# Note that CT ID <= 100 are reserved for OpenVZ internal purposes.
	def ctid
		if tmp = vzlist('--no-header', '-a','-N',resource[:name]).split(" ")[0]
			id = tmp
		elsif !id = resource[:ctid]
			out = vzlist('--no-header', '-a', '-o','ctid')
			tmp = out.empty? ? 100 : Integer(out.split.last)
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
			fail "Paramenter 'os_variant' is required."
		end

		download

		args = [ 'create', ctid, '--ostemplate', ostemplate ]
		if priv = resource[:private]
			args << '--private' << priv
		end
	
		if hn = resource[:hostname]
			args << '--hostname' << hn
		end

		args << '--name' << resource[:name]
		vzctl args
	
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

	# It is not possible to compare the current user password with the password declared
	def user
		false
	end

	def user=(value)
		vzctl('set', ctid, '--userpasswd', value)
	end

	SET_PARAMS = ["name", "capability", "applyconfig", "applyconfig_map", "iptables", "features", "searchdomain", "hostname", "disabled", "noatime", "setmode", "cpuunits", "cpulimit", "quotatime", "quotaugidlimit", "ioprio", "cpus", "diskspace", "diskinodes", "devices", "devnodes"]
	UBC_PARAMS = ["vmguarpages", "physpages", "oomguarpages", "lockedpages", "privvmpages", "shmpages", "numproc", "numtcpsock", "numothersock", "numfile", "numflock", "numpty", "numsiginfo", "dcachesize", "numiptent", "kmemsize", "tcpsndbuf", "tcprcvbuf", "othersockbuf", "dgramrcvbuf"]
	
	(SET_PARAMS+UBC_PARAMS).each do |arg|
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
		result = value.size == 0 ? '' : value[0].split('"')[1].downcase
		debug "Actual value: " << result
		debug "Should value: " << String(resource.should(arg))
		return result
	end
	
	private
	def apply(paramname, value)
		args = ['set', ctid]
		[value].flatten.each do |value|
			args << '--'+paramname << value
		end
		vzctl args, '--save'
	end

	def autoboot
		return get_value("onboot") == "yes" ? :true : :false
	end

	def autoboot=(value)
		result = value == :true ? 'yes' : 'no'
		vzctl 'set', ctid, '--onboot', result, '--save'
	end

	["nameserver", "iptables", "features", "capability"].each do |arg|
		define_method(arg.to_s.downcase) do
			get_value(arg).split
		end
	
		define_method("#{arg}=".downcase) do |value|
			apply(arg, value)
		end
	end

	def ipaddr
		get_value("ip_address").split
	end

	def ipaddr=(value)
		vzctl('set', ctid, '--ipdel', 'all', '--save')
		apply("ipadd", value) unless value.empty?
	end

	def interfaces
		get_value("netif").split(";")
	end

	def interfaces=(value)
		if value == "disabled"
			vzctl('set', ctid, '--netif_del', 'all', '--save')
		end

		apply("netif_add", value)
	end

	def devices
		devs = get_value("devices").split
		nodes = get_value("devnodes").split
		devs + nodes
	end

	def devices=(value)
		args = ['set', ctid]
		[value].flatten.each do |value|
			paramname = value.start_with?("b:", "c:") ? "devices" : "devnodes"
			args << '--'+paramname << value
		end
		vzctl args, '--save'
	end

	
end
