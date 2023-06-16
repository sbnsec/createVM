#!/bin/bash

PROGRAM_NAME=$(basename $0)
PROGRAM_TITLE="Create VMware virtual machines from the command line"
PROGRAM="$PROGRAM_NAME $PROGRAM_VER"
LOGFILE=createvm.log
BINARIES=(vmware-vdiskmanager)
BINARY_TESTS=yes

# Default VM parameters
VM_CONF_VER=8           # VM Config version
VM_VMHW_VER=4           # VM Hardware version
VM_RAM=256              # Default RAM
VM_NVRAM=nvram          # Default bios file
VM_ETH_TYPE=bridged     # Default network type
VM_MAC_ADDR=default     # Default MAC address
VM_DISK_SIZE=8          # Default DISK size (GB's)
VM_DISK_TYPE=SCSI       # Default DISK type
VM_USE_USB=FALSE        # Enable USB
VM_USE_SND=FALSE        # Enable sound
VM_USE_CDD=FALSE        # Enable CD drive
VM_USE_ISO=FALSE        # Enable and load ISO 
VM_USE_FDD=FALSE        # Enable and load FDD
VM_VNC_PASS=FALSE       # VNC password
VM_VNC_PORT=FALSE       # VNC port 

# This is the list of supported OS
SUPPORT_OS=(AlmaLinux-OS-8 AlmaLinux-OS-9 Amazon-Linux-2 Asianux-3.0 \
Asianux-4.0 Asianux-7.0 CentOS4 CentOS5 CentOS6 CentOS7 \
CentOS8 Debian10 Debian11 Debian12 Debian7 Debian8 \
Debian9 Debian-GNU/Linux6.0 eComStation1 eComStation2 \
Fedora16 Fedora17 Fedora18 Fedora19 Fedora28 Fedora31 \
Fedora32 Fedora33 Fedora34 Fedora37 FlatcarLTS \
FreeBSD10 FreeBSD11 FreeBSD12 FreeBSD13 FreeBSD7 \
FreeBSD8 FreeBSD9 KylinLinuxAdvancedServerV10 \
macOS10.12 macOS10.13 macOS10.14 macOS10.15 macOS11 \
macOS12 macOS13 MIRACLELINUX8 openSUSE12 openSUSELeap15 \
openSUSELeap42 OracleLinux4 OracleLinux5 OracleLinux6 \
OracleLinux7 OracleLinux8 OracleLinux9 Orel2.12 Pardus21 \
PhotonOS1 PhotonOS2 PhotonOS3 PhotonOS4 PhotonOS5 ProLinux7 \
ProLinux8 RedHatEnterpriseLinux4 RedHatEnterpriseLinux5 \
RedHatEnterpriseLinux6 RedHatEnterpriseLinux7 RedHatEnterpriseLinux8 \
RedHatEnterpriseLinux9 RockyLinux8 RockyLinux9 SCOOpenServer5 \
SCOUnixWare7 Solaris10 Solaris11 SUSELinuxEnterprise10 \
SUSELinuxEnterprise11 SUSELinuxEnterprise12 SUSELinuxEnterprise15 \
SUSELinuxEnterprise9 Ubuntu14.04 Ubuntu16.04 Ubuntu18.04 Ubuntu20.04 \
Ubuntu20.10 Ubuntu21.04 Ubuntu21.10 Ubuntu22.04 Ubuntu22.10 \
Ubuntu23.04 UnionTechOSDesktop20 UnionTechOSServer20 Windows10 \
Windows11 Windows2000 Windows7 Windows8 WindowsServer2003 \
WindowsServer2008 WindowsServer2012 WindowsServer2016 WindowsServer2019 \
WindowsServer2022 WindowsVista WindowsXP)

# Some color codes
COL_EMR="\033[1;31m"    # Bold red
COL_EMG="\033[1;32m"    # Bold green
COL_EMW="\033[1;37m"    # Bold white
COL_RESET="\033[0;00m"  # Default colors

### Main functions ###

