#!/bin/bash

version=$(uname -m)
directory=$(printf "%q\n" "$(pwd)")
wd=$directory/xmr
color='\033[1;33m'
nc='\033[0m'
line=0

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

rmfiles () {
  rm "$wd/LICENSE"
  rm "$wd/monero-blockchain-ancestry"
  rm "$wd/monero-blockchain-depth"
  rm "$wd/monero-blockchain-export"
  rm "$wd/monero-blockchain-import"
  rm "$wd/monero-blockchain-mark-spent-outputs"
  rm "$wd/monero-blockchain-prune"
  rm "$wd/monero-blockchain-prune-known-spent-data"
  rm "$wd/monero-blockchain-stats"
  rm "$wd/monero-blockchain-usage"
  rm "$wd/monerod"
  rm "$wd/monero-gen-ssl-cert"
  rm "$wd/monero-gen-trusted-multisig"
  rm "$wd/monero-wallet-cli"
  rm "$wd/monero-wallet-rpc"
}

updater () {
  msg="REMOVING OLD BACKUP AND MOVING CURRENT VERSION TO BACKUP FILE" && print
  rm -dr "$wd.bk"
  cp -r "$wd" "$wd.bk"
  rmfiles
  msg="EXTRACTING BINARY TO $wd" && print
  mkdir "$wd"
  tar -xjvf "$a1" -C "$wd" --strip-components=1
  rm "$keyname" "$hashfile" "$a1"
}

verifier () {
  rm "$keyname" "$hashfile"
  msg="DOWNLOADING SIGNING KEY AND VERIFYING SIGNING KEY" && print
  wget -O "$keyname" "$keyurl"
  if gpg --keyid-format long --with-fingerprint "$keyname" | grep -q "$fingerprint"; then
    msg="GOOD SIGNING KEY IMPORTING SIGNING KEY" && print
    gpg --import "$keyname"
    msg="DOWNLOADING THEN CHECKING THE HASH FILE" && print
    wget -O "$hashfile" "$hashurl"
    if gpg --verify "$hashfile"; then
      checkversion
      hash0=$(sed -n "$line"p "$hashfile" | cut -f 1 -d ' ')
      msg="THE TEXT FILE HASH IS $hash0 DOWNLOADING BINARYS" && print
      rm "$a1"
      wget "$url"
      hash1=$(shasum -a 256 "$a1" | cut -f 1 -d ' ') 
      msg="THE BINARY HASH IS $hash1 CHECKING MATCH" && print
      if [ "$hash1" = "$hash0" ] ; then
        msg="GOOD MATCH STARTING UPDATE" && print
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

checkversion () {
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
  if [ "$line" = '0' ] ; then
    msg="FAILED TO DETECT VERSION STOPPING NOW" && print
    exit 1
  fi
}

verifier
