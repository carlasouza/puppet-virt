Facter.add('virtual_guests') do
	confine :virtual => [ :xen0, :kvm ]
	setcode do
    # cache the list for other facts
    system('((/usr/bin/find /var/cache/virsh_list.state -mmin -5 2>&1 | /bin/grep -qE \'^\/var\/cache\/virsh_list\.state$\') && [ `/bin/cat /var/cache/virsh_list.state | /usr/bin/wc -l` -gt 1 ]) || /usr/bin/virsh list | egrep -v \'(^.*Id.*Name.*State$|^-*$|Domain-0|^$)\' > /var/cache/virsh_list.state')
    return '' unless File.exists?('/var/cache/virsh_list.state')
    File.read('/var/cache/virsh_list.state').split("\n").collect{|line| line.split[1] }.sort.join(',')
	end
end

