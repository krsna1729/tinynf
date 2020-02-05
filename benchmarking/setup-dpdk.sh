#!/bin/sh
# Ensures that the devices given as $@, and only those devices, are bound to the DPDK kernel module

# Note that binding/unbinding devices occasionally has weird effects like killing SSH sessions,
# so we should only do it if absolutely necessary

# If DPDK doesn't exist (or we are using the TinyNF DPDK shim), ensure we were asked to do nothing
if [ -z "$RTE_SDK" ] || [ "$RTE_TARGET" = '.' ]; then
  if [ -z "$@" ]; then exit 0; fi
  echo "Could not find DPDK, cannot bind $@"
  exit 1
fi

# Unbind any other devices
all_bound="$(sudo $RTE_SDK/usertools/dpdk-devbind.py --status | grep 'drv=igb_uio' | awk '{print $1}')"
for pci in $@; do
  all_bound="$(echo "$all_bound" | grep -Fv "$pci")"
done
all_bound="$(echo "$all_bound" | tr '\n' ' ' | xargs)" # xargs is a cheap way to trim whitespace
if [ ! -z "$all_bound" ]; then
  sudo "$RTE_SDK/usertools/dpdk-devbind.py" -u $(echo "$all_bound" | tr '\n' ' ')
fi

needs_reset='false'
for pci in $@; do
  if ! sudo "$RTE_SDK/usertools/dpdk-devbind.py" --status | grep -F "$pci" | grep -q 'drv=igb_uio'; then
    needs_reset='true'
  fi
done

if [ "$needs_reset" = 'true' ]; then
  # Reset == uninstall driver, recompile, install driver
  # This also implies unbinding any devices that were using it, otherwise we can't uninstall it
  for pci in $(sudo "$RTE_SDK/usertools/dpdk-devbind.py" --status | grep drv=igb_uio | awk '{ print $1 }'); do
    sudo "$RTE_SDK/usertools/dpdk-devbind.py" -u $pci
  done
  sudo rmmod igb_uio >/dev/null 2>&1 || true
  make -C "$RTE_SDK" install -j$(nproc) T=x86_64-native-linuxapp-gcc DESTDIR=. >/dev/null 2>&1
  sudo modprobe uio
  sudo insmod "$RTE_SDK/$RTE_TARGET/kmod/igb_uio.ko"
  sudo "$RTE_SDK/usertools/dpdk-devbind.py" -u $@ >/dev/null 2>&1
  sudo "$RTE_SDK/usertools/dpdk-devbind.py" -b igb_uio $@
fi
