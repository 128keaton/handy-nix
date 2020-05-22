import unittest
import pygrub


class TestPyGrub(unittest.TestCase):
    success_result = "{'variables': {'default': 'OS EFI ...', 'timeout': '15'}, 'entries': {'ToastER2 UEFI ...': {" \
                     "'name': 'ToastER2 UEFI ...', 'classes': ['gnu-linux', 'gnu', 'os'], 'kernel': 'linux  (" \
                     "pxe)/toastER2-2/vmlinuz root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2-2 ip=dhcp  rw " \
                     "i8042.notimeout i$', 'ramdisk': 'initrd (pxe)/toastER2-2/initrd.img'}, 'ToastER2 UEFI (disable " \
                     "graphics) ...': {'name': 'ToastER2 UEFI (disable graphics) ...', 'classes': ['gnu-linux', " \
                     "'gnu', 'os'], 'kernel': 'linux  (pxe)/toastER2/vmlinuz root=/dev/nfs nfsroot=${" \
                     "pxe_default_server}:/nfs/toastER2 ip=dhcp rw i8042.notimeout i8042.$', 'ramdisk': 'initrd (" \
                     "pxe)/toastER2/initrd.img'}, 'ToastER2 UEFI (safemode) ...': {'name': 'ToastER2 UEFI (safemode) " \
                     "...', 'classes': ['gnu-linux', 'gnu', 'os'], 'kernel': 'linux  (pxe)/toastER2/vmlinuz " \
                     "root=/dev/nfs nfsroot=${pxe_default_server}:/nfs/toastER2 ip=dhcp  rw i8042.notimeout i8042$', " \
                     "'ramdisk': 'initrd (pxe)/toastER2/initrd.img'}}}"

    def test_base_parse(self):
        result = str(pygrub.parse_config('grub.cfg'))
        self.assertEqual(self.success_result, result)


if __name__ == '__main__':
    unittest.main()