# Show version log_info
function version() {
    echo -e "${COL_EMW}$PROGRAM - $PROGRAM_TITLE${COL_RESET}"
    echo -e $PROGRAM_COPYRIGHT
}
# Print status message
function log_status() {
    echo -ne "    $1 "
}
# Print if cmd returned oke or failed
function check_status() {
    if [[ $? -ne 0 ]] ; then
        echo -e "${COL_EMR}[FAILED]${COL_RESET}"
        exit 1;
    else
        echo -e "${COL_EMG}[OK]${COL_RESET}"
    fi
}
# Print normal message
function log_message() {
    echo -e "    $1 "
}
# Print highlighted message
function log_info() {
    echo -e "${COL_EMW}    $1${COL_RESET} "
}

### Specific funtions ###

# Print Help message
function usage() {
    echo "Affichage de l'aide" >> $LOGFILE
    echo -e "${COL_EMW}$PROGRAM - $PROGRAM_TITLE${COL_RESET}
Usage: $PROGRAM_NAME GuestOS OPTIONS
VM Options:
 -n, --name [NAME]              Friendly name of the VM       (default: <os-type>-vm)
 -r, --ram [SIZE]               RAM size in MB                (default: $VM_RAM)
 -d, --disk-size [SIZE]         HDD size in GB                (default: $VM_DISK_SIZE)
 -t, --disk-type [TYPE]         HDD Interface, SCSI or IDE    (default: $VM_DISK_TYPE)
 -e, --eth-type [TYPE]          Network Type (bridge/nat/etc) (default: $VM_ETH_TYPE)
 -i, --iso [FILE]               Enable CDROM Iso              (default: $VM_USE_ISO)
 
Program Options:
 -w, --working-dir [PATH]       Path to use as Working Dir    (default: current working dir)
 -l, --list                     Generate a list of VMware Guest OS'es
 
 -h, --help                     This help screen
 -v, --version                  Shows version information
 -ex, --sample                  Show some examples 
Dependencies:
This program needs the following binaries in its path: ${BINARIES[@]}"
}

# Show some examples
function print_examples(){
    echo "Affichage des exemples" >> $LOGFILE
    echo -e "${COL_EMW}$PROGRAM - $PROGRAM_TITLE${COL_RESET}
Here are some examples:
 Create an Ubuntu Linux machine with a 20GB hard disk and a different name
   $ $PROGRAM_NAME ubuntu -d 20 -n \"My Ubuntu VM\"
 Create a Linux machine with default parameters in a different directory
   $ $PROGRAM_NAME linux -w /home/user/vms"
}

function _summary_item() {
    local item=$1
    shift;
    printf "    %-26s" "$item"
    echo -e "${COL_EMW} $* ${COL_RESET}"
}

# Print a summary with some of the options on the screen
function show_summary(){
    log_info "I am about to create this Virtual Machine:"
    _summary_item "Guest OS" $VM_OS_TYPE
    _summary_item "Display name" $VM_NAME
    _summary_item "RAM (MB)" $VM_RAM
    _summary_item "HDD (Gb)" $VM_DISK_SIZE
    _summary_item "HDD interface" $VM_DISK_TYPE
    _summary_item "BIOS file" $VM_NVRAM
    _summary_item "Ethernet type" $VM_ETH_TYPE
    _summary_item "Mac address" $VM_MAC_ADDR
    _summary_item "Floppy disk" $VM_USE_FDD
    _summary_item "CD/DVD drive" $VM_USE_CDD
    _summary_item "CD/DVD image" $VM_USE_ISO
    _summary_item "USB device" $VM_USE_USB
    _summary_item "Sound Card" $VM_USE_SND
    _summary_item "VNC Port" $VM_VNC_PORT
    _summary_item "VNC Password" $VM_VNC_PASS
}

function add_config_param() {
    if [ -n "$1" ] ; then
        local item=$1
        shift;
        [ -n "$1" ] && CONFIG_PARAM="$CONFIG_PARAM\n$item = \"$@\""
        return
    fi
    # if empty, then reset the config params
    CONFIG_PARAM=""
}

