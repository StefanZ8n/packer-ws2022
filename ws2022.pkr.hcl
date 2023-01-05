packer {
  required_plugins {
    vsphere = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/vsphere"
    }
  }
}

source "vsphere-iso" "ws2022" {
  # Deployment Connection Details
  vcenter_server = "${var.vcenter_server}"
  username = "${var.vcenter_user}"
  password = "${var.vcenter_password}"
  datacenter = "${var.vcenter_datacenter}"
  cluster = "${var.vcenter_cluster}"
  host = "${var.esx_host}"
  datastore = "${var.vcenter_datastore}"

  http_ip = "${var.http_ip}"
  http_directory = "./resources"

  insecure_connection = true

  # VM Details
  vm_name = "${var.vm_name}"
  vm_version = 18
  guest_os_type = "windows2019srvNext_64Guest"
  CPUs = "${var.numcores}"
  cpu_cores = "${var.numcores}"  
  RAM = "${var.memsize}"
  firmware = "efi"
  disk_controller_type = ["pvscsi"]
  network_adapters {
    network = "VM Network"
    network_card = "vmxnet3"
  }
  storage {
    disk_size = "${var.disk_size}"
    disk_thin_provisioned = true
  }
  notes = "${var.vm_notes}"  
  remove_cdrom = true

  # Boot details
  iso_checksum = "${var.iso_checksum}"
  iso_paths = ["[] /vmimages/tools-isoimages/windows.iso"]
  iso_url = "${var.iso_url}"

  boot_wait = "${var.boot_wait}"  
  boot_command = var.boot_command

  cd_files = ["resources/configs/autounattend.xml", "resources/configs/sysprep-autounattend.xml", "resources/scripts/install-vmware-tools-from-iso.ps1"]
  
   # OS Connection Details
  communicator = "ssh"  
  ssh_clear_authorized_keys = true
  ssh_password = "${var.os_password}"
  ssh_timeout = "1h"
  ssh_username = "${var.os_user}"
  
  shutdown_command = "C:\\Windows\\system32\\Sysprep\\sysprep.exe /generalize /oobe /shutdown /unattend:F:\\sysprep-autounattend.xml"  
  shutdown_timeout = "60m"
  
  export {
    force            = true
    output_directory = "./build"
    options          = ["nodevicesubtypes"]
  }
}

build {
  name = "ws2022"

  sources = ["source.vsphere-iso.ws2022"]

  provisioner "powershell" {
    scripts          = ["resources/scripts/win-update.ps1"]
    valid_exit_codes = [0, 2300218]
  }

  provisioner "windows-restart" {
    pause_before    = "30s"
    restart_timeout = "30m"
  }

  provisioner "powershell" {
    scripts = ["resources/scripts/win-update.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "powershell" {
    scripts = ["resources/scripts/adjustments.ps1"]
  }

  provisioner "powershell" {
    scripts = ["resources/scripts/cleanup.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

}
