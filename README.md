# Monero CLI updater and installer
Monero CLI updater and installer for linux. Auto detects version and keeps wallet files after making a backup of the previous version with the wallet files.
This script will make a new directory next to the xmr directory called xmr.bk this one is the backup of the entire xmr directory before the update including the wallet files, other then that this script won't touch the wallet files. The script just makes a copy to the xmr.bk dirctory when the updater is ran and then removes the monero software inside the xmr directory then extracts the verified software to that directory. I have tried to keep it simple and easy to read so you can verify the script does as said. This script was wrote in shell so it can be easily read and updated if needed.

## Install
Just put the updater.sh script where you want the xmr directory that contains the monero wallet software and the wallet files then type.

First Download the updater with this command (This requires you have git installed for this command)
```
$ git clone https://github.com/sxtq/Monero-CLI-bash-updater.git
```
Now move the updater.sh script to the where you want the xmr directory
```
$ mv Monero-CLI-bash-updater/updater.sh updater.sh
```
Now make the updater.sh script exicutable
```
$ chmod +x updater.sh
```
Now you can run the script
```
$ ./updater.sh
```
This script can also be placed inside the xmr directory with the wallet files and monero software files. This way you can have all of the monero files in one directory, it works both ways so its up to you if you want it inside or outside the xmr directory.

When first downloading this script it is recommended you verify the variables haven't been modified match the urls and fingerprint with the urls on the official Monero website https://web.getmonero.org/resources/user-guides/verification-allos-advanced.html
```
 -h,  --help                              show list of startup flags
 -d,  --directory /path/to/dir            manually set directory path (This will add /xmr to the end)
 -f,  --fingerprint fingerprint           manually set fingerprint use quotes around fingerprint if the fingerprint has spaces
 -n,  --name dirName                      manually set the name for the directory used to store the monero files
 -v,  --version number                    manually set the version 1 for 64-bit, 2 for arm7 and 3 for arm8
 -o,  --offline                           run in offline mode, this requires the files to be next to this script
 -t,  --type number                       1 for CLI 2 for GUI
 -t,  --type number                       1 for CLI 2 for GUI
 -s,  --skip                              run with no input needed useful for auto updaters in scripts
```
## Examples
```
$ ./updater.sh -f "81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92" -d /home/user1/Documents -n Monero-Wallet
```
This will put the Monero-Wallet directory with the extacted files and wallet files inside /home/user1/Documents/ so /home/user1/Documents/Monero-Wallet
```
$ ./updater.sh -d /home/user1/
```
This will put the default directory name "xmr" in the /home/user1/ directory so /home/user1/xmr/ Inside the xmr dir is the wallet and software files
