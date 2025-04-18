# infra-lab-iac
👨‍💻 Manual Steps to Complete pfSense Setup
1. Access the console

In Proxmox Web UI:

    Open the VM vm-pfsense (ID 100)

    Use the "Console" tab

2. Go through the installer

    Choose Install pfSense

    Use default keymap

    Partitioning: Auto (UFS)

    Confirm installation

    Reboot when prompted

✅ The ISO will be ignored on next boot, pfSense will boot from disk
3. Initial pfSense Console Configuration

You'll see a menu like this:

0) Logout
1) Assign Interfaces
2) Set Interface IP Address
...
8) Shell

➡️ Press 1 to assign interfaces:

    VLANs: n

    WAN interface: vtnet0

    LAN interface: vtnet1

4. Set static IPs

Press 2 to configure IP addresses:

    WAN: 192.168.0.201/24

    Gateway: 192.168.0.1 (your router)

    LAN: 192.168.1.1/24

If gateway fails, run manually in shell (option 8):

route add default 192.168.0.1

5. Test connectivity

In shell:

ping 8.8.8.8
curl -I https://pkg.pfsense.org

6. Enable SSH and install API package

In WebGUI (https://192.168.0.201):

    Login: admin / pfsense

    Go to System > Advanced > Admin Access

    ✅ Enable Secure Shell (SSH)

Then in shell:

pkg update -f
pkg install -y pfSense-pkg-API

7. Create ansible user

echo "ansible123" | pw useradd ansible -m -s /bin/sh -h 0
usermod -G admins ansible

Or via WebGUI → System > User Manager
✅ After This

You’ll be able to:

    Access WebGUI: https://192.168.0.201

    SSH into pfSense as ansible

    Use Ansible to automate rules, users, firewall, etc.