# TODO Update methods' visibility to private
Puppet::Type.type(:virt).provide(:libvirt) do
  desc "Creates a new Xen (fully or para-virtualized) or KVM guest using libvirt."
  # Ruby-Libvirt API Reference: http://libvirt.org/ruby/api/index.html

  commands :virtinstall => "/usr/bin/virt-install"
  commands :virtclone => "/usr/bin/virt-clone"
  commands :virsh => "/usr/bin/virsh"
  commands :grep => "/bin/grep"
  commands :ip => "/sbin/ip"

  # The provider is chosen by virt_type
  confine :feature => :libvirt

  has_features :pxe, :manages_behaviour, :graphics, :clocksync, :boot_params, :cloneable

  defaultfor :virtual => ["kvm", "physical", "xenu"]

  def self.instances
    # TODO
    []
  end

  def hypervisor
    #FIXME add support to autentication
    case resource[:virt_type]
      when :xen_fullyvirt, :xen_paravirt then "xen:///"
      else "qemu:///session"
    end
  end

  # Executes operation over guest
  def exec
    conn = Libvirt::open(hypervisor)
    @guest = conn.lookup_domain_by_name(resource[:name])
    ret = yield if block_given?
    conn.close
    return ret
  end

  # Installs the new domain.
  def install(bootoninstall = true)
    debug "Installing new vm"
    debug "Boot on install: %s" % bootoninstall

    if resource[:xml_file]
      xmlinstall(bootoninstall)
    elsif resource[:clone]
      clone
    else
      debug "Virtualization type: %s" % [resource[:virt_type]]

      args = generalargs(bootoninstall) + network + graphic + bootargs
      debug "[INFO] virt-install arguments: #{args}"
      virtinstall args
    end

    resource.properties.each do |prop|
      if self.class.supports_parameter? :"#{prop.to_s}" and prop.to_s != 'ensure'
        eval "self.#{prop.to_s}=prop.should"
      end
    end

  end

  def clone
    # TODO test it
    # virt-clone -o web_devel        -n database_devel  -f /path/to/database_devel.img --connect=qemu:///system
    # virt-clone -o resource[:clone] -n resource[:name] -f resource[:virt_path]        --connect=qemu:///system
    args = ["-o", resource[:clone], "--connect=#{hypervisor}", "-n", resource[:name]]
    if resource[:virt_path].nil?
      args << "--auto-clone"
    else
      args << ["-f", resource[:virt_path]]
    end
    virtclone args
  end

  def generalargs(bootoninstall)
    debug "Building general arguments"

    virt_parameter = case resource[:virt_type]
      when :xen_fullyvirt then "--hvm" #must validate kernel support
      when :xen_paravirt then "--paravirt" #Must validate kernel support
      when :kvm then "--accelerate" #Must validate hardware support
    end
    arguments = ["--name", resource[:name], "--ram", resource[:memory], "--noautoconsole", "--force", virt_parameter]

    if !bootoninstall
      arguments << "--noreboot"
    end

    if resource[:desc]
      arguments << ["--description='#{resource[:desc]}'"]
    end

    if resource[:boot_options]
      arguments << [ "-x", resource[:boot_options] ]
    end

    max_cpus = Facter.value('processorcount')
    arguments << ["--vcpus=#{resource[:cpus]},maxvcpus=#{max_cpus}"]

    arguments << diskargs

    if resource[:boot_location]
      fail "To use 'boot_location', you need to specify the 'virt_path' parameter." if resource[:virt_path].nil?
      arguments << ["-l", resource[:boot_location]]
    else
      if File.exists?(resource[:virt_path].split('=')[1])
        warnonce("Ignoring PXE boot. Domain image already exists") if resource[:pxe]
        debug "File already exists. Importing domain"
        arguments << "--import"
      elsif resource[:pxe]
        debug "Creating new domain. Using PXE"
        # Only works with hvm virtualization
        arguments << "--pxe"
      else
        fail "Only existing domain images importing and PXE boot are supported."
      end
    end

    arguments
  end

  def diskargs
    parameters = ""
    parameters = resource[:virt_path] if resource[:virt_path]
    parameters.concat("," + resource[:disk_size]) if resource[:disk_size]
    parameters.empty? ? [] : ["--disk", parameters]
  end

  # Additional boot arguments
  def bootargs
    debug "Bootargs"

    # kickstart support
    resource[:kickstart] ? ["-x", resource[:kickstart]] : []
  end

  # Creates network arguments for virt-install command
  def network
    debug "Network paramenters"
    network = []

    iface = resource[:interfaces]
    case iface
    when nil
      network = ["--network", "network=default"]
    when "disabled"
      network = ["--nonetworks"]
    else
      iface.each { |iface| network << ["--network","bridge="+iface] if interface?(iface) }
    end

    macs = resource[:macaddrs]
    if macs
      resource[:macaddrs].each do |macaddr|
        #FIXME -m is decrepted
        network << "-m"
        network << macaddr
      end
    end

    return network
  end

  # Auxiliary method. Checks if declared interface exists.
  def interface?(ifname)
    ip('link', 'list',  ifname)
    rescue Puppet::ExecutionFailure
      fail("Network interface " + ifname + " does not exist")
  end

  #TODO the Libvirt biding for ruby doesnt support this feature
  def interfaces
    warnonce "It is not possible to change interfaces settings for an existing guest."
    resource[:interfaces]
  end

  #TODO the Libvirt biding for ruby doesnt support this feature
  def interfaces=(value)
    warnonce "It is not possible to change interfaces settings for an existing guest."
  end

  # Setup the virt-install graphic configuration arguments
  def graphic
    opt = resource[:graphics]
    case opt
      when :enable || nil then args = ["--vnc"]
      when :disable then args = ["--nographics"]
      else args = ["--vncport=" + opt.split(':')[1]]
    end
    args
  end

  # Install guests using virsh with xml when virt-install is still not yet supported.
  # Libvirt XML <domain> specification: http://libvirt.org/formatdomain.html
  def xmlinstall(bootoninstall)
    if File.exists?(resource[:xml_file])
      args = ["-c", hypervisor, "define", resource[:xml_file]]

      debug "Creating the domain: %s " % [resource[:name]]
      virsh args

      exec { @guest.create } if bootoninstall
    else
      fail "Error: XML file not found: " + resource[:xml_file]
    end
  end

  # Changing ensure to absent
  def destroy #Changing ensure to absent
    debug "Trying to destroy domain %s" % [resource[:name]]

    begin
      exec { @guest.destroy }
    rescue Libvirt::Error => e
      debug "Domain %s already Stopped" % [resource[:name]]
    end
    exec { @guest.undefine }
  end

  #FIXME remove the guest's files
  def purge
    destroy
  end

  # Creates config file if absent, and makes sure the domain is not running.
  def stop
    debug "Stopping domain %s" % [resource[:name]]

    if !exists?
      install(false)
    elsif status == :running
      case resource[:virt_type]
        when :kvm,:qemu then exec { @guest.destroy }
        else exec { @guest.shutdown }
      end
    end
  end

  def suspend
    if !exists?
      install(false)
    elsif
      case status
      when :running
        exec { @guest.suspend }
      else
        exec { @guest.create }
        exec { @guest.suspend }
      end
    end
  end

  # Creates config file if absent, and makes sure the domain is running.
  def start
    debug "Starting domain %s" % [resource[:name]]

    if exists?
      case status
      when :suspended
        exec { @guest.resume }
      else
        exec { @guest.create }
      end
    elsif status == :absent
      install
    end
  end

  # Auxiliary method to make sure the domain exists before change it's properties.
  def setpresent
    install(false)
  end

  # Check if the domain exists.
  def exists?
    exec
    true
  rescue Libvirt::RetrieveError => e
    false # The vm with that name doesnt exist
  end

  # running | stopped | absent,
  def status
    if exists?
    # 1 = running, 3 = paused|suspend|freeze, 5 = stopped
      if resource[:ensure].to_s == "installed"
        return :installed
      elsif exec { @guest.info.state } == 3
        debug "Domain %s status: suspended" % [resource[:name]]
        return :suspended
      elsif exec { @guest.info.state } != 5
        debug "Domain %s status: running" % [resource[:name]]
        return :running
      else
        debug "Domain %s status: stopped" % [resource[:name]]
        return :stopped
      end
    else
      debug "Domain %s status: absent" % [resource[:name]]
      return :absent
    end
  end

  # Is the domain autostarting?
  def autoboot
    return exec { @guest.autostart.to_s }
  end

  # Set true or false to autoboot property
  def autoboot=(value)
    debug "Trying to set autoboot %s at domain %s." % [resource[:autoboot], resource[:name]]
    # FIXME
    if value.to_s == "false"
      exec { @guest.autostart=(false) }
    else
      exec { @guest.autostart=(true) }
    end
  rescue Libvirt::RetrieveError => e
    debug "Domain %s not defined" % [resource[:name]]
  end

  def memory
    mem = exec { @guest.max_memory }
    mem / 1024 #MB
  end

  def memory=(value)
    mem = value * 1024 #MB
    exec { @guest.destroy } unless status == :stopped
    fail "Unable to stop the guest." if status != :stopped
    exec { @guest.max_memory=(mem) }
    start
  end

  def cpus
    exec { @guest.num_vcpus 0 } #Why 0? See at http://www.libvirt.org/html/libvirt-libvirt.html#virDomainGetVcpusFlags
  rescue Libvirt::RetrieveError => e
    debug "Domain is not running, cannot evaluate cpus parameter"
  end

  def cpus=(value)
    warn "It is not possible to set the # of cpus if the guest is not running." if status != :running
    exec { @guest.vcpus=(value) }
  end

  # Not implemented by libvirt yet
  def on_poweroff
    #TODO refactor
    path = "/etc/libvirt/qemu/" #Debian/ubuntu path for qemu's xml files
    extension = ".xml"
    xml = path + resource[:name] + extension

    if File.exists?(xml)
      arguments =  ["on_poweroff", xml]
      line = ""
      debug "Line: %s" % [line]
      line = grep arguments
      return line.split('>')[1].split('<')[0]
    else
      return :absent
    end
  end

  #
  def on_poweroff=(value)
    # Not implemented by libvirt yet
  end

  #
  def on_reboot
    # Not implemented by libvirt yet
    resource[:on_reboot]
  end

  #
  def on_reboot=(value)
    # Not implemented by libvirt yet
  end

  #
  def on_crash
    # Not implemented by libvirt yet
    resource[:on_crash]
  end

  #
  def on_crash=(value)
    # Not implemented by libvirt yet
  end

end
