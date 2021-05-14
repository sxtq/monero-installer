#!/bin/bash

#Version 1.3.8
directory_name="xmr" #Name of directory that contains monero software files (make it whatever you want)
version=$(uname -m) #version=1 for 64-bit, 2 for arm7, 3 for arm8 and 4, for android arm8, 5 for linux32 or version=$(uname -m) for auto detect
directory=$(printf "%q\n" "$(pwd)" | sed 's/\/'$directory_name'//g')
working_directory="$directory/$directory_name" #To set manually use this example working_directory=/home/myUser/xmr
temp_directory="$directory/tmp-xmr-483" #This is where the hashes.txt, binary file and sigining key will be stored while the script is running.
offline=0 #Change this to 1 to run in offline mode
backup=1 #Change this to 0 to not backup any files (If 0 script wont touch wallet files AT ALL)
type=1 #1 for CLI 2 for GUI

#Match the fingerprint below with the one here
#https://web.getmonero.org/resources/user-guides/verification-allos-advanced.html#22-verify-signing-key
output_fingerprint="81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92"
key_url=https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc #Keyfile download URL
key_name=binaryfate.asc #Key file name (Used to help the script locate the file)
hash_url=https://www.getmonero.org/downloads/hashes.txt #Hash file download URL
hash_file=hashes.txt #Hash file name (Used to help the script locate the file)

#Download server URL
url=https://downloads.getmonero.org

while test "$#" -gt 0; do
  case "$1" in
    -h|--help)
      echo "  -h,  --help                          show list of startup flags"
      echo "  -d,  --directory /path/to/dir        manually set directory path (This will add /$directory_name to the end)"
      echo "  -f,  --fingerprint fingerprint       manually set fingerprint use quotes around fingerprint if the fingerprint has spaces"
      echo "  -n,  --name dirName                  manually set the name for the directory used to store the monero files"
      echo "  -v,  --version number                manually set the version 1 for 64-bit, 2 for arm7, 3 for arm8, 4 for android arm8, 5 for linux32"
      echo "  -o,  --offline                       run in offline mode, this requires the files to be next to this script"
      echo "  -t,  --type number                   1 for CLI 2 for GUI"
      echo "  -s,  --skip                          run with no input needed useful for auto updaters in scripts"
      exit 0
      ;;
    -f|--fingerprint)
      shift
      if test "$#" -gt 0; then
        export output_fingerprint="$1"
      else
        echo "No fingerprint specified"
        exit 1
      fi
      shift
      ;;
    -n|--name)
      shift
      if test "$#" -gt 0; then
        export directory_name="$1"
      else
        echo "No name specified"
        exit 1
      fi
      shift
      ;;
    -d|--directory)
      shift
      if [ -d "$1" ]; then
        if test "$#" -gt 0; then
          directory="${1%/}"
        else
          echo "No directory specified"
          exit 1
        fi
      else
        echo "$1 does not exist"
        exit 1
      fi
      shift
      ;;
    -v|--version)
      shift
      if test "$#" -gt 0; then
        export version="$1"
      else
        echo "No version specified"
        echo "1 for 64-bit, 2 for arm7, 3 for arm8, 4 for android arm8, 5 for linux32"
        exit 1
      fi
      shift
      ;;
    -t|--type)
      shift
      if test "$#" -gt 0; then
        export type="$1"
      else
        echo "No type specified"
        exit 1
      fi
      shift
      ;;
    -s|--skip)
      shift
      export no_input=1
      shift
      ;;
    -o|--offline)
      shift
      export offline=1
      shift
      ;;
    *)
      echo "Unrecognized flag \"$1\""
      exit 1
      ;;
  esac
done

#Checks if wget is installed
if ! command -v wget &> /dev/null; then
  echo "wget not installed"
  exit
fi

#Checks if gnupg is installed
if ! command -v gpg &> /dev/null; then
  echo "gnupg not installed"
  exit
fi

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
  gpg -k
  print "Downloading and verifying signing key" yellow
  if [ "$net" = "1" ]; then
    rm -v "$temp_directory/$key_name"
    wget -O "$temp_directory/$key_name" "$key_url"
  fi
  if gpg --with-colons --import-options import-show --dry-run --import < "$temp_directory/$key_name" | grep -q "$fingerprint"; then
    print "Good signing key importing key $temp_directory/$key_name" green
    gpg -v --import "$temp_directory/$key_name"
    check_0=1
  else
    print "Failed to verify signing key" red
    fail
  fi
}

