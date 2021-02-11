# Monero CLI updater
Monero CLI updater for linux. Auto detects version and keeps wallet files after making a backup of the previous version with wallet files.
This script will make a new directory next to the xmr directory called xmr.bk this one is the backup of the entire xmr directory including the wallet files, other then that this script won't touch the wallet files. The script just makes a copy to the xmr.bk dirctory when the updater is ran and then removes the monero software inside the xmr directory then extracts the verified software to that directory. I have tried to keep it simple and easy to read so you can verify the script does as said. This script was wrote in shell so it can be easily read and updated if needed.

# Install
Just put the updater.sh script where you want the xmr directory that contains the monero wallet software and the wallet files.
When first downloading this script it is recommended you verify the variables haven't been modified match the urls and fingerprint with the urls on the official Monero website https://web.getmonero.org/resources/user-guides/verification-allos-advanced.html
