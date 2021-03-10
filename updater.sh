#!/bin/bash

#Version 1.3.4
directory_name="xmr" #Name of directory that contains monero software files (make it whatever you want)
version=$(uname -m) #version=1 for 64-bit, 2 for arm7 and 3 for arm8 or version=$(uname -m) for auto detect
directory=$(printf "%q\n" "$(pwd)" | sed 's/\/'$directory_name'//g')
working_directory="$directory/$directory_name" #To set manually use this example working_directory=/home/myUser/xmr
temp_directory="/tmp/xmr-75RvX3g3P" #This is where the hashes.txt, binary file and sigining key will be stored while the script is running.

checker0=1 #Change this number to 0 to avoid checking for a script update
checker1=1 #Change this number to 0 to avoid checking for a monero update (Just download and install)
backup=1 #Change this to 0 to not backup any files (If 0 script wont touch wallet files AT ALL)

#Match the fingerprint below with the one here
#https://web.getmonero.org/resources/user-guides/verification-allos-advanced.html#22-verify-signing-key
fingerprint="81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92"
key_url=https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc #Keyfile download URL
key_name=binaryfate.asc #Key file name (Used to help the script locate the file)
hash_url=https://www.getmonero.org/downloads/hashes.txt #Hash file download URL
hash_file=hashes.txt #Hash file name (Used to help the script locate the file)

#x86_64 CLI URL
url_linux64=https://downloads.getmonero.org/cli/linux64
#arm7 CLI URL
url_linuxarm7=https://downloads.getmonero.org/cli/linuxarm7
#arm8 CLI URL
url_linuxarm8=https://downloads.getmonero.org/cli/linuxarm8

#Used for printing text on the screen
print () {
  no_color='\033[0m'
  if [ "$2" = "green" ]; then     #Print Green
    color='\033[1;32m'
  elif [ "$2" = "yellow" ]; then  #Print Yellow
    color='\033[1;33m'
  elif [ "$2" = "red" ]; then     #Print Red
    color='\033[1;31m'
  fi
  echo -e "${color}$1${no_color}" #Takes message and color and prints to screen
}

#Download and verifys the key we will use to verify the binary
get_key () {
  print "Downloading and verifying signing key" yellow
  rm -v "$temp_directory/$key_name"
  wget -O "$temp_directory/$key_name" "$key_url"
  if gpg --keyid-format long --with-fingerprint "$temp_directory/$key_name" | grep -q "$fingerprint"; then
    print "Good signing key importing signing key" green
    gpg --import "$temp_directory/$key_name"
  else
    print "Failed to verify signing key stopping script" red
    exit 1
  fi
}

#Downloads the hash file then verifies it with the key we downloaded
get_hash () {
  print "Downloading and verifying the hash file" yellow
  rm -v "$temp_directory/$hash_file"
  wget -O "$temp_directory/$hash_file" "$hash_url"
  if gpg --verify "$temp_directory/$hash_file"; then
    print "Good hash file" green
  else
    print "Failed to verify hash file stopping script" red
    exit 1
  fi
}

#Downloads the binary then shasums it and matches the hash with the hash file
get_binary () {
  print "Downloading and verifying the binary version: $locate" yellow
  rm -v "$temp_directory/$binary_name"
  wget -P "$temp_directory" "$url" #Downloads the binary

  print "Checking the sum from the hash file and the binary" yellow
  line=$(grep -n "$locate" "$temp_directory/$hash_file" | cut -d : -f 1) #Gets the version line(hash) from hash file
  file_hash=$(sed -n "$line"p "$temp_directory/$hash_file" | cut -f 1 -d ' ')
  binary_hash=$(shasum -a 256 "$temp_directory/$binary_name" | cut -f 1 -d ' ')

  print "File hash:     $file_hash" yellow
  print "Binary hash:   $binary_hash" yellow
  if [ "$file_hash" = "$binary_hash" ]; then #Match the hashfile and binary
    print "Good match" green
  else
    print "Bad match binary does not match hash file stopping updater" red
    exit 1
  fi
}

#This makes the backup and removes old files then extracts the verifed binary to the xmr directory
updater () {
  if pgrep monerod; then #Stops monerod to make sure it does not corrupt database when updating
    print "Stopping monerod to protect database during upgrade" yellow
    "$working_directory"/monerod exit
    sleep 3
  fi
  if [ "$backup" = "1" ]; then #Removes old backup copies currect directory to directory.bk
    print "Moving current version to backup file" yellow
    rm -vdr "$working_directory.bk"
    cp -r "$working_directory" "$working_directory.bk"
  fi
  print "Extracting binary to $working_directory" yellow
  mkdir "$working_directory"
  tar -xjvf "$temp_directory/$binary_name" -C "$working_directory" --strip-components=1
  print "Removing temp files (Binary/Hash file/Signing key)"
  rm -v "$temp_directory/$key_name" "$temp_directory/$hash_file" "$temp_directory/$binary_name" #Clean up install files
}

#This verifies the binary, signing key and hash file
verifier () {
  mkdir "$temp_directory"
  get_key
  get_hash
  get_binary
  updater
}

#This is checks what version the verifier needs to download and  what line is needed in the hash file
checkversion () {
  if [ "$version" = 'x86_64' ] || [ "$version" = '1' ]; then
    binary_name=linux64
    url="$url_linux64"
    print "Monerod version set to $binary_name" green
    locate="monero-linux-x64"
  elif [ "$version" = 'armv7l' ] || [ "$version" = '2' ]; then
    binary_name=linuxarm7
    url="$url_linuxarm7"
    print "Monerod version set to $binary_name" green
    locate="monero-linux-armv7"
  elif [ "$version" = 'armv8l' ] || [ "$version" = '3' ]; then
    binary_name=linuxarm8
    url="$url_linuxarm8"
    print "Monerod version set to $binary_name" green
    locate="monero-linux-armv8"
  elif [ -z "$binary_name" ]; then
    print "Failed to detect version" red
    print "1 = x64, 2 = armv7, 3 = armv8, Enter nothing to exit" yellow
    read -r -p "Select a version [1/2/3]: " version
    if [ -z "$version" ]; then
      print "No version selected exiting" red
      rm "$temp_directory/$key_name" "$temp_directory/$hash_file"
      exit 1
    fi
    checkversion
  fi
}

#This will check for an update by looking at the github release page for the latest version
checkupdate () {
  if [ "$checker0" = "1" ]; then #Checks for updates to this script, this can be turned off above.
    current_version=1.3.4
    latest_version=$(curl -s https://github.com/882wZS6Ps7/Monero-CLI-bash-updater/releases/latest | sed 's/.*v\(.*\)">.*/\1/')
    if [ "$latest_version" = "$current_version" ]; then
      print "[Script] No update avalible latest: $latest_version Current: $current_version" green
    else
      print "[Script] Update avalible latest: $latest_version Current: $current_version" red
    fi
  fi
  if [ "$checker1" = "1" ]; then
    latest=$(curl -s https://github.com/monero-project/monero/releases/latest | sed 's/.*v\(.*\)">.*/\1/')
    if [ -f "$working_directory/monerod" ]; then
      current=$("$working_directory"/monerod --version | sed 's/.*v\(.*\)-.*/\1/')
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
print "Current install directory: $working_directory" yellow
print "Current temp directory: $temp_directory" yellow
if [ "$backup" = "1" ]; then
  print "Backup ON script will copy /$directory_name/ files to $working_directory.bk" yellow
else
  print "Backup OFF script will not backup /$directory_name/ files" yellow
fi
checkupdate
