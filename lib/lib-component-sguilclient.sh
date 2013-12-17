#!/bin/bash
#
# Copyright (C) 2008-2009 SecurixLive   <dev@securixlive.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License Version 2 as
# published by the Free Software Foundation.  You may not use, modify or
# distribute this program under any other version of the GNU General
# Public License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# Description:
#   Handling of the installation, configuration, fixing and uninstallation of
# the sguil-client package and dependancies. 
#
#   sguil-client components are used on the Client component and is used to
# display all the collected/correlated information from the Sensor/Server
# components in a user friendly manner to an NSM analyst.
#
# Dependencies:
#   <= tcl
#

SGUIL_SRC_DIR="sguil-0.7.0"
SGUIL_TARBALL="sguil-0.7.0.tar.gz"
SGUIL_SRC_URL="http://downloads.sourceforge.net/sguil/sguil-0.7.0.tar.gz?modtime=1206487221&big_mirror=0"

nsm_package_sguilclient_required_options()
{
	# grab input variables with sane defaulting
    OPTIONS=${1:-1}
	
    for OPT in "GENERAL_DOWNLOAD_DIR" "GENERAL_SOURCE_DIR"
    do
	    required_option_set "$OPT"
    done
	
	if [ ${OPTIONS} -eq 1 ]
    then
		required_option_set "GENERAL_BIN_DIR"
		required_option_set "CLIENT_CONF_PATH"
		required_option_set "CLIENT_CONF_NAME"
		required_option_set "CLIENT_SRV_HOST"
		required_option_set "CLIENT_LIB_PATH"
    fi

	return 0
}

nsm_package_sguilclient_download()
{
   	prompt_user_yesno "" "Download sguilclient tools packages(s)?" "Y"
   	[ ${?} -ne 0 ] && return 1

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y -d install wireshark"
        print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
        if [ ${?} -ne 0 ]
        then
            return 1
        fi

        sguil_tarball_download
        return $?
    fi
    
    # check if we are a redhat'ish system
    is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		CMD="yum --downloadonly -y install wireshark wireshark-gnome"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
		#FIXME: yum's "--downloadonly" returns exit code 1 regardless of download success
  
        sguil_tarball_download
        return $?
	fi

	print_all "Not sure how to download sguilclient tools on this UNKNOWN system." 1
	return 1
}