function print_config() {
    echo "Ecriture du fichier .vmx" >> $LOGFILE
    echo -e $CONFIG_PARAM > "$VM_VMX_FILE"
}

# Create the .vmx file
function create_conf(){
    log_status "Creating config file...   "

    add_config_param config.version $VM_CONF_VER
    add_config_param virtualHW.version $VM_VMHW_VER
    add_config_param displayName $VM_NAME
    add_config_param guestOS $VM_OS_TYPE
    add_config_param memsize $VM_RAM

    if [ ! $VM_NVRAM = "nvram" ]; then
        FILENAME=$(basename $VM_NVRAM)
        cp $VM_NVRAM "$WORKING_DIR/$FILENAME"
        add_config_param nvram $FILENAME
    else
        add_config_param nvram $VM_NVRAM
    fi

    add_config_param ethernet0.present TRUE
    add_config_param ethernet0.connectionType $VM_ETH_TYPE

    if [ ! $VM_MAC_ADDR = "default" ]; then
        add_config_param ethernet0.addressType static
        add_config_param ethernet0.address $VM_MAC_ADDR
    else
        add_config_param ethernet0.addressType generated
    fi

    if [ ! $VM_DISK_TYPE = "IDE" ]; then
        add_config_param scsi0:0.present TRUE
        add_config_param scsi0:0.fileName $VM_DISK_NAME
    else 
        add_config_param ide0:0.present TRUE
        add_config_param ide0:0.fileName $VM_DISK_NAME
    fi

    if [ ! $VM_USE_USB = "FALSE" ]; then
        add_config_param usb.present TRUE
        add_config_param usb.generic.autoconnect FALSE
    fi

    if [ ! $VM_USE_SND = "FALSE" ]; then
        add_config_param sound.present TRUE
        add_config_param sound.fileName -1
        add_config_param sound.autodetect TRUE
        add_config_param sound.startConnected FALSE
    fi

    if [ ! $VM_USE_FDD = "FALSE" ]; then
        add_config_param floppy0.present TRUE
        add_config_param floppy0.startConnected FALSE
    else
        add_config_param floppy0.present FALSE
    fi

    if [ ! $VM_USE_CDD = "FALSE" ]; then
        add_config_param ide0:1.present TRUE
        add_config_param ide0:1.fileName auto detect
        add_config_param ide0:1.autodetect TRUE
        add_config_param ide0:1.deviceType cdrom-raw
        add_config_param ide0:1.startConnected FALSE
    fi

    if [ ! $VM_USE_ISO = "FALSE" ]; then
        add_config_param ide1:0.present TRUE
        add_config_param ide1:0.fileName $VM_USE_ISO
        add_config_param ide1:0.deviceType cdrom-image
        add_config_param ide1:0.startConnected TRUE
        add_config_param ide1:0.mode persistent
    fi

    if [ ! $VM_VNC_PASS = "FALSE" ]; then
        add_config_param remotedisplay.vnc.enabled TRUE
        add_config_param remotedisplay.vnc.port $VM_VNC_PORT
        add_config_param remotedisplay.vnc.password $VM_VNC_PASS
	
    fi

    add_config_param annotation "This VM is created by $PROGRAM"

    print_config
    check_status
}

