# virt_libvirt.rb

def libvirt_connect
  begin
    require 'libvirt'
    $c = Libvirt::open('qemu:///system')
    return $c
  rescue LoadError
    nil
  rescue Libvirt::Error => e
    raise
  end
end

Facter.add("virt_libvirt") do
  setcode do
    begin
      require 'libvirt'
      true
    rescue LoadError
      false
    end
  end
end

Facter.add("virt_conn") do
  confine :virt_libvirt => true
  setcode do
    begin
      libvirt_connect
      true
    rescue Libvirt::Error, NoMethodError
      false
    end
  end
end

Facter.add("virt_conn_type") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      $c.type.chomp
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_hypervisor_version") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      $c.version.to_s.chomp
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_libvirt_version") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      $c.libversion.to_s.chomp
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_hostname") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      $c.hostname.chomp
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_uri") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      $c.uri.chomp
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_max_vcpus") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      $c.max_vcpus('qemu').to_s.chomp
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_domains_active") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      domains = []
      $c.list_domains.each do |domid|
        domains.concat([ $c.lookup_domain_by_id(domid.to_i).name ])
      end
      domains.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_domains_inactive") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      domains = []
      $c.list_defined_domains.each do |name|
        domains.concat([ name ])
      end
      domains
    end
  end
end

Facter.add("virt_networks_active") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      networks = []
      $c.list_networks.each do |netname|
        networks.concat([ netname ])
      end
      networks.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_networks_inactive") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      networks = []
      $c.list_defined_networks.each do |netname|
        networks.concat([ netname ])
      end
      networks.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_nodes") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      nodes = []
      $c.list_nodedevices.each do |nodename|
        nodes.concat([ nodename ])
      end
      nodes.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_nwfilters") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      nwfilters = []
      $c.list_nwfilters.each do |filtername|
        nwfilters.concat([ filtername ])
      end
      nwfilters.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_secrets") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      secrets = []
      $c.list_secrets.each do |secret|
        secrets.concat([ secret ])
      end
      secrets.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_storage_pools_active") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      pools = []
      $c.list_storage_pools.each do |pool|
        pools.concat([ pool ])
      end
      pools.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_storage_pools_inactive") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      pools = []
      $c.list_defined_storage_pools.each do |pool|
        pools.concat([ pool ])
      end
      $c.close
      pools.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end
