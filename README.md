# ws2022

## What is this project about?

`ws2022` is a set of configuration files used to build automated Windows Server 2022 virtual machine images using [Packer](https://www.packer.io/).
This Packer configuration file allows you to build images for VMware Workstation and Oracle VM VirtualBox.

## Prerequisites

* [Packer](https://www.packer.io/downloads.html) to run the build process
* [VMware ESXI](https://www.vmware.com/de/products/esxi-and-esx.html) to build on
* [VMware OVF Tool](https://www.vmware.com/support/developer/ovf/) to create the OVA from the generated VM

## Build process

**Unattended Windows Installation (`autounattend.xml` and `sysprep-autounattend.xml`)**
  * Windows Server 2022 Datacenter Eval Edition (Desktop Experience)
  * Changing Eval to Full Datacenter version with KMS key
  * Install & configure OpenSSH Client & Server for remote connection  
  * Installation of VMware tools from ISO provided from the build ESX server

**Packer Provisioner Steps**
* Updating OS via Windows Update
* Doing some OS adjustments
  * Set Windows telemetry settings to minimum
  * Show file extentions by default
  * Install [Chocolatey](https://chocolatey.org/) - a Windows package manager
    * Install Microsoft Edge (Chromium)
    * Install Win32-OpenSSH-Server
    * Install PowerShell Core
    * Install 7-Zip
    * Install Notepad++    
  * Enable Powershell-Core (`pwsh`) to be the default SSHD shell
* Cleanup tasks
* Remove CDROM drives from VM template (otherwise there would be 2)

**Additional Gitlab-CI build steps**
* Export VM and package as an OVA file

## Result

| Parameter          | Value                         |
| ------------------ | ----------------------------- |
| Template type      | `.ova`                        |
| VM CPU             | `1 socket, 2 cores`           |
| Memory             | `4 GB`                        |
| Disk               | `64 GB, thin provisioned`     |
| Storage Controller | `VMware Paravirtual (pvscsi)` |
| Network            | `VMXNET 3`                    |

## HowTo

### Prepare Build ESX Server

* Default ESXi installation (can be nested)
* Enable SSH service
* Configure guest IP hack via SSH: 
  ```sh
  esxcli system settings advanced set -o /Net/GuestIPHack -i 1
  ```

### Prepare Build Host

* Must be Windows (for VMware's `ovftool`)
* Install Packer
* Install VMware OVA Tool and add the installation path to `%PATH%` to find `ovftool`

### Configure Build Variables

There are some variables which can be changed before building at the top of the `ws2022.json` file.
You can overwrite these variables in the file, in a variable file or via commandline.

See the [Packer documentation on user variables](https://www.packer.io/docs/templates/user-variables.html) for details.

A lot of these variables default to environment variables (`env VARIABLE_NAME`) so that I can use automated builds with Gitlab-CI.
You can either set these variables in your build environment or overwrite the defaults like described above.

| Packer Variable      | Default Value                   | Description                                                                                                                                                    |
| -------------------- | ------------------------------- |
| `iso_url`            | `https://...`                   | Link to the WS2022 installation ISO file (see `ws2022.json`)                                                                                                   |
| `iso_checksum`       | `sha256:....`                   | SHA256 checksum of above ISO file (see `ws2022.json`)                                                                                                          |
| `vcenter_server`     | `env PACKER_VCENTER_USER`       | VMware vSphere vCenter to connect to for building with the `vsphere-iso` builder                                                                               |
| `vcenter_user`       | `env PACKER_VCENTER_USER`       | The user to connect with to the vCenter                                                                                                                        |
| `vcenter_password`   | `env PACKER_VCENTER_PASSWORD`   | Above user's password                                                                                                                                          |
| `vcenter_datacenter` | `env PACKER_VCENTER_DATACENTER` | The name of the vSphere datacenter to build in                                                                                                                 |
| `esx_host`           | `env PACKER_ESX_HOST`           | The ESX to build on                                                                                                                                            |
| `esx_user`           | `env PACKER_ESX_USER`           | User to connect to above ESX                                                                                                                                   |
| `esx_password`       | `PACKER_ESX_PASSWORD`           | Above user's password                                                                                                                                          |
| -                    | `SMB_PATH`                      | Only for Gitlab-CI build. The UNC path to the SMB share where to put the resulting OVA file - the user running Gitlab-Runner must have write access (optional) |

### How to use Packer

To create a Windows Server VM image using a vSphere ESX host:

```sh
cd <path-to-git-root-directory>
packer build ws2022.json
```

Wait for the build to finish to find the generated OVA file in the `build` folder.

## Default credentials

The default credentials for this VM image are:

| Username      | Password    |
| ------------- | ----------- |
| Administrator | `Passw0rd.` |

## Implementation Details

- Retrying VMware tools installation in `install-vmware-tools-from-iso.ps1` because sometimes the installation fails on first try and services are not available and thus the IP address of the VM is not recognized by vCenter nor Packer
- Allow RC `2300218` for win-update script on first provisioner because vmxnet drivers will be pulled from Windows Update breaking the SSH network connection from Packer
- Postpone first reboot provisioner for `30s` to make sure the update script before finished before rebooting (connection loss because of vmxnet driver update)
- Run `win-update.ps1` twice, because it finds new updates / replaces updates again
- 

## Resources

- [packer-Win2019](https://github.com/eaksel/packer-Win2019) (used as a base for this work - big kudos!)
- [Hashicorp Windows Update Script](https://github.com/hashicorp/best-practices/blob/master/packer/scripts/windows/install_windows_updates.ps1)
- A lot of StackExchange, Blogs, etc... - thank you all for publishing about these great small gotchas which block me sometimes