# Variables that need to be set for the build
variable "vcenter_server" {
  type    = string
  description = "The hostname of the vCenter server to use for building"
}

variable "vcenter_user" {
  type    = string
  description = "The username to use when connecting to the vCenter"
}

variable "vcenter_password" {
  type    = string
  sensitive = true
  description = "The password for the vCenter user"
}

variable "vcenter_datacenter" {
  type    = string
  description = "The name of the datacenter within vCenter to build in"
}

variable "esx_host" {
  type    = string
  description = "The hostname of the ESX to build on"
}

variable "esx_user" {
  type    = string
  description = "The username to connect with to the ESX server"
}

variable "esx_password" {
  type    = string
  sensitive = true
  description = "The password for the ESX user"
}

# Other variables for easy adaption

variable "iso_checksum" {
  type    = string
  default = "sha256:4f1457c4fe14ce48c9b2324924f33ca4f0470475e6da851b39ccbf98f44e7852"
  description = "The checksum for the ISO specified in `iso_url`"
}

variable "iso_url" {
  type    = string
  default = "https://software-download.microsoft.com/download/sg/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
  description = "The download url for the installation ISO"
}

variable "boot_wait" {
  type    = string
  default = "3s"
  description = "The time to wait after boot of the VM to start doing anything"
}

variable "disk_size" {
  type    = number
  default = 65536
  description = "The size of the generated VMDK in MB"
}

variable "memsize" {
  type    = number
  default = 4096
  description = "The memory size for the template VM in MB"
}

variable "numcores" {
  type    = number
  default = 2
  description = "The number of cores for the new template VM"
}

variable "numsockets" {
  type    = number
  default = 1
  description = "The number of sockets for the new template VM"
}

variable "os_password" {
  type    = string
  default = "Passw0rd."
  description = "The password for the OS user to be used when connecting to the deployed VM"
}

variable "os_user" {
  type    = string
  default = "Administrator"
  description = "The username to connect with to the newly delpoyed OS"
}

variable "vm_name" {
  type    = string
  default = "ws2022"
  description = "The name of the VM when building"
}

variable "vm_notes" {
  type    = string
  default = "by Stefan Zimmermann"
  description = "Notes appearing for each deployed VM"
}

packer {
  required_plugins {
    vsphere = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/vsphere"
    }
  }
}

source "vsphere-iso" "ws2022" {
  CPUs                 = ${var.numcores}
  RAM                  = ${var.memsize}
  boot_command         = ["w"]
  boot_wait            = "${var.boot_wait}"
  communicator         = "ssh"
  cpu_cores            = ${var.numcores}
  datacenter           = "${var.vcenter_datacenter}"
  disk_controller_type = ["pvscsi"]
  export {
    force            = true
    output_directory = "./build"
  }
  firmware            = "efi"
  floppy_files        = ["configs/autounattend.xml", "configs/sysprep-autounattend.xml", "scripts/install-vmware-tools-from-iso.ps1"]
  guest_os_type       = "windows2019srvNext_64Guest"
  host                = "${var.esx_host}"
  insecure_connection = true
  iso_checksum        = "${var.iso_checksum}"
  iso_paths           = ["[] /vmimages/tools-isoimages/windows.iso"]
  iso_url             = "${var.iso_url}"
  network_adapters {
    network      = "VM Network"
    network_card = "vmxnet3"
  }
  notes                     = "${var.vm_notes}"
  password                  = "${var.vcenter_password}"
  remove_cdrom              = true
  shutdown_command          = "C:\\Windows\\system32\\Sysprep\\sysprep.exe /generalize /oobe /shutdown /unattend:A:\\sysprep-autounattend.xml"
  shutdown_timeout          = "60m"
  ssh_clear_authorized_keys = true
  ssh_password              = "${var.os_password}"
  ssh_timeout               = "1h"
  ssh_username              = "${var.os_user}"
  storage {
    disk_size             = ${var.disk_size}
    disk_thin_provisioned = true
  }
  username       = "${var.vcenter_user}"
  vcenter_server = "${var.vcenter_server}"
  vm_name        = "${var.vm_name}"
  vm_version     = 18
}

build {
  name = "ws2022"

  sources = ["source.vsphere-iso.ws2022"]

  provisioner "powershell" {
    scripts          = ["scripts/win-update.ps1"]
    valid_exit_codes = [0, 2300218]
  }

  provisioner "windows-restart" {
    pause_before    = "30s"
    restart_timeout = "30m"
  }

  provisioner "powershell" {
    scripts = ["scripts/win-update.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "powershell" {
    scripts = ["scripts/adjustments.ps1"]
  }

  provisioner "powershell" {
    scripts = ["scripts/cleanup.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

}
