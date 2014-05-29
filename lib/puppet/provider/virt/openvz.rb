#require 'facter/util/plist'
Puppet::Type.type(:virt).provide(:openvz) do
  desc "Manages OpenVZ guests."  # More information about OpenVZ at: openvz.org

  commands :vzctl  => "/usr/sbin/vzctl"
  commands :vzlist => "/usr/sbin/vzlist"

  has_features :disabled, :cpu_fair, :disk_quota, :manages_resources,
    :manages_capabilities, :manages_features, :manages_devices, :manages_user,
    :iptables, :initial_config, :storage_path, :ip

  defaultfor :virtual => ["openvzhn"]

  case Facter.value(:operatingsystem)
  when "Ubuntu", "Debian"
    @@vzcache = "/var/lib/vz/template/cache/"
    @@vzconf = "/etc/vz/conf/"
  when "CentOS"
    @@vzcache = "/vz/template/cache/"
    @@vzconf = "/etc/vz/conf/"
  else
    raise Puppet::Error, "Sorry, this provider is not supported for your Operation System, yet :)"
  end

  %w(create destroy start stop status set).each do |action|
    define_method("vzctl_#{action}") do |*args|
      vzctl(action, *args)
    end
  end

  %w(name capability applyconfig applyconfig_map iptables features
    searchdomain hostname disabled setmode cpuunits cpulimit quotatime
    quotaugidlimit ioprio cpus diskspace diskinodes devices devnodes
  ).each do |arg|
    define_method(arg.to_s.downcase) do
      get_value(arg)
    end

    define_method("#{arg}=".downcase) do |value|
      args = parametrize(arg, value) << '--save'
      vzctl_set(ctid, *args)
    end
  end

  %w(autoboot noatime).each do |name|
    arg = name == 'autoboot' ? 'onboot' : name
    define_method(name.to_s.downcase) do
      return get_value(arg) == "yes" ? :true : :false
    end

    define_method("#{name}=".downcase) do |value|
      result = value == :true ? 'yes' : 'no'
      vzctl_set(ctid, '--'+ arg, result, '--save')
    end
  end

  %w(nameserver iptables features capability).each do |arg|
    define_method(arg.to_s.downcase) do
      get_value(arg).split
    end

    define_method("#{arg}=".downcase) do |value|
      apply(arg, value)
    end
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
                # when "i386","i686" then "x86"
                when "amd64","ia64","x86_64" then "x86_64"
                else "x86"
    end
    resource[:os_template]
  end

  # If CTID not specified, it will assign the first possible value
  # Note that CT ID <= 100 are reserved for OpenVZ internal purposes.
  def ctid
    if tmp = vzlist('-1', '-a','-N',resource[:name]).split(" ")[0]
    #if tmp = vzlist('--no-header', '-a','-N',resource[:name]).split(" ")[1]
      id = tmp
    elsif !id = resource[:id]
      out = vzlist('--no-header', '-a', '-o','ctid')
      tmp = out.empty? ? 100 : Integer(out.split.last)
      id = tmp <= 100 ? 101 : tmp + 1
    end
    return id if id
    raise Puppet::Error, "CTID not specified"
  end

  def install
    raise Puppet::Error, "Paramenter 'os_template' is required." if resource[:os_template].nil?

    download(resource[:tmpl_repo]) if resource[:tmpl_repo]

    args =  parametrize('ostemplate', ostemplate)
    args += parametrize('private',    resource[:ve_private]) if resource[:ve_private]
    args += parametrize('root',       resource[:ve_root]) if resource[:ve_root]
    args += parametrize('config',     resource[:configfile]) if resource[:configfile]
    args += deep_flatten(resource[:ipaddr]).map do |ip| if resource[:ipaddr]
      parametrize('ipadd', ip)
    end.flatten
    args += parametrize('hostname',   resource[:hostname] || resource[:name])
    args += parametrize('name',       resource[:name])
    
    vzctl_create(ctid, *args)

    resource.properties.each do |prop|
      if self.class.supports_parameter? :"#{prop.to_s}" and prop.to_s != 'ensure'
        send("#{prop.to_s}=", prop.should)
      end
    end
  end

  def setpresent
    install
  end

  def destroy
    vzctl_stop(ctid) if status == :running
    vzctl_destroy(ctid)
  end

  def purge
    destroy
  #  File.unlink("#{@@vzconf}/#{ctid}.conf.destroyed")
  end

  def stop
    install if !exists?
    vzctl_stop(ctid)
  end

  def start
    install if !exists?
    vzctl_start(ctid)
  end

  def exists?
    stat = vzctl_status(ctid).split(" ")
    !(stat.nil? || stat[2] == "deleted")
  end

  # OpenVZ guests status: exist, deleted, mouted, umounted, running, down
  # running | stopped | absent
  def status
    stat = vzctl_status(ctid).split(" ")

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
    vzctl_set(ctid, '--userpasswd', value)
  end

  def apply(paramname, value)
    args = parametrize_many(value) do |resource|
      [paramname, resource]
    end << '--save'
    vzctl_set(ctid, *args)
  end

  def resources_parameters
    conf = @@vzconf + ctid + '.conf'
    resource[:resources_parameters].flatten.map do |value|
      tmp = open(conf).grep(/^#{value.split("=")[0].upcase}/)[0].delete! "\""
      tmp.delete! "\n"
      tmp
    end
  end

  def resources_parameters=(value)
    args = parametrize_many(value) do |resource|
      resource.split('=')
    end << '--save'
    vzctl_set(ctid, *args)
  end

  def memory
    PRIVVMPAGES.split(":")[0].to_i / 256 #MB
  end

  def memory=(value)
    unless resource[:configfile] == "unlimited" #FIXME use regex for the match
      vzctl_set(ctid, "--vmguarpages", value.to_s + "M", '--save"'
      vzctl_set(ctid, "--oomguarpages", value.to_s + "M", '--save"'
      vzctl_set(ctid, "--privvmpages", value.to_s + "M", '--save"'
    end
  end

  def ipaddr
    ip_address.split
  end

  def ipaddr=(value)
    vzctl_set(ctid, '--ipdel', 'all', '--save')
    apply("ipadd", value) unless value.empty?
  end

  def network_cards
    netdev.split
  end

  def network_cards=(value)
    vzctl_set(ctid, '--netdev_del', 'all', '--save')
    apply("netdev_add", value) unless value.empty?
  end

  def interfaces
    netif.split(";")
  end

  def interfaces=(value)
    vzctl_set(ctid, '--netif_del', 'all', '--save') if value == "disabled"
    apply("netif_add", value)
  end

  def devices
    devices.split
    devnodes.split
    devs + nodes
  end

  def devices=(value)
    args = parametrize_many(value) do |resource|
      paramname = resource.start_with?('b:', 'c:') ? 'devices' : 'devnodes'
      [paramname, resource]
    end << '--save'
    vzctl_set(ctid, *args)
  end

  private

  def deep_flatten(value)
    [value].flatten
  end

  def parametrize_many(values, &block)
    deep_flatten(values).map do |resource|
      parametrize(*block.call(resource))
    end
  end

  def parametrize(name, value)
    ["--#{name}", value]
  end

  def get_value(arg)
    debug "Getting parameter #{arg} value"
    conf = @@vzconf + ctid + '.conf'
    value = open(conf).grep(/^#{arg.upcase}/)
    value.size == 0 ? '' : value[0].split('"')[1].downcase
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

end
