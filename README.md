HandShaker
==========
handshaker - Detect, deauth, capture and crack WPA/2 handshakes
	       - Record AP location with Android GPS over adb
		
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
			 handshaker -a -i wlan0 -d 5			       ~ Autobot mode on wlan0 and deauth 5 times.
			 handshaker -e Hub3-F -w wordlist.txt	 	   ~ Find AP like 'Hub3-F' and crack with wordlist.
			 handshaker -l -o out/dir			           ~ List all APs and save handshakes to out/dir.
			 handshaker -c handshake.cap -w wordlist.txt   ~ Crack handshake.cap with wordlist.
