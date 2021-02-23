#!/bin/bash

dirname="xmr" #Name of directory that contains monero software files (make it whatever you want)
version=$(uname -m) #version=1 for 64-bit, 2 for arm7 and 3 for arm8 or version=$(uname -m) for auto detect
directory=$(printf "%q\n" "$(pwd)" | sed 's/\/'$dirname'//g')
wd="$directory"/"$dirname" #To set manually use this example wd=/home/myUser/xmr
tmpdir=/tmp/xmr-75RvX3g3P #This is where the hashes.txt, binary file and sigining key will be stored while the script is running.

checker0=1 #Change this number to 0 to avoid checking for a script update
checker1=1 #Change this number to 0 to avoid checking for a monero update (Just download and install)
backup=1 #Change this to 0 to not backup any files (If 0 script wont touch wallet files AT ALL)

#Match the fingerprint below with the one here https://web.getmonero.org/resources/user-guides/verification-allos-advanced.html#22-verify-signing-key
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
  echo -e "\033[1;33m$1\033[0m"
}

#This makes the backup and removes old files then extracts the verifed binary to the xmr directory
updater () {
  if [ "$backup" = "1" ]; then
    print "Moving current version to backup file"
    rm -dr "$wd.bk"
    cp -r "$wd" "$wd.bk"
  fi
  print "Extracting binary to $wd"
  mkdir "$wd"
  tar -xjvf "$tmpdir/$a1" -C "$wd" --strip-components=1
  rm "$tmpdir/$keyname" "$tmpdir/$hashfile" "$tmpdir/$a1"
}

#This verifies the binary, signing key and hash file
verifier () {
  rm "$tmpdir/$keyname" "$tmpdir/$hashfile"
  print "Downloading signing key and verifying signing key"
  wget -O "$tmpdir/$keyname" "$keyurl"
  if gpg --keyid-format long --with-fingerprint "$tmpdir/$keyname" | grep -q "$fingerprint"; then
    print "Good signing key importing signing key"
    gpg --import "$tmpdir/$keyname"
    print "Downloading then checking the hash file"
    wget -O "$tmpdir/$hashfile" "$hashurl"
    if gpg --verify "$tmpdir/$hashfile"; then
      checkversion
      hash0=$(sed -n "$line"p "$tmpdir/$hashfile" | cut -f 1 -d ' ')
      print "The text file hash for $a1 is $hash0 downloading binary"
      rm "$tmpdir/$a1"
      wget -P "$tmpdir" "$url"
      hash1=$(shasum -a 256 "$tmpdir/$a1" | cut -f 1 -d ' ')
      print "The binary hash for $a1 is $hash1 checking match"
      if [ "$hash1" = "$hash0" ]; then
        print "Good match starting update"
        updater
      else
        print "Failed match stopping updater"
      fi
    else
      print "Failed to verify hashes stopping updater"
    fi
  else
    print "Failed to verify signing key stopping updater"
  fi
}

#This is checks what version the verifier needs to download and  what line is needed in the hash file
checkversion () {
  line=0
  if [ "$version" = 'x86_64' ] || [ "$version" = '1' ]; then
    a1=linux64
    url="$url0"
    line=$(grep -n monero-linux-x64 "$tmpdir/$hashfile" | cut -d : -f 1)
    print "Monerod version set to $a1"
  fi
  if [ "$version" = 'armv7l' ] || [ "$version" = '2' ]; then
    a1=linuxarm7
    url="$url1"
    line=$(grep -n monero-linux-armv7 "$tmpdir/$hashfile" | cut -d : -f 1)
    print "Monerod version set to $a1"
  fi
  if [ "$version" = 'armv8l' ] || [ "$version" = '3' ]; then
    a1=linuxarm8
    url="$url2"
    line=$(grep -n monero-linux-armv8 "$tmpdir/$hashfile" | cut -d : -f 1)
    print "Monerod version set to $a1"
  fi
  if [ "$line" = '0' ]; then
    print "Failed to detect version"
    print "1 = x64, 2 = armv7, 3 = armv8, Enter nothing to exit"
    read -r -p "Select a version [1/2/3]: " version
    if [ "$version" = '' ]; then
      print "No version selected exiting"
      rm "$tmpdir/$keyname" "$tmpdir/$hashfile"
      exit 1
    fi
    checkversion
  fi
}

#This will check for an update by looking at the github release page for the latest version
checkupdate () {
  #Checks for updates to this script, this can be turned off above.
  if [ "$checker0" = "1" ]; then
    cvrs=1.3.3
    lvrs=$(curl -s https://github.com/882wZS6Ps7/Monero-CLI-bash-updater/releases/latest | sed 's/.*v\(.*\)">.*/\1/')
    if [ "$lvrs" = "$cvrs" ]; then
      print "This script is up to date current version is: $cvrs"
    else
      print "This script is outdated latest version: $lvrs Current version: $cvrs"
    fi
  fi
  if [ "$checker1" = "0" ]; then
    verifier
    exit
  fi
  current=$("$wd"/monerod --version | sed 's/.*v\(.*\)-.*/\1/')
  latest=$(curl -s https://github.com/monero-project/monero/releases/latest | sed 's/.*v\(.*\)">.*/\1/')
  if [ -f "$wd/monerod" ]; then
    w="update"
  else
    current="Not installed"
    w="install"
  fi
  if [ "$current" = "$latest" ]; then
    print "No update avalible latest version: $latest Current version: $current"
    read -r -p "Would you like to update anyways? [N/y]: " output
    if [ "$output" = 'y' ] || [ "$output" = 'Y' ]; then
      print "Starting updater"
      verifier
    else
      return 0
    fi
  else
    print "Update avalible latest version: $latest Current version: $current"
    read -r -p "Would you like to $w? [Y/n]: " output
    if [ "$output" = 'n' ] || [ "$output" = 'N' ]; then
      return 0
    else
      print "Starting updater"
      verifier
    fi
  fi
}

print "Current fingerprint: $fingerprint"
print "Current Directory: $wd"
checkupdate
