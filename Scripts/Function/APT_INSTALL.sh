#!/bin/bash

#--How to USE--#
# APT_INSTALL_PPA_UPDATE_INSTALL "<PPA>" "<apt software code e.g. kdenlive>" "Package Display name in UI" "<package name in apt list>"
#--------------#
APT_INSTALL_PPA_UPDATE_INSTALL() {
	PPA=$1
	Software=$2
	Name=$3
	Aptlisting=$4
	
	#if already present, don't install
	if [[ $(which $Aptlisting | grep -w "$Aptlisting" | awk {'print $0'}) ]]; then
		zenity --info --timeout 5\
		--text="\n$Name Already Installed\t\t"\
		--title "Installed" --no-wrap 2>/dev/null
	else
		#Adding ppa
		(sudo add-apt-repository -y $PPA 2>/dev/null | \
		tee >(xargs -I % echo "#%")) | \
		zenity --progress --width=720 --pulsate --title="$Name: $PPA" \
		--no-cancel --auto-kill --auto-close 2>/dev/null
		
		#Refreshing apt
		APT_REFRESH
		
		#Installing
		(sudo apt-get -y install $Software 2>/dev/null | \
		tee >(xargs -I % echo "#%")) | \
		zenity --progress --width=720 --pulsate --title="$Name" \
		--no-cancel --auto-kill --auto-close 2>/dev/null
		
		#Installation Complete Dialog
		INSTALLATION_COMPLETE $Name
	fi		
}


#--How to USE--#
# APT_INSTALL_DIRECT "<apt software code e.g. git>" "Package Display name in UI" "<package name in apt list>"
#--------------#
APT_INSTALL_DIRECT() {
	Software=$1
	Name=$2
	Aptlisting=$3
	
	#if already present, don't install
	if [[ $(which $Aptlisting | grep -w "$Aptlisting" | awk {'print $0'}) ]]; then
		zenity --info --timeout 5\
		--text="\n$Name Already Installed\t\t"\
		--title "Installed" --no-wrap 2>/dev/null
	else
		#Installing
		(sudo apt -y install $Software 2>/dev/null | \
		tee >(xargs -I % echo "#%")) | \
		zenity --progress --width=720 --pulsate --title="$Name" \
		--no-cancel --auto-kill --auto-close 2>/dev/null
		
		#Installation Complete Dialog
		INSTALLATION_COMPLETE $Name
	fi
}


#--How to USE--#
# APT_INSTALL_WGET "<Refined static URL to download>""<Term in .deb package to search for>" "Package Display name in UI" "<package name in apt list>"
#--------------#
APT_INSTALL_WGET() {
	URL=$1
	DebTerm=$2
	Name=$3
	Aptlisting=$4
	
	#if already present, don't install
	if [[ $(which $Aptlisting | grep -w "$Aptlisting" | awk {'print $0'}) ]]; then
		zenity --info --timeout 5\
		--text="\n$Name Already Installed\t\t"\
		--title "Installed" --no-wrap 2>/dev/null
	else
		if [ $URL ];then
  			WGET_DOWNLOAD_URL_NAME "$URL" "$Name"
		else
  			dllink=$(zenity --entry --text "Your download link :" --width="350" --entry-text "" --title="Download $Name url")
  			if [ $dllink ];then
    				WGET_DOWNLOAD_URL_NAME "$dllink" "$Name"
  			fi
		fi

		#Find the name of the downloaded .deb package and Install it
		DEB_PKG=$(ls | grep $DebTerm)
		if [[ ! -z $DEB_PKG ]]; then	#if package exists, install
			DEB_PACKAGE_INSTALL_AND_CLEANUP $DEB_PKG
		else	
			#error message
			zenity --error --timeout 3\
			--text="\nPackage of $Name not found\t\t"\
			--title "Failed" --no-wrap 2>/dev/null
		fi
		
		#Installation Complete Dialog
		INSTALLATION_COMPLETE $Name
	fi
}


#--------------------------------------------------HELPERS--------------------------------------------------#

#Credits to https://gist.github.com/felix-orduz/79f284a4d51a0171eac8
#--How to USE--#
# WGET_DOWNLOAD_URL_NAME "URL" "Name of Software for Titlebar"
#--------------#
WGET_DOWNLOAD_URL_NAME() {
	rand="$RANDOM `date`"
	pipe="/tmp/pipe.`echo '$rand' | md5sum | tr -d ' -'`"
	mkfifo $pipe
	
	wget -c $1 2>&1 | while read data;do
		if [ "`echo $data | grep '^Length:'`" ]; then
			total_size=`echo $data | grep "^Length:" | sed 's/.*\((.*)\).*/\1/' |  tr -d '()'`
		fi
	
		if [ "`echo $data | grep '[0-9]*%' `" ];then
		
			percent=`echo $data | grep -o "[0-9]*%" | tr -d '%'`
			current=`echo $data | grep "[0-9]*%" | sed 's/\([0-9BKMG.]\+\).*/\1/' `
			speed=`echo $data | grep "[0-9]*%" | sed 's/.*\(% [0-9BKMG.]\+\).*/\1/' | tr -d ' %'`
			remain=`echo $data | grep -o "[0-9A-Za-z]*$" `
			echo $percent
			
			echo "#Downloading $1\n$current of $total_size ($percent%)\nSpeed : $speed/Sec\nEstimated time : $remain"
		fi
	done > $pipe &
 
	wget_info=`ps ax |grep "wget.*$1" |awk '{print $1"|"$2}'`
	wget_pid=`echo $wget_info|cut -d'|' -f1 `
 
	software=$2
	zenity --progress 2>/dev/null --no-cancel --auto-close --text="Connecting to $1\n\n\n" --width="720" --title="Downloading $software"< $pipe
	if [ "`ps -A |grep "$wget_pid"`" ];then
		kill $wget_pid
	fi
	
	rm -f $pipe
}


#--How to USE--#
# DEB_PACKAGE_INSTALL_AND_CLEANUP "<complete deb Package name>"
#--------------#
DEB_PACKAGE_INSTALL_AND_CLEANUP() {
	PKG_NAME=$1
	
	#Installing
	(sudo apt -y install ./$PKG_NAME 2>/dev/null | \
	tee >(xargs -I % echo "#%")) | \
	zenity --progress --width=720 --pulsate --title="Installing $PKG_NAME" \
	--no-cancel --auto-kill --auto-close 2>/dev/null
	
	#Cleaning up the .deb package after install
	sudo rm $PKG_NAME
}


#--How to USE--#
# APT_REFRESH
#--------------#
APT_REFRESH() {
	(sudo apt update 2>/dev/null | \
	tee >(xargs -I % echo "#%")) | \
	zenity --progress --width=720 --pulsate --title="Refreshing Apt List" \
	--no-cancel --auto-kill --auto-close 2>/dev/null
}


#--How to USE--#
# INSTALLATION_COMPLETE $VAR_NAME
#--------------#
INSTALLATION_COMPLETE() {
	Name=$1
	
	zenity --info --timeout 5\
	--text="\nInstallation Complete\t\t"\
	--title "$Name" --no-wrap 2>/dev/null
}