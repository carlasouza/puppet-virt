class virt::xen {
  case $::virtual {
    'xen0': { include virt::xen::xen0 }
    'xenu': { include virt::xen::xenu }
    default: { fail("No such xen mode known") }
  }
}
