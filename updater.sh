#!/bin/bash

wallet=xmr
version=$(uname -m)
directory=$(printf "%q\n" "$(pwd)")
wd=$directory/xmr
color='\033[1;33m'
nc='\033[0m'

fingerprint="81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92"
keyname=binaryfate.asc
keyurl=https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc
hashurl=https://www.getmonero.org/downloads/hashes.txt
hashfile=hashes.txt

#x86_64 CLI URL
url0=https://downloads.getmonero.org/cli/linux64
#arm7 CLI URL
url1=https://downloads.getmonero.org/cli/linuxarm7
#arm8 CLI URL
url2=https://downloads.getmonero.org/cli/linuxarm8
	
print () {
  echo -e "${color}$msg${nc}"
}

updater () {
  msg="REMOVING OLD BACKUP AND MOVING CURRENT VERSION TO BACKUP FILE" && print
  rm -dr "$wd.bk"
  mv "$wd" "$wd.bk"
  mkdir "$wd"
  cp "$wd.bk/$wallet" "$wd"
  cp "$wd.bk/$wallet.keys" "$wd"
  msg="EXTRACTING BINARY TO XMR DIRECTORY" && print
  tar -xjvf "$a1" -C "$wd" --strip-components=1
  rm "$a1"
}

verifier () {
  if [ "$version" = 'x86_64' ] ; then
    a1=linux64
    url=$url0
    line=$(grep -n monero-linux-x64 "$hashfile" | cut -d : -f 1)
    msg="MONEROD VERSION SET TO $a1" && print
  fi
  if [ "$version" = 'armv7l' ] ; then
    a1=linuxarm7
    url=$url1
    line=$(grep -n monero-linux-armv7 "$hashfile" | cut -d : -f 1)
    msg="MONEROD VERSION SET TO $a1" && print
  fi
  if [ "$version" = 'armv8l' ] ; then
    a1=linuxarm8
    url=$url2
    line=$(grep -n monero-linux-armv8 "$hashfile" | cut -d : -f 1)
    msg="MONEROD VERSION SET TO $a1" && print
  fi
  msg="DOWNLOADING SIGNING KEY AND VERIFYING SIGNING KEY" && print
  rm "$keyname"
  wget -O "$keyname" "$keyurl"
  if gpg --keyid-format long --with-fingerprint "$keyname" | grep -q "$fingerprint"; then
    msg="GOOD SIGNING KEY IMPORTING SIGNING KEY" && print
    gpg --import "$keyname"
    msg="DOWNLOADING THEN CHECKING THE HASH FILE" && print
    rm "$hashfile"
    wget -O "$hashfile" "$hashurl"
    if gpg --verify "$hashfile"; then
      hash0=$(sed $line'q;d' "$hashfile" | cut -f 1 -d ' ')
      msg="THE TEXT FILE HASH IS $hash0 DOWNLOADING BINARYS" && print 
      rm $a1
      wget $url
      hash1=$(shasum -a 256 $a1 | cut -f 1 -d ' ') 
      msg="THE BINARY HASH IS $hash1 CHECKING MATCH" && print
      if [ "$hash1" = "$hash0" ] ; then
        msg="GOOD MATCH STARTING UPDATE" && print
        rm "$hashfile" "$keyname"
        updater
      else
        msg="FAILED MATCH STOPPING UPDATER" && print
      fi
    else
      msg="FAILED TO VERIFY HASHES STOPPING UPDATER" && print
    fi
  else
    msg="FAILED TO VERIFY SIGNING KEY STOPPING UPDATER" && print
  fi
}

verifier

