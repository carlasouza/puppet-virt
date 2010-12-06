class virt::openvz {
  case $virtual {
    openvzhn: { include virt::openvz::hn }
  }
}
