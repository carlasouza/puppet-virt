# virt_libvirt.rb

Facter.add("virt_conn_type") do
  setcode do
    conn = Libvirt::open('qemu:///system')
    conn.type.chomp
  end
end
