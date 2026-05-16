### Disk partition

**Issue: Root filesystem only uses 100 GiB on a 1 TB disk after Ubuntu LVM install**

When installing Ubuntu with the default "Use LVM" option, the installer creates the root logical volume (ubuntu-lv) at a fixed size of 100 GiB regardless of the underlying disk capacity. The physical volume (/dev/nvme0n1p3) spans the full ~950 GiB and is correctly assigned to the ubuntu-vg volume group, but only 100 GiB of that group is allocated to the root LV — leaving roughly 850 GiB as unused free space inside the VG. As a result, df -h / reports a ~98 GiB filesystem even though the disk is 1 TB.

Fix: extend the logical volume to consume the remaining free space in the volume group, then grow the ext4 filesystem online:

``` shell
# Confirm the LV name first
sudo lvdisplay

# Extend the logical volume to use all free space in the VG
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

# Grow the ext4 filesystem to fill the new LV size
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```
