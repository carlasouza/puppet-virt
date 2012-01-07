# virt_libvirt.rb

def libvirt_connect
  begin
    require 'libvirt'
    Libvirt::open('qemu:///system')
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
      libvirt_connect.type.chomp
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
      libvirt_connect.version.to_s.chomp
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
      libvirt_connect.libversion.to_s.chomp
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
      libvirt_connect.hostname.chomp
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
      libvirt_connect.uri.chomp
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
      libvirt_connect.max_vcpus('qemu').to_s.chomp
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
      libvirt_connect.list_domains.each do |domid|
        domains.concat([ conn.lookup_domain_by_id(domid).name ])
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
      libvirt_connect.list_defined_domains.each do |domid|
        domains.concat([ conn.lookup_domain_by_id(domid).name ])
      end
      domains.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_networks_active") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      networks = []
      libvirt_connect.list_networks.each do |netname|
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
      libvirt_connect.list_defined_networks.each do |netname|
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
      libvirt_connect.list_nodedevices.each do |nodename|
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
      libvirt_connect.list_nwfilters.each do |filtername|
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
      libvirt_connect.list_secrets.each do |secret|
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
      libvirt_connect.list_storage_pools.each do |pool|
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
      libvirt_connect.list_defined_storage_pools.each do |pool|
        pools.concat([ pool ])
      end
      pools.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end
