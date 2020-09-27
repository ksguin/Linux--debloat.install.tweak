#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "Run with sudo";
	exit 0
else
	if [ -f .flagfile.txt ]; then
		if [[ $(head -1 ".flagfile.txt" | grep -wl "DONE" ) ]] ; then	#error
			:
		else
			rm .flagfile.txt
			echo "DONE" > .flagfile.txt
			sudo update-manager 2>/dev/null
		fi
	else
		echo "DONE" > .flagfile.txt
		sudo update-manager 2>/dev/null
	fi
fi

#Inclusion of Essential Scripts
source ./Scripts/Function/FIND_EXECUTE_SCRIPT.sh


# check if zenity is installed, if not install it
if [ "$(dpkg -l | awk '/zenity/ {print }'|wc -l)" -ge 1 ]; then
  	:
else
  	sudo apt install zenity -y
fi

# run only if a superuser
if [[ $EUID -ne 0 ]]; then
	#every zenity command will have height=480 and width=720 for the sake of uniformity
	zenity --error --icon-name=error --title="ROOT permission required!" --text="\nThis script requires ROOT permission. Run with sudo!" --no-wrap 2>/dev/null
	notify-send -u normal "ERROR" "Re-run "$(basename "$0")""
   	exit 1
else
	#Zenity Checklist for all the scripts
	SEL=$( zenity --list --checklist\
		2>/dev/null --height=480 --width=720\
		--text="Don't worry! You will get sub-choices for each selection."\
		--ok-label "Start" --cancel-label "Exit"\
		--column "Pick" --column "Operation" 	--column "Description"\
		TRUE		LANGUAGE		"Tweaks Language Settings"\
		TRUE 		FONT			"Deletes Unnecessary Fonts"\
		TRUE 		BLOATWARE 		"Deletes Pre-installed Softwares"\
		TRUE		INSTALL			"Installs Your Preferred Softwares"\
		FALSE		"ADDITIONAL TWEAKS"	"Some Additional System Settings" );

	# pressed Cancel or closed the dialog window 
	if [[ $? -eq 1 ]]; then 
  		zenity --warning --title="Cancelled"\
		--text "\nOperation cancelled by user. Nothing will be done!"\
		2>/dev/null --no-wrap
	elif [[ -z "$SEL"  ]]; then
		zenity --warning\
		--text "\nNo Option Selected. Nothing will be done!"\
		2>/dev/null --no-wrap
	else
		#this is mandatory for the space in checklist to work eg. "ADDITIONAL TWEAKS"
		IFS=$'\n'

		for option in $(echo $SEL | tr "|" "\n"); do

			case $option in

			"LANGUAGE")	#Language setup script
					FIND_EXECUTE_SCRIPT /Scripts/ delete_language.sh
				;;

			"FONT")		#Font deletion script
					FIND_EXECUTE_SCRIPT /Scripts/ delete_font.sh
				;;

			"BLOATWARE")	#Bloatware deletion script
					FIND_EXECUTE_SCRIPT /Scripts/ delete_bloat.sh
				;;

			"INSTALL")	#Software Installation script
					FIND_EXECUTE_SCRIPT /Scripts/ install_software.sh
				;;

			"ADDITIONAL TWEAKS") 	#Additonal Settings Script
					FIND_EXECUTE_SCRIPT /Scripts/ additional_tweaks.sh
				;;
			esac
		done	
		
	fi
	unset IFS

	if [[ ! -z $SEL ]]; then
		#notify-send cannot work as root
		USER=$(cat /etc/passwd|grep 1000|sed "s/:.*$//g");
		su $USER -c "/usr/bin/notify-send -u normal 'Complete' 'Enjoy your system!'"
	fi
fi
