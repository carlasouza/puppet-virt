# virt_libvirt.rb

def libvirt_connect
  begin
    require 'libvirt'
    Libvirt::open('qemu:///system')
  rescue NoMethodError
    nil
  rescue Libvirt::Error
    nil
  end
end

Facter.add("virt_libvirt") do
  setcode do
    begin
      require 'libvirt'
      true
    rescue LoadError
      nil
    end
  end
end

Facter.add("virt_conn_type") do
  confine :virt_libvirt => true
  setcode do
    begin
      libvirt_connect.type.chomp
    rescue NoMethodError
      nil
    end
  end
end

Facter.add("virt_hypervisor_version") do
  confine :virt_libvirt => true
  setcode do
    libvirt_connect.version.chomp
  end
end

Facter.add("virt_libvirt_version") do
  confine :virt_libvirt => true
  setcode do
    libvirt_connect.libversion.chomp
  end
end

Facter.add("virt_hostname") do
  confine :virt_libvirt => true
  setcode do
    libvirt_connect.hostname.chomp
  end
end

Facter.add("virt_uri") do
  confine :virt_libvirt => true
  setcode do
    libvirt_connect.uri.chomp
  end
end

Facter.add("virt_max_vcpus") do
  confine :virt_libvirt => true
  setcode do
    libvirt_connect.max_vcpus.chomp
  end
end

Facter.add("virt_domains_active") do
  confine :virt_libvirt => true
  setcode do
    domains = []
    conn = libvirt_connect
    conn.list_domains.each do |domid|
      domains.concat(conn.lookup_domain_by_id(domid).name)
    end
    domains.join(',')
  end
end

Facter.add("virt_domains_inactive") do
  confine :virt_libvirt => true
  setcode do
    domains = []
    conn = libvirt_connect
    conn.list_defined_domains.each do |domname|
      domains.concat(domname)
    end
    domains.join(',')
  end
end

Facter.add("virt_networks_active") do
  confine :virt_libvirt => true
  setcode do
    networks = []
    conn = libvirt_connect
    conn.list_networks.each do |netname|
      networks.concat(netname)
    end
    networks.join(',')
  end
end

Facter.add("virt_networks_inactive") do
  confine :virt_libvirt => true
  setcode do
    networks = []
    conn = libvirt_connect
    conn.list_defined_networks.each do |netname|
      networks.concat(netname)
    end
    networks.join(',')
  end
end

Facter.add("virt_nodes") do
  confine :virt_libvirt => true
  setcode do
    nodes = []
    conn = libvirt_connect
    conn.list_nodedevices.each do |nodename|
      nodes.concat(nodename)
    end
    nodes.join(',')
  end
end

Facter.add("virt_nwfilters") do
  confine :virt_libvirt => true
  setcode do
    nwfilters = []
    conn = libvirt_connect
    conn.list_nwfilters.each do |filtername|
      nwfilters.concat(filtername)
    end
    nwfilters.join(',')
  end
end

Facter.add("virt_secrets") do
  confine :virt_libvirt => true
  setcode do
    secrets = []
    conn = libvirt_connect
    conn.list_secrets.each do |secret|
      secrets.concat(secret)
    end
    secrets.join(',')
  end
end

Facter.add("virt_storage_pools_active") do
  confine :virt_libvirt => true
  setcode do
    pools = []
    conn = libvirt_connect
    conn.list_storage_pools.each do |pool|
      pools.concat(pool)
    end
    pools.join(',')
  end
end

Facter.add("virt_storage_pools_inactive") do
  confine :virt_libvirt => true
  setcode do
    pools = []
    conn = libvirt_connect
    conn.list_defined_storage_pools.each do |pool|
      pools.concat(pool)
    end
    pools.join(',')
  end
end
