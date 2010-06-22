include *

Puppet::Type.type(:virt).provide(:libvirt) do
	desc "Libvirt provider"

	util = Util.new()
	conn = util.connect

	confine :operatingsystem => [:debian, :ubuntu]
	
	def status 
		util.isRunning? @resource[:name]
	end
end
