#!/bin/bash

version=$(uname -m) #version=1 for 64-bit, 2 for arm7 and 3 for arm8 or version=$(uname -m) for auto detect
directory=$(printf "%q\n" "$(pwd)")
wd=$directory/xmr #To set manually use this example wd=/home/myUser/xmr

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

#Used for printing text on the screen
print () {
  color='\033[1;33m'
  nc='\033[0m'
  echo -e "${color}$msg${nc}"
}

#This will remove all filles here from the xmr directory and replace them with updated versions
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
  #rm "$wd/monero-wallet-cli.log"
}

#This makes the backup and removes old files then extracts the verifed binary to the xmr directory
updater () {
  msg="Removing old backup and moving current version to backup file" && print
  rm -dr "$wd.bk"
  cp -r "$wd" "$wd.bk"
  rmfiles
  msg="Extracting binary to $wd" && print
  mkdir "$wd"
  tar -xjvf "$a1" -C "$wd" --strip-components=1
  rm "$keyname" "$hashfile" "$a1"
}

#This verifies the binary, signing key and hash file
verifier () {
  rm "$keyname" "$hashfile"
  msg="Downloading signing key and verifying signing key" && print
  wget -O "$keyname" "$keyurl"
  if gpg --keyid-format long --with-fingerprint "$keyname" | grep -q "$fingerprint"; then
    msg="Good signing key importing signing key" && print
    gpg --import "$keyname"
    msg="Downloading then checking the hash file" && print
    wget -O "$hashfile" "$hashurl"
    if gpg --verify "$hashfile"; then
      checkversion
      hash0=$(sed -n "$line"p "$hashfile" | cut -f 1 -d ' ')
      msg="The text file hash is $hash0 downloading binary" && print
      rm "$a1"
      wget "$url"
      hash1=$(shasum -a 256 "$a1" | cut -f 1 -d ' ')
      msg="The binary hash is $hash1 checking match" && print
      if [ "$hash1" = "$hash0" ] ; then
        msg="Good match starting update" && print
        updater
      else
        msg="Failed match stopping updater" && print
      fi
    else
      msg="Failed to verify hashes stopping updater" && print
    fi
  else
    msg="Failed to verify signing key stopping updater" && print
  fi
}

#This is checks what version the verifier needs to download and  what line is needed in the hash file
checkversion () {
  line=0
  if [ "$version" = 'x86_64' ] || [ "$version" = '1' ]; then
    a1=linux64
    url="$url0"
    line=$(grep -n monero-linux-x64 "$hashfile" | cut -d : -f 1)
    msg="Monerod version set to $a1" && print
  fi
  if [ "$version" = 'armv7l' ] || [ "$version" = '2' ] ; then
    a1=linuxarm7
    url="$url1"
    line=$(grep -n monero-linux-armv7 "$hashfile" | cut -d : -f 1)
    msg="Monerod version set to $a1" && print
  fi
  if [ "$version" = 'armv8l' ] || [ "$version" = '3' ] ; then
    a1=linuxarm8
    url="$url2"
    line=$(grep -n monero-linux-armv8 "$hashfile" | cut -d : -f 1)
    msg="Monerod version set to $a1" && print
  fi
  if [ "$line" = '0' ] ; then
    msg="Failed to detect version stopping now" && print
    exit 1
  fi
}

#This will check for an update by looking at the github release page for the latest version
checkupdate () {
  current=$("$wd"/monerod --version | sed 's/.*v\(.*\)-.*/\1/')
  latest=$(curl https://github.com/monero-project/monero/releases/latest | sed 's/.*v\(.*\)">.*/\1/')
  if [ "$current" = "$latest" ] ; then
    msg="No update avalible latest version is $latest current version is $current" && print
    read -p 'Would you like to update anyways? [N/y]: ' output
    if [ "$output" = 'y' ] || [ "$output" = 'Y' ]; then
      msg="Starting updater" && print
      verifier
    else
      return 0
    fi
  else
    msg="Update avalible latest version is $latest current version is $current" && print
    read -p 'Would you like to update? [Y/n]: ' output
    if [ "$output" = 'n' ] || [ "$output" = 'N' ]; then
      return 0
    else
      msg="Starting updater" && print
      verifier
    fi
  fi
}

checkupdate
