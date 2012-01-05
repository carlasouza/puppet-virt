# virt_libvirt.rb

def libvirt_connect
  begin
    require 'libvirt'
    Libvirt::open('qemu:///system')
  rescue Libvirt::Error => e
    if e.libvirt_code == 3
      # do nothing
    else
      raise
    end
  end
end

Facter.add("virt_conn_type") do
  confine :kernel => "Linux"
  setcode do
    libvirt_connect.type.chomp
  end
end

Facter.add("virt_hypervisor_version") do
  confine :kernel => "Linux"
  setcode do
    libvirt_connect.version.chomp
  end
end

Facter.add("virt_libvirt_version") do
  confine :kernel => "Linux"
  setcode do
    libvirt_connect.libversion.chomp
  end
end

Facter.add("virt_hostname") do
  confine :kernel => "Linux"
  setcode do
    libvirt_connect.hostname.chomp
  end
end

Facter.add("virt_uri") do
  confine :kernel => "Linux"
  setcode do
    libvirt_connect.uri.chomp
  end
end

Facter.add("virt_max_vcpus") do
  confine :kernel => "Linux"
  setcode do
    libvirt_connect.max_vcpus.chomp
  end
end

Facter.add("virt_domains_active") do
  confine :kernel => "Linux"
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
  confine :kernel => "Linux"
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
  confine :kernel => "Linux"
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
  confine :kernel => "Linux"
  setcode do
    networks = []
    conn = libvirt_connect
    conn.list_defined_networks.each do |netname|
      networks.concat(netname)
    end
    networks.join(',')
  end
end

Facter.add("virt_nodedevices") do
  confine :kernel => "Linux"
  setcode do
    nodedevices = []
    conn = libvirt_connect
    conn.list_nodedevices.each do |nodename|
      nodedevices.concat(nodename)
    end
    nodedevices.join(',')
  end
end
