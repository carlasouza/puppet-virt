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