# Create the working dir
function create_working_dir(){
    log_info "Creating Virtual Machine..."
    log_status "Creating working dir...   "
    mkdir -p "$WORKING_DIR" 1> /dev/null
    check_status
}
# Create the virtual disk
function create_virtual_disk(){
    log_status "Creating virtual disk...  "
    local adapter=buslogic
    [ "$VM_DISK_TYPE" = "IDE" ] && adapter=ide
    vmware-vdiskmanager -c -a $adapter -t 1 -s $VM_DISK_SIZE "$WORKING_DIR/$VM_DISK_NAME" >> $LOGFILE
    check_status
}
# Print OS list.
function list_guest_os() {
    echo "Affichage des OS supportés" >> $LOGFILE
    echo "List of Guest Operating Systems:"

    local max="${#SUPPORT_OS[@]}"
    for ((i=0;i < max; i=i+3)) ; do
        printf "%-25s %-25s %-25s\n" ${SUPPORT_OS[$i]} ${SUPPORT_OS[$((i + 1))]} ${SUPPORT_OS[$((i + 2))]}
    done
}
# Check if selected OS is in the OS list
function run_os_test(){
    local OS
    for OS in ${SUPPORT_OS[@]} ; do 
        # Everything OK, no need to continue
        [ $OS = "$VM_OS_TYPE" ] && return
    done
    log_info "Guest OS \"$VM_OS_TYPE\" is unknown..."
    log_message "Run \"$PROGRAM_NAME -l\" for a list of Guest OS'es..."
    log_message "Run \"$PROGRAM_NAME -h\" for help..."
    log_message "Run \"$PROGRAM_NAME -ex\" for examples..."
    exit 1
}
# Check for binaries and existance of previously created VM's
function run_tests(){
    # Check for needed binaries
    if [ "$BINARY_TESTS" = "yes" ]; then
        log_info "Checking binaries..."
        local app
        for app in ${BINARIES[@]} ; do
            log_status ""
            printf " - %-22s " "$app..."
            which $app 1> /dev/null
            check_status
        done
    fi
    # Check if working dir file exists
    log_info "Checking files and directories..."
    if [ -e "$WORKING_DIR" ]; then
        log_info "Working dir already exists, i will trash it!"
        log_status "Trashing working dir...   "
        rm -rf "$WORKING_DIR" 1>/dev/null
        check_status
    fi
}

### FLow start here

# Print date of launch in logfile
echo "Date de dernier lancement du script : `date`" > $LOGFILE

# Chatch some parameters if the first one is not the OS.
if [ "$1" = "" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then usage; exit; fi
if [ "$1" = "-v" ] || [ "$1" = "--version" ];     then version; exit; fi
if [ "$1" = "-l" ] || [ "$1" = "--list" ];     then list_guest_os; exit 1; fi
if [ "$1" = "-ex" ] || [ "$1" = "--sample" ];     then print_examples; exit 1; fi

# The first parameter is the Guest OS Type
VM_OS_TYPE="$1"

# Set default VM Name
VM_NAME="$VM_OS_TYPE-vm"

# Run OS test to see if provided os is suppported
run_os_test

# Shift through all parameters to search for options
shift
while [ "$1" != "" ]; do
    case $1 in
    -d | --disk-size )
        shift
        VM_DISK_SIZE=$1
    ;;
    -e | --eth-type )
        shift
        VM_ETH_TYPE=$1
    ;;
    -i | --iso )
        shift
        VM_USE_ISO=$1
    ;;
    -n | --name )
        shift
        VM_NAME="$1"
    ;;
    -r | --ram )
        shift
        VM_RAM=$1
    ;;
    -t | --disk-type )
        shift
        VM_DISK_TYPE=$1
    ;;
    -v | --version )
        version
    ;;
    -w | --working-dir )
        shift
        DEFAULT_WRKPATH=$1
    ;;
    * )
        log_error "what do you mean by \"$*\"?"
        log_message "Run \"$PROGRAM_NAME -h\" for help"
        log_message "Run \"$PROGRAM_NAME -ex\" for examples..."
        exit 1
    esac
    shift
done

# The last parameters are set
WORKING_DIR="$DEFAULT_WRKPATH/$VM_NAME"
VM_VMX_FILE="$WORKING_DIR/$VM_OS_TYPE.vmx"
VM_DISK_NAME="$VM_DISK_TYPE-$VM_OS_TYPE.vmdk"
VM_DISK_SIZE="$VM_DISK_SIZE""Gb"

# Print banner
version
# Display summary
show_summary
# Do some tests like checking binaries and previously created VMs
run_tests

# Create working environment
create_working_dir
# Write config file
create_conf
# Create virtual disk
create_virtual_disk