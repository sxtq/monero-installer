#!/bin/bash

	dir=$(printf "%q\n" "$(pwd)")
        wd=$dir/xmr
	fp="81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92"
	vrs=$(uname -m)
	wallet=xmr
        YELLOW='\033[1;33m'
        NC='\033[0m'

	keyname=binaryfate.asc
	keyurl=https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc
	hashurl=https://www.getmonero.org/downloads/hashes.txt
	
	cliurl0=https://downloads.getmonero.org/cli/linux64
	cliurl1=https://downloads.getmonero.org/cli/linuxarm7
	cliurl2=https://downloads.getmonero.org/cli/linuxarm8
	
alert ()
{
        echo -e "${YELLOW}$msg${NC}"
}

updater ()
{
	msg="REMOVING OLD BACKUP AND MOVING CURRENT VERSION TO BACKUP FILE" && alert
        rm -dr "$wd.bk"
        mv "$wd" "$wd.bk"
        mkdir "$wd"
	cp "$wd.bk/$wallet" "$wd"
	cp "$wd.bk/$wallet.keys" "$wd"

	msg="EXTRACTING BINARY TO XMR DIRECTORY" && alert
        tar -xjvf "$a1" -C "$wd" --strip-components=1
        rm "$a1"
	exit 1
}

verifier ()
{
	if [ $vrs = 'x86_64' ]; then
        	a1=linux64
        	url=$cliurl0
        	line=16
		msg="MONEROD VERSION SET TO $a1" && alert
	fi
	if [ $vrs = 'armv7l' ]; then
        	a1=linuxarm7
        	url=$cliurl1
        	line=14
		msg="MONEROD VERSION SET TO $a1" && alert
	fi
	if [ $vrs = 'armv8l' ]; then
        	a1=linuxarm8
        	url=$cliurl2
        	line=15
		msg="MONEROD VERSION SET TO $a1" && alert
	fi

        msg="DOWNLOADING SIGNING KEY AND VERIFYING SIGNING KEY" && alert
        wget -O "$keyname" "$keyurl"
        if gpg --keyid-format long --with-fingerprint "$keyname" | grep -q "$fp"; then
		msg="GOOD SIGNING KEY IMPORTING SIGNING KEY" && alert
                gpg --import "$keyname"

		msg="DOWNLOADING HASH FILES AND CHECKING THE HASH FILE" && alert
                wget -O hashes.txt "$hashurl"
                if gpg --verify hashes.txt; then
                        hash=$(sed $line'q;d' hashes.txt | cut -f 1 -d ' ')
			msg="THE HASH IS $hash DOWNLOADING BINARYS" && alert 
                        rm $a1
			wget $url
                        sh=$(shasum -a 256 $a1 | cut -f 1 -d ' ') 
			msg="THE SHASUM IS $sh CHECKING MATCH" && alert
                        if [ "$sh" = "$hash" ]; then
				msg="GOOD MATCH STARTING UPDATE" && alert
                                rm hashes.txt "$keyname"
                                updater
                        else
				msg="FAILED MATCH STOPPING UPDATER" && alert
                        fi
                else
			msg="FAILED TO VERIFY HASHES STOPPING UPDATER" && alert
                fi
        else
		msg="FAILED TO VERIFY SIGNING KEY STOPPING UPDATER" && alert
        fi
}

verifier