#Downloads the hash file then verifies it with the key we downloaded
get_hash () {
  print "Downloading and verifying the hash file" yellow
  if [ "$net" = "1" ]; then
    rm -v "$temp_directory/$hash_file"
    wget -O "$temp_directory/$hash_file" "$hash_url"
  fi
  if gpg -v --verify "$temp_directory/$hash_file"; then
    print "Good hash file $temp_directory/$hash_file" green
    check_1=1
  else
    print "Failed to verify hash file $temp_directory/$hash_file" red
    fail
  fi
}

#Downloads the binary then shasums it and matches the hash with the hash file
get_binary () {
  print "Downloading and verifying the binary version: $version_name" yellow
  if [ "$net" = "1" ]; then
    rm -v "$temp_directory/$binary_name"
    wget -P "$temp_directory" "$url" #Downloads the binary
  fi
  print "Checking the sum from the hash file and the binary" yellow
  line=$(grep -n "$version_name" "$temp_directory/$hash_file" | cut -d : -f 1) #Gets the version line(hash) from hash file
  file_hash=$(sed -n "$line"p "$temp_directory/$hash_file" | cut -f 1 -d ' ')
  pre_binary_hash=$(shasum -a 256 "$temp_directory/$binary_name" || sha256sum "$temp_directory/$binary_name" | cut -f 1 -d ' ')
  binary_hash=$(echo "$pre_binary_hash" | cut -f 1 -d ' ')

  print "File hash:     $file_hash" yellow
  print "Binary hash:   $binary_hash" yellow
  if [ "$file_hash" = "$binary_hash" ]; then #Match the hashfile and binary
    print "Binary hash matches hash file" green
    check_2=1
  else
    print "Bad match binary does not match hash file" red
    fail
  fi
}

#This makes the backup and removes old files then extracts the verifed binary to the xmr directory
updater () {
  if pgrep monerod; then #Stops monerod to make sure it does not corrupt database when updating
    print "Stopping monerod to protect database during upgrade" yellow
    "$working_directory"/monerod exit
    sleep 8
  fi
  if [ "$backup" = "1" ]; then #Removes old backup then copies currect directory to directory.bk
    print "Moving current version to backup file" yellow
    rm -vdr "$working_directory.bk"
    cp -r "$working_directory" "$working_directory.bk"
  fi
  print "Extracting binary to $working_directory" yellow
  mkdir -v "$working_directory"
  tar -xjvf "$temp_directory/$binary_name" -C "$working_directory" --strip-components=1
  if [ "$net" = "1" ]; then
    print "Removing temp files (Binary/Hash file/Signing key)"
    rm -v "$temp_directory/$key_name" "$temp_directory/$hash_file" "$temp_directory/$binary_name" #Clean up install files
  fi
}

#This is what checks what version the verifier needs to download and what line is needed in the hash file
checkversion () {
  if [ "$version" = 'x86_64' ] || [ "$version" = '1' ]; then
    binary_name=linux64
    if [ "$type" = "1" ]; then
      type_set="CLI"
      url="$url/cli/linux64"
      version_name="monero-linux-x64"
    else
      type_set="GUI"
      url="$url/gui/linux64"
      version_name="monero-gui-linux-x64"
    fi
  elif [ "$version" = 'armv7l' ] || [ "$version" = '2' ]; then
    type_set="CLI"
    binary_name=linuxarm7
    url="$url/cli/linuxarm7"
    version_name="monero-linux-armv7"
    if [ "$type" = "2" ]; then
      print "GUI Version is not supported on $binary_name" red
      exit 1
    fi
  elif [ "$version" = 'armv8l' ] || [ "$version" = '3' ]; then
    type_set="CLI"
    binary_name=linuxarm8
    url="$url/cli/linuxarm8"
    version_name="monero-linux-armv8"
    if [ "$type" = "2" ]; then
      print "GUI Version is not supported on $binary_name" red
      exit 1
    fi
  elif [ "$version" = 'aarch64' ] || [ "$version" = '4' ]; then
    type_set="CLI"
    binary_name=androidarm8
    url="$url/cli/androidarm8"
    version_name="monero-android-armv8"
    if [ "$type" = "2" ]; then
      print "GUI Version is not supported on $binary_name" red
      exit 1
    fi
  elif [ "$version" = 'i686' ] || [ "$version" = '5' ]; then
    type_set="CLI"
    binary_name=linux32
    url="$url/cli/linux32"
    version_name="monero-linux-x86"
    if [ "$type" = "2" ]; then
      print "GUI Version is not supported on $binary_name" red
      exit 1
    fi
  elif [ -z "$binary_name" ]; then
    print "Failed to detect version manual selection required" red
    if [ "$no_input" = "1" ]; then
      print "Script ran in no input mode nothing can be done exiting" red
      exit 1
    else
      print "1 = linux64, 2 = armv7, 3 = armv8, 4 = android-arm8, 5 = linux32" yellow
      print "Enter nothing to exit" yellow
      read -r -p "Select a version [1/2/3/4/5]: " version
    fi
    if [ -z "$version" ]; then
      print "No version selected exiting" red
      rm -v "$temp_directory/$key_name" "$temp_directory/$hash_file"
      exit 1
    fi
    checkversion
  fi
}

