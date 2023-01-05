# ws2022

## What is this project about?

`ws2022` is a set of configuration files used to build automated Windows Server 2022 virtual machine images using [Packer](https://www.packer.io/).
This Packer configuration file allows you to build images for VMware Workstation and Oracle VM VirtualBox.

## Prerequisites

* [Packer](https://www.packer.io/downloads) to run the build process
* [VMware vCenter](https://www.vmware.com/products/vcenter-server.html) and [VMware ESXI](https://www.vmware.com/products/esxi-and-esx.html) to build on
* `xorriso`, `mkisofs`, `hdiutil` (macOS) or `oscdimg` (part of Windows ADK) on the build host to build a CD ISO
* `tar` for building an OVA from the export OVF files

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
* Copy OVA file to an SMB share for further use

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

### Requirements

* ESX added to vCenter to build on
* Buildhost with packer installed (run `packer init`-command before building)
* ISO build tool in the PATH to be found by `vsphere-iso` packer plug-in
* For creating an OVA automatically (`gitlab-ci` build): tar

### Configure Build Variables

There are some variables which can be changed before building at the top of the `ws2022.pkr.hcl` file.
You can overwrite these variables in the file, in a variable file or via commandline.

See the [Packer documentation on user variables](https://www.packer.io/docs/templates/hcl_templates/variables) for details.

A lot of these variables are required for the build but do not have default values. 
In this case packer will search for environment variables starting with `PKR_VAR_`, e.g. `PKR_VAR_vcenter_server`. 
This is used in the automated builds with Gitlab-CI.
You can either set these environment variables in your build environment or overwrite the defaults like described above.

| Packer Variable         | Default Value | Description                                                                      |
| ----------------------- | ------------- | -------------------------------------------------------------------------------- |
| `iso_url`               | `https://...` | Link to the WS2022 installation ISO file (see `ws2022.pkr.hcl`)                  |
| `iso_checksum`          | `sha256:....` | SHA256 checksum of above ISO file (see `ws2022.pkr.hcl`)                         |
| `vcenter_server`        | NONE          | VMware vSphere vCenter to connect to for building with the `vsphere-iso` builder |
| `vcenter_user`          | NONE          | The user to connect with to the vCenter                                          |
| `vcenter_password`      | NONE          | Above user's password                                                            |
| `vcenter_datacenter`    | `null`        | The name of the vSphere datacenter to build in                                   |
| `vcenter_cluster`       | `null`        | The name of the cluster to build in                                              |
| `vcenter_resource_pool` | `null`        | The resource pool to create the VM in, if not specified uses the default pool    |
| `vcenter_datastore`     | `null`        | The resource pool to create the VM in, if not specified uses the default pool    |
| `esx_host`              | `null`        | The ESX to build on                                                              |

To specify the right vCenter parameters, check the [vsphere-iso documentation](https://www.packer.io/plugins/builders/vsphere/vsphere-iso#working-with-clusters-and-hosts)

The following variables are only taken into consideration on a Gitlab-CI build (see `.gitlab-ci.yml`) and not relevant if the packer build is called locally.

| Gitlab-CI variable | Default Value | Description                                                                                                                    |
| ------------------ | ------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `SMB_PATH`         | NONE          | Optional UNC path to the SMB share where to put the resulting OVA file - the user running Gitlab-Runner must have write access |

### How to use Packer

To create a Windows Server VM image using a vSphere ESX host:

```sh
cd <path-to-git-root-directory>
packer build ws2022.pkr.hcl
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

## Resources

- [packer-Win2019](https://github.com/eaksel/packer-Win2019) (used as a base for this work - big kudos!)
- [Hashicorp Windows Update Script](https://github.com/hashicorp/best-practices/blob/master/packer/scripts/windows/install_windows_updates.ps1)
- A lot of StackExchange, Blogs, etc... - thank you all for publishing about these great small gotchas which block me sometimes