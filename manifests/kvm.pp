define virt::kvm($desc,$eth1_addr,$memory = 1024, $targetmem = 524288, $disk_size = 6, $ensure = running) {
  $hostname = $name

  virt { "$hostname":
    desc        =>  "$desc",
    memory      =>  $memory,
    cpus        =>  4,
    graphics    =>  "disable",
    clocksync   =>  "UTC",
    kickstart   =>  "http://puppet/centos.ks.php?hostname=$hostname&eth1_addr=$eth1_addr ksdevice=eth0 console=ttyS0,115200",
    boot_location => "/mnt/gluster/centos/6/os/x86_64",
    virt_path   =>  "/mnt/gluster/vmimages/$hostname.img",
    disk_size   =>  $disk_size,
    disk_cache  =>  "writethrough",
    os_variant  =>  "virtio26",
    virt_type   =>  "kvm",
    interfaces  =>  ["br0", "br1"],
    autoboot    =>  true,
    ensure      =>  $ensure,
    on_poweroff =>  "destroy",
    on_reboot   =>  "restart",
    on_crash    =>  "restart",
  }

  exec { "/usr/bin/virsh setmem $hostname $targetmem": 
  unless  => "/usr/bin/virsh dommemstat $hostname | /bin/grep $targetmem",
  returns => [0,1] 
  }
}