nsm_package_sguilclient_reconfigure()
{
	# check if sguil source is available
#	if ( ! sguil_source_exists() )
#	{
#		utils::print_all("  sguil-client (sguil) source is NOT available", 2);
#		return 0;
#	}

	# check for pre-existing config file
	print_all "Checking for existing sguilclient config file: ${CLIENT_CONF_PATH}/${CLIENT_CONF_NAME}" 2
	if [ -f "${CLIENT_CONF_PATH}/${CLIENT_CONF_NAME}" ]
    then
		print_all "config file already exists" 3

        prompt_user_yesno "" "Overwrite existing configuration?" "N"
        [ ${?} -ne 0 ] && return 1

    fi

	# generate config file
	print_all "Generating sguil-client config file: ${CLIENT_CONF_PATH}/${CLIENT_CONF_NAME}" 1

        create_dir "${CLIENT_CONF_PATH}"
        if [ ${?} -ne 0 ]
        then
		print_all "unable to create client configuration path: ${CLIENT_CONF_PATH}" 3
            return 1
        fi

THE_TIME=$(date)
cat >${CLIENT_CONF_PATH}/${CLIENT_CONF_NAME} << EOF_CLIENT
# auto-generated by NSMnow on ${THE_TIME}
# Port to connect to the server on 
set SERVERPORT 7734 

# Server to connect to: 
# this can also be a space separated list of hosts (if you have more than one) 
#set SERVERHOST "demo.sguil.net localhost 10.0.0.2" 
set SERVERHOST ${CLIENT_SRV_HOST} 
# Where any required sguil libraries are (like the font chooser). 
set SGUILLIB ${CLIENT_LIB_PATH} 
# Debug 1=on 0=off This is VERY chatty 
set DEBUG 1 

# PATH to tls lib if needed (tcl can usually find this by default) 
#set TLS_PATH /usr/lib/tls1.4/libtls1.4.so 
# win32 example 
#set TLS_PATH "c:/tcl/lib/tls1.4/tls14.dll" 
# Path to a whois script. 
# awhois.sh is an example. Get it at ftp://ftp.weird.com/pub/local/awhois.sh 
# NEW: sguil.tk has a built in whois proc called SimpleWhois although 
# you can continue to use tools like awhois.sh. 
set WHOIS_PATH SimpleWhois 

# Configure optional external DNS here. An external DNS can be used as a 
# way to prevent data leakage. Some users would prefer to use anonymous 
# DNS as a way to keep potential malicious sources from knowing who is 
# interested in their activities. 

# Enable Ext DNS 
set EXT_DNS 1 
# Define the external nameserver to use. OpenDNS list 208.67.222.222 and 208.67.220.220 
set EXT_DNS_SERVER 208.67.222.222 
# Define a list of space separated networks (xxx.xxx.xxx.xxx/yy) that you want 
# to use the OS's resolution for. 
set HOME_NET "192.168.0.0/16 10.0.0.0/8" 

# If you have festival installed, then you can have alerts spoken to 
# you. Set the path to the festival binary here. If you are using 
# speechd from speechio.org, then leave this commented out. 
set FESTIVAL_PATH /usr/bin/festival 
# win32 example 
# set FESTIVAL_PATH "c:festivalbinfestival.exe" 
#set WHOIS_PATH /common/bin/awhois.sh 
# Path to wireshark (ethereal) 
set WIRESHARK_PATH /usr/bin/wireshark 
# win32 example 
# set WIRESHARK_PATH "c:/progra~1/wireshark/wireshark.exe" 
# Where to save the temporary raw data files on the client system 
# You need to remember to delete these yourself. 
set WIRESHARK_STORE_DIR /tmp 
# win32 example 
# set WIRESHARK_STORE_DIR "c:/tmp" 
# Favorite browser for looking at sig info on snort.org 
set BROWSER_PATH /usr/bin/firefox 
# win32 example (IE) 
# set BROWSER_PATH c:/progra~1/intern~1/iexplore.exe 

# Path to gpg 
set GPG_PATH /usr/local/bin/gpg 
# win32 example 
# set GPG_PATH "c:/gnupg" 

# How often in seconds to get sensor status updates 
# Default is 15 seconds 
set STATUS_UPDATES 15 
# Packet Data Search Frame shown by default? 
set SEARCHFRAME 1 
# Number of RealTime Event Panes 
set RTPANES 1
# Specify which priority events go into what pane 
# According to the latest classification.config from snort, 
# there are only 4 priorities. The sguil spp_portscan mod 
# uses a priority of 5. 
set RTPANE_PRIORITY(0) "1 2 3 4 5" 
#set RTPANE_PRIORITY(1) "2 3" 
#set RTPANE_PRIORITY(2) "4 5" 
# Number of different colors in the Status (ST) column. 
set RTCOLORS 3 
# If you defined 3 colors than you need 3 corresponding 
# definitions of which priority alerts have what color. 
set RTCOLOR_PRIORITY(0) "1" 
set RTCOLOR_PRIORITY(1) "2 3" 
set RTCOLOR_PRIORITY(2) "4 5" 
# Now define the colors 
set RTCOLOR_NAME(0) "red" 
set RTCOLOR_NAME(1) "orange" 
set RTCOLOR_NAME(2) "yellow" 
# Different colors for different incident categories 
set CATEGORY_COLOR(NA) "lightblue" 
set CATEGORY_COLOR(C1) "#cc0000" 
set CATEGORY_COLOR(C2) "#ff6600" 
set CATEGORY_COLOR(C3) "#ff9900" 
set CATEGORY_COLOR(C4) "#cc9900" 
set CATEGORY_COLOR(C5) "#9999cc" 
set CATEGORY_COLOR(C6) "#ffcc00" 
set CATEGORY_COLOR(C7) "#cc66ff" 
set CATEGORY_COLOR(ES) "pink" 
set CATEGORY_COLOR(UN) "white" 
# Customize the Select/highlight color 
set SELECTBACKGROUND "#ffffcc" 
set SELECTFOREGROUND black 
# Default Max Rows returned for portscan data. 
# Value can be changed within the GUI after init. 
# Set to 0 for no limit - use 0 at your own risk. 
set MAX_PS_ROWS 200 
# Display a GMT clock in the upper righthand corner 
# 1=on 0=off 
set GMTCLOCK 1 
# Mailserver to use for emailing alerts 
set MAILSERVER mail.example.com 
# If you need to define a hostname for the HELO set it here. 
# Otherwise your \`hostname\` will be used 
#set HOSTNAME host.example.com 
# Default From: address for emailing 
set EMAIL_FROM example@example.com 
# Default CC: 
set EMAIL_CC "" 
# Default Email Subject 
set EMAIL_SUBJECT "Incident Report" 
# Default Email Body Header 
set EMAIL_HEAD "Dear Hostmaster,n We recently detected a possible attack from an IP address that originates from your network. Please take appropriate action.nn All times are UTC and re accuraten" 
# Default Email Body Footer 
set EMAIL_TAIL "Please Reply to this Email Address with questions.n"
EOF_CLIENT

	return $?
}

