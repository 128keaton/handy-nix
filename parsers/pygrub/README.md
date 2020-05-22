# Linux Python Parsers

## PyGrub
Reads a Grub2 configuration and parses it into JSON

```shell script
$ python pygrub.py /path/to/grub.cfg
```

Input:
```
set default="OS EFI ..."
set timeout=15
menuentry "OS EFI ..." --class gnu-linux --class gnu --class os {
 linux  (pxe)/boot/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs ip=dhcp rw nomodeset noefi i8042.notimeout i8$
 initrd (pxe)/boot/initrd.img-net
}

menuentry "ToastER2 UEFI ..." --class gnu-linux --class gnu --class os {
 linux  (pxe)/toastER2-2/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2-2 ip=dhcp  rw i8042.notimeout i$
 initrd (pxe)/toastER2-2/initrd.img
}

menuentry "ToastER2 UEFI (disable graphics) ..." --class gnu-linux --class gnu --class os {
 linux  (pxe)/toastER2/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2 ip=dhcp rw i8042.notimeout i8042.$
 initrd (pxe)/toastER2/initrd.img
}


menuentry "ToastER2 UEFI (safemode) ..." --class gnu-linux --class gnu --class os {
 linux  (pxe)/toastER2/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2 ip=dhcp  rw i8042.notimeout i8042$
 initrd (pxe)/toastER2/initrd.img
}
```


Output:
```json
{
	"variables": {
		"default": "OS EFI ...",
		"timeout": "15"
	},
	"entries": {
		"ToastER2 UEFI ...": {
			"name": "ToastER2 UEFI ...",
			"classes": ["gnu-linux", "gnu", "os"],
			"kernel": "linux  (pxe)/toastER2-2/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2-2 ip=dhcp  rw i8042.notimeout i$",
			"ramdisk": "initrd (pxe)/toastER2-2/initrd.img"
		},
		"ToastER2 UEFI (disable graphics) ...": {
			"name": "ToastER2 UEFI (disable graphics) ...",
			"classes": ["gnu-linux", "gnu", "os"],
			"kernel": "linux  (pxe)/toastER2/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2 ip=dhcp rw i8042.notimeout i8042.$",
			"ramdisk": "initrd (pxe)/toastER2/initrd.img"
		},
		"ToastER2 UEFI (safemode) ...": {
			"name": "ToastER2 UEFI (safemode) ...",
			"classes": ["gnu-linux", "gnu", "os"],
			"kernel": "linux  (pxe)/toastER2/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2 ip=dhcp  rw i8042.notimeout i8042$",
			"ramdisk": "initrd (pxe)/toastER2/initrd.img"
		}
	}
}
```


