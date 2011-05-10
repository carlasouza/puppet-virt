Puppet::Type.type(:virt).provide(:openvz) do
	desc "Manages OpenVZ guests."
        # More information about OpenVZ at: openvz.org

	commands :vzctl => "/usr/sbin/vzctl"

	#defaultfor @resource[:virt_type] => [:openvz]

	def install
	end

	def destroy
	end

	def stop
	end

	def start
	end

	def exists?
	end

	# running | stopped | absent
	def status
	end

end
