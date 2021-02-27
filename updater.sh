#!/bin/bash

#Version 1.3.4
dirname="xmr" #Name of directory that contains monero software files (make it whatever you want)
version=$(uname -m) #version=1 for 64-bit, 2 for arm7 and 3 for arm8 or version=$(uname -m) for auto detect
directory=$(printf "%q\n" "$(pwd)" | sed 's/\/'$dirname'//g')
wd="$directory/$dirname" #To set manually use this example wd=/home/myUser/xmr
tmpdir="/tmp/xmr-75RvX3g3P" #This is where the hashes.txt, binary file and sigining key will be stored while the script is running.

checker0=1 #Change this number to 0 to avoid checking for a script update
checker1=1 #Change this number to 0 to avoid checking for a monero update (Just download and install)
backup=1 #Change this to 0 to not backup any files (If 0 script wont touch wallet files AT ALL)

#Match the fingerprint below with the one here
#https://web.getmonero.org/resources/user-guides/verification-allos-advanced.html#22-verify-signing-key
fingerprint="81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92"
keyurl=https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc #Keyfile download URL
keyname=binaryfate.asc #Key file name (Used to help the script locate the file)
hashurl=https://www.getmonero.org/downloads/hashes.txt #Hash file download URL
hashfile=hashes.txt #Hash file name (Used to help the script locate the file)

#x86_64 CLI URL
url0=https://downloads.getmonero.org/cli/linux64
#arm7 CLI URL
url1=https://downloads.getmonero.org/cli/linuxarm7
#arm8 CLI URL
url2=https://downloads.getmonero.org/cli/linuxarm8

#Used for printing text on the screen
print () {
  nc='\033[0m'
  if [ "$2" = "green" ]; then
    color='\033[1;32m'
  elif [ "$2" = "yellow" ]; then
    color='\033[1;33m'
  elif [ "$2" = "red" ]; then
    color='\033[1;31m'
  fi
  echo -e "${color}$1${nc}"
}

#This makes the backup and removes old files then extracts the verifed binary to the xmr directory
updater () {
  if pgrep monerod; then #Stops monerod to make sure it does not corrupt database when updating
    print "Stopping monerod to protect database during upgrade" yellow
    "$wd"/monerod exit
    sleep 3
  fi
  if [ "$backup" = "1" ]; then
    print "Moving current version to backup file" yellow
    rm -dr "$wd.bk"
    cp -r "$wd" "$wd.bk"
  fi
  print "Extracting binary to $wd" yellow
  mkdir "$wd"
  tar -xjvf "$tmpdir/$a1" -C "$wd" --strip-components=1
  print "Removing temp files (Binary/Hash file/Signing key)"
  rm "$tmpdir/$keyname" "$tmpdir/$hashfile" "$tmpdir/$a1"
}

#This verifies the binary, signing key and hash file
verifier () {
  mkdir "$tmpdir"
  rm "$tmpdir/$keyname" "$tmpdir/$hashfile"
  print "Downloading signing key and verifying signing key" yellow
  wget -O "$tmpdir/$keyname" "$keyurl"
  if gpg --keyid-format long --with-fingerprint "$tmpdir/$keyname" | grep -q "$fingerprint"; then
    print "Good signing key importing signing key" green
    gpg --import "$tmpdir/$keyname"
    print "Downloading then checking the hash file" yellow
    wget -O "$tmpdir/$hashfile" "$hashurl"
    if gpg --verify "$tmpdir/$hashfile"; then
      line=$(grep -n "$locate" "$tmpdir/$hashfile" | cut -d : -f 1)
      hash0=$(sed -n "$line"p "$tmpdir/$hashfile" | cut -f 1 -d ' ')
      print "The text file hash for $a1 is $hash0 downloading binary" yellow
      rm "$tmpdir/$a1"
      wget -P "$tmpdir" "$url"
      hash1=$(shasum -a 256 "$tmpdir/$a1" | cut -f 1 -d ' ')
      print "The binary hash for $a1 is $hash1 checking match" yellow
      if [ "$hash1" = "$hash0" ]; then
        print "Good match starting update" green
        updater
      else
        print "Bad match binary does not match hash file stopping updater" red
      fi
    else
      print "Failed to verify hash file stopping updater" red
    fi
  else
    print "Failed to verify signing key stopping updater" red
  fi
}

#This is checks what version the verifier needs to download and  what line is needed in the hash file
checkversion () {
  if [ "$version" = 'x86_64' ] || [ "$version" = '1' ]; then
    a1=linux64
    url="$url0"
    print "Monerod version set to $a1" green
    locate="monero-linux-x64"
  elif [ "$version" = 'armv7l' ] || [ "$version" = '2' ]; then
    a1=linuxarm7
    url="$url1"
    print "Monerod version set to $a1" green
    locate="monero-linux-armv7"
  elif [ "$version" = 'armv8l' ] || [ "$version" = '3' ]; then
    a1=linuxarm8
    url="$url2"
    print "Monerod version set to $a1" green
    locate="monero-linux-armv8"
  elif [ -z "$a1" ]; then
    print "Failed to detect version" red
    print "1 = x64, 2 = armv7, 3 = armv8, Enter nothing to exit" yellow
    read -r -p "Select a version [1/2/3]: " version
    if [ -z "$version" ]; then
      print "No version selected exiting" red
      rm "$tmpdir/$keyname" "$tmpdir/$hashfile"
      exit 1
    fi
    checkversion
  fi
}

#This will check for an update by looking at the github release page for the latest version
checkupdate () {
  if [ "$checker0" = "1" ]; then #Checks for updates to this script, this can be turned off above.
    cvrs=1.3.4
    lvrs=$(curl -s https://github.com/882wZS6Ps7/Monero-CLI-bash-updater/releases/latest | sed 's/.*v\(.*\)">.*/\1/')
    if [ "$lvrs" = "$cvrs" ]; then
      print "[Script] No update avalible latest: $lvrs Current: $cvrs" green
    else
      print "[Script] Update avalible latest: $lvrs Current: $cvrs" red
    fi
  fi
  if [ "$checker1" = "1" ]; then
    latest=$(curl -s https://github.com/monero-project/monero/releases/latest | sed 's/.*v\(.*\)">.*/\1/')
    if [ -f "$wd/monerod" ]; then
      current=$("$wd"/monerod --version | sed 's/.*v\(.*\)-.*/\1/')
    else
      current="Not installed"
    fi
    if [ "$current" = "$latest" ]; then
      print "[Monero] No update avalible latest: $latest Current: $current" green
      read -r -p "Would you like to install? [N/y]: " output
      if [ "$output" = 'y' ] || [ "$output" = 'Y' ]; then
        print "Starting updater" yellow
        verifier
      else
        exit 1
      fi
    else
      print "[Monero] Update avalible latest: $latest Current: $current" yellow
      read -r -p "Would you like to install? [Y/n]: " output
      if [ "$output" = 'n' ] || [ "$output" = 'N' ]; then
        exit 1
      else
        print "Starting updater" yellow
        verifier
      fi
    fi
  else
    verifier
  fi
}

checkversion
print "Current fingerprint: $fingerprint" yellow
print "Current install directory: $wd" yellow
print "Current temp directory: $tmpdir" yellow
if [ "$backup" = "1" ]; then
  print "Backup ON script will copy /$dirname/ files to $wd.bk" yellow
else
  print "Backup OFF script will not backup /$dirname/ files" yellow
fi
checkupdate