nsm_package_sguilclient_fix()
{
	print_all "sguilclient has no fix options enabled" 2
}

nsm_package_sguilclient_install()
{
	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y install wireshark"
        print_all "Installing with: ${CMD}" 2
		system_log "${CMD}"
        if [ ${?} -ne 0 ]
        then
            return 1
        fi
   fi
    
    # check if we are a redhat'ish system
    is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		CMD="yum -y install wireshark wireshark-gnome"
		print_all "Installing with: ${CMD}" 2
		system_log "${CMD}"
		#FIXME: yum's "--downloadonly" returns exit code 1 regardless of download success
	fi

#	print_all "Not sure how to install sguilclient tool(s) on this system." 1
#	return 1

	# check it's presence and install if required
	print_all "Checking if sguilclient is installed" 2
    is_binary_installed "sguil.tk"
	if [ ${?} -eq 0 ]
    then
        print_all "sguilclient already installed" 2
		return 0
	fi

	# check if the source is present and download if necessary
	print_all "Checking sguilclient (sguil) source presence: ${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}" 2
    sguil_source_exists
    if [ ${?} -ne 0 ]
    then
		print_all "sguilclient source NOT found" 2
	
		# abort if tarball can not be obtained
        sguil_tarball_download
        if [ ${?} -ne 0 ]
        then
            return 1
        fi
		
		# extract the source tarball as required
		if [ ! -d "${GENERAL_SOURCE_DIR}" ]
        then
            create_dir "${GENERAL_SOURCE_DIR}"
            if [ ${?} -ne 0 ]
            then
                return 1
            fi
		fi

		CMD="tar -xzf ${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL} -C ${GENERAL_SOURCE_DIR}"
		print_all "Extracting sguilclient source with: ${CMD}" 3
		$CMD
		if [ ${?} -ne 0 ]
        then
			print_all "sguilclient source could NOT be obtained" 2
			return 1
		fi
	else
		print_all "sguilclient source found" 2
	fi

	# create the client lib directory if it doesn't exist
    create_dir "${CLIENT_LIB_PATH}"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# install the client library files
	print_all "Installing sguil-client library files" 1
    copy_and_cache_files "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}/client/lib" "**" "${CLIENT_LIB_PATH}" "" "" "sguilclient"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi
	
	# install the binary
	print_all "Installing sguil-client binary" 1
    copy_and_cache_files "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}/client" "sguil.tk" "${GENERAL_BIN_DIR}" "" "0755" "sguilclient"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi
	 
	# ensure it's installed
    is_binary_installed "sguil.tk"
	if [ ${?} -ne 0 ]
    then
        print_all "sguilclient is NOT installed" 2
		return 1
	fi

	print_all "sguilclient is installed" 2
	return 0
}

nsm_package_sguilclient_uninstall()
{
    cache_group_remove "sguilclient"
}

nsm_package_sguilclient_upgrade()
{
	print_all "sguilclient has no upgrade options enabled" 2
}

#
# LOCAL FUNCTIONS
#
sguil_source_exists()
{
	if [ -d "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}" ]
    then
        return 0
    fi

	return 1
}

sguil_tarball_exists()
{
	if [ -r "${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}" ]
    then
        return 0
    fi

	return 1
}

sguil_tarball_download()
{
	print_all "Checking sguilsensor tarball presence: ${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}" 2
	
	# check if we already have the file
    sguil_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sguilsensor tarball NOT found" 2

		print_all "Downloading sguilsensor tarball: ${SGUIL_SRC_URL}" 3
		download_file "${SGUIL_SRC_URL}" "${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}"
	else
		print_all "sguilsensor tarball found" 2
	fi

	# confirm we got the file
    sguilserver_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sguilsensor could NOT be downloaded" 2
		return 1
	fi

	return 0
}