#This will run if the script failes to verify any parts of the install, just prints info and ask if you want to remove files
fail () {
  print "Failed to meet all requiremnts the script wont update" red
  if [ "$no_input" = "1" ]; then
    print "Script ran in no input mode removing files by default" red
    output=Y
  else
    print "Path to files : $temp_directory" yellow
    print "Signing key verifcation : $check_0" yellow
    print "   Hashfile verifcation : $check_1" yellow
    print "     Binary verifcation : $check_2" yellow
    read -r -p "Would you like to remove the files? [N/y]: " output
  fi
  if [ "$output" = 'Y' ] || [ "$output" = 'y' ]; then
    rm -drv "$temp_directory"
  fi
  exit 1
}

main () {
  check_0=0
  check_1=0
  check_2=0
  working_directory="$directory/$directory_name"

  if [ -z "$output_fingerprint" ]; then
    print "No hardcoded fingerprint inside the script" red
    read -r -p "Input fingerprint: " output_fingerprint
  fi
  fingerprint=$(echo "$output_fingerprint" | tr -d " \t\n\r")

  checkversion
  if wget -q --spider http://github.com && [ "$offline" = "0" ]; then
    network_stat="Online install"
    net=1
  else
    temp_directory=$(pwd)
    network_stat="Offline install"
    if [ -f "$temp_directory/$key_name" ] && [ -f "$temp_directory/$hash_file" ] && [ -f "$temp_directory/$binary_name" ]; then
      print "All install files found in: $temp_directory/" green
    else
      print "Offline install" red
      print "Failed to find install files" red
      print "$temp_directory/$key_name" red
      print "$temp_directory/$hash_file" red
      print "$temp_directory/$binary_name" red
      exit 1
    fi
  fi
  print "Verify everything is correct before installing" green
  print "Manually checking the script is required to verify nothing was modified" red
  print "      Fingerprint : $output_fingerprint" yellow
  print "   Network status : $network_stat" yellow
  print "   Monero version : $binary_name / $type_set" yellow
  print "Install directory : $working_directory" yellow
  print "   Temp directory : $temp_directory" yellow
  if [ "$backup" = "1" ]; then
    print " Backup directory : ON $working_directory.bk" yellow
  else
    print " Backup directory : OFF script wont touch wallet files" yellow
  fi

  if [ "$no_input" = "1" ]; then
    print "Script ran in no input mode starting updater" red
    output=Y
  else
    read -r -p "Would you like to install? [Y/n]: " output
  fi
  if [ "$output" = 'N' ] || [ "$output" = 'n' ]; then
    exit 1
  else
    mkdir -v "$temp_directory"
    get_key
    get_hash
    get_binary
    if [ "$check_0" = "1" ] && [ "$check_1" = "1" ] && [ "$check_2" = "1" ]; then
      print "All requiremnts met starting updater function" green
      updater
      print "Done, make sure you DONT use the .bk directory as thats the backup and will be replaced every new install" yellow
    else
      fail
    fi
    rm -drv "$temp_directory"
  fi
}

main
