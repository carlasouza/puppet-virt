#require 'facter/util/plist'
Puppet::Type.type(:virt).provide(:openvz) do
	desc "Manages OpenVZ guests."	# More information about OpenVZ at: openvz.org

	commands :vzctl  => "/usr/sbin/vzctl"
	commands :vzlist => "/usr/sbin/vzlist"

	has_features :disabled, :cpu_fair, :disk_quota, :manages_resources, :manages_capabilities, :manages_features, :manages_devices, :manages_user, :iptables, :initial_config, :storage_path

	defaultfor :virtual => ["openvzhn"]

	if [ "Ubuntu", "Debian" ].any? { |os|  Facter.value(:operatingsystem) == os }
		@@vzcache = "/var/lib/vz/template/cache/"
		@@vzconf = "/etc/vz/conf/"
	else
		raise Puppet::Error, "Sorry, this provider is not supported for your Operation System, yet :)"
	end

	# Returns all host's guests
	def self.instances
		guests = []
		execpipe "#{vzlist} --no-header -a -o ctid" do |process|
		process.collect do |line|
		next unless options = parse(line)
				guests << new(options)
			end
		end
		guests
	end

	def ostemplate
		os = resource[:os_template]
		if File.file? @@vzcache + os + '.tar.gz' || !resource[:tmpl_repo].nil?
			return os
		end
		arch = resource[:arch].nil? ? Facter.value(:architecture) : resource[:arch]
		arch = case arch.to_s
		#when "i386","i686" then "x86"
		when "amd64","ia64","x86_64" then "x86_64"
			else "x86"
		end
		return resource[:os_template]
	end

	# Private method to download OpenVZ template if don't already exists
	def download(url='http://download.openvz.org/template/precreated/')
		template = ostemplate
		file = @@vzcache + template + '.tar.gz'
    if !File.file? file or File.zero? file
			require 'open-uri'
			Puppet.info "Downloading #{url}#{template}.tar.gz"
			writeOut = open(file, "wb")
			writeOut.write(open(url + '/' + template + '.tar.gz').read)
			writeOut.close
		end
	end

	# If CTID not specified, it will assign the first possible value
	# Note that CT ID <= 100 are reserved for OpenVZ internal purposes.
	def ctid
		if tmp = vzlist('--no-header', '-a','-N',resource[:name]).split(" ")[0]
			id = tmp
		elsif !id = resource[:id]
			out = vzlist('--no-header', '-a', '-o','ctid')
			tmp = out.empty? ? 100 : Integer(out.split.last)
			id = tmp <= 100 ? 101 : tmp + 1
		end
		if id
			return id
		else
			raise Puppet::Error, "CTID not specified"
		end
	end

	def install
    raise Puppet::Error, "Paramenter 'os_template' is required." if resource[:os_template].nil?

		if resource[:tmpl_repo]
			download(resource[:tmpl_repo])
		end

		args = [ 'create', ctid, '--ostemplate', ostemplate ]
		if priv = resource[:ve_private]
			args << '--private' << priv
		end

		if root = resource[:ve_root]
			args << '--root' << root
		end

		if config = resource[:configfile]
			args << '--config' << config
		end

		if ips = resource[:ipaddr]
			[ips].flatten.each do |ip|
				args << '--ipadd' << ip
			end
		end

		hn = resource[:hostname] ? resource[:hostname] : resource[:name]
		args << '--hostname' << hn

		args << '--name' << resource[:name]
		vzctl args

                resource.properties.each do |prop|
                        if self.class.supports_parameter? :"#{prop.to_s}" and prop.to_s != 'ensure'
                                eval "self.#{prop.to_s}=prop.should"
                        end
                end

	end

	def setpresent
		install
	end

	def destroy
		if status == :running
			vzctl('stop', ctid)
		end
		vzctl('destroy', ctid)
	end

	def purge
		destroy
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

	# OpenVZ guests status: exist, deleted, mouted, umounted, running, down
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

	SET_PARAMS = ["name", "capability", "applyconfig", "applyconfig_map", "iptables", "features", "searchdomain", "hostname", "disabled", "setmode", "cpuunits", "cpulimit", "quotatime", "quotaugidlimit", "ioprio", "cpus", "diskspace", "diskinodes", "devices", "devnodes"]

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
		result = value.size == 0 ? '' : value[0].split('"')[1].downcase
		return result
	end

	private
	def apply(paramname, value)
		args = ['set', ctid]
		[value].flatten.each do |value|
			args << '--'+paramname << value
		end
		vzctl(args, '--save')
	end

	def resources_parameters
		conf = @@vzconf + ctid + '.conf'

		results = []
		resource[:resources_parameters].flatten.each do |value|

			tmp = open(conf).grep(/^#{value.split("=")[0].upcase}/)[0].delete! "\""
			tmp.delete! "\n"
			results << tmp
		end
		results

	end

	def resources_parameters=(value)
		args = ['set', ctid]
		[value].flatten.each do |resource|
			paramname, value = resource.split("=")
			args << '--'+paramname.downcase << value
		end
		vzctl(args, '--save')
	end

	def memory
		get_value("PRIVVMPAGES").split(":")[0].to_i / 256 #MB
	end

	def memory=(value)
		vzctl('set', ctid, "--vmguarpages", value.to_s + "M", "--save")
		vzctl('set', ctid, "--oomguarpages", value.to_s + "M", "--save")
		vzctl('set', ctid, "--privvmpages", value.to_s + "M", "--save")
	end

	["autoboot", "noatime"].each do |name|
		arg = name == 'autoboot' ? 'onboot' : name
		define_method(name.to_s.downcase) do
			return get_value(arg) == "yes" ? :true : :false
		end

		define_method("#{name}=".downcase) do |value|
			result = value == :true ? 'yes' : 'no'
			vzctl('set', ctid, '--'+ arg, result, '--save')
		end
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

	def network_cards
		get_value("netdev").split
	end

	def network_cards=(value)
		vzctl('set', ctid, '--netdev_del', 'all', '--save')
		apply("netdev_add", value) unless value.empty?
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
