\# Pi-hole Automated Backup Solution
Automate your Pi-hole backups with this workflow. The script uses the command-line version of Pi-hole's built-in 'Teleporter' to create a configuration backup, which is then transferred to your chosen destination (e.g., a NAS) via rsync. A log of the transfer is also saved to the destination directory. To conserve space, only the four most recent Teleporter backups are kept and synced, ensuring efficient use of storage.

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

---
<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#release-history">Release History</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contact-and-info">Contact and Info</a></li>
    <li><a href="#acknowledgments">Acknowledgements</a></li>
    <li><a href="#contributing">Contributing</a></li>
  </ol>
</details>

---

<!-- ABOUT THE PROJECT -->
## About The Project

<img src="https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/blob/main/README-files/Pi-Hole_Header_Image.png?raw=true">


After finally setting up a Pi-hole instance in my Home Lab to see what all the fuss what about I was thoroughly impressed. But, as with many things Home Lab, one project quickly begets another: now I had to setup some sort of reliable backup solution.  
  
At first I began looking for a good solution to backup my entire Raspberry Pi. The thought process was "if my SD card on the Pi, or the Pi itself dies, I'll be able to quickly swap out the broken hardware and restore the entire system to it's previous state."  
  
Since I use Active Backup for Business on my Synology NAS this was the first thing I tried. Unfortunately, Synology has not ported Active Backup for Business for ARM processors so this is a no-go solution for a Raspberry Pi.

In the end I opted to use "Teleporter" -- the built-in configuration backup solution for Pi-hole.

The next problem was "how do I automate this?". Teleporter works fine, but the joys of a successful Home Lab architecture is not having a ton of things that require manual handling. Hence, this project was born!

**NOTE:**  
In addition to the automated Teleporter backups provided by this solution, I setup a secondary Pi-hole DNS server and synced it with my primary Pi-hole instance using ~~Orbital Sync~~ [Nebula-Sync](https://github.com/lovelaze/nebula-sync). Therefore, for my setup to fail my Primary Pi-hole instance on my Raspberry Pi plus my backups of that instance on my NAS plus my secondary Pi-hole instance running in Docker would both have to fail.  


### Built With

Below are all the parts, tools, libraries, frameworks, etc. applicable to and used in this project. Additional details can be found in the acknowledgements section.

* [Pi-hole](https://https://pi-hole.net/)
* [Bash Script](https://www.freecodecamp.org/news/shell-scripting-crash-course-how-to-write-bash-scripts-in-linux/)
* [Rsync](https://linuxize.com/post/how-to-use-rsync-for-local-and-remote-data-transfer-and-synchronization/)
* [Cron](https://crontab.guru/)
* [fstab](https://linuxconfig.org/how-fstab-works-introduction-to-the-etc-fstab-file-on-linux)
* [Raspberry Pi OS](https://www.raspberrypi.com/software/)



<p align="right">(<a href="#top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

This repo assumes that you have a Pi-hole instance setup on a physical Raspberry Pi with Raspbian / Raspberry Pi OS. This is my particular setup, but could easily be used if your Pi-hole is running on a virtualized instance via Proxmox, Hyper-V, etc. or a containerized instance via Docker.   
  
The other assumptions made here are that you will be able to follow the logic of the installation to suit your specific conditions in regards to your destination device. In my case I am using a Synology NAS. For this gear the configuration of shares (e.g. CIFS, NFS, etc.) are quite specific. Instead of giving all the details regarding that I leave it up to the reader / implementer to understand how to do this on their own hardware.

### Installation

1. **Put the script on your Pi-hole:** <br>
Make a directory for the [backup_pihole.sh script](https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/blob/main/backup_pihole.sh) to live (e.g. `mkdir pihole_backups`), then place it there.


2. **Make sure the Script is executable:** <br>
`sudo chmod -x backup_pihole.sh`

3. **Make sure Rsync is installed on your system running Pi-hole (install if it isn't):** <br>
`rsync --version`

4. **Mount your destination directory onto your Pi-hole:** <br>
`sudo mkdir -p /mnt/backup_destination`

5. **Setup the mount so it persists on the Pi-hole after a reboot:** <br>
Edit `/etc/fstab` with your preferred editor:<br>
`sudo nano /etc/fstab` <br><br>
Add the command to enable the mount:<br>
`//192.168.1.100/Backups/Pi-hole /mnt/backup_destination cifs vers=1.0,user=your-admin-username,password=your-admin-password,x-systemd.automount 0 0`

6. **Verify that the Mount persists on Pi-hole reboot:** <br>
`sudo reboot now` <br>
Then, check if mountpoint is still available at `ls /mnt/`
7. **Setup Password-less SSH connection via SSH Keys**
This is done so the script can run without prompting for any passwords. <br>
`ssh-keygen -t rsa -b 4096` <br>
Then copy the SSH Public Key to the destination device. Note that after being generated the SSH Key files will be placed in the `.ssh` directory under your home directory (e.g. `~/.ssh`). <br><br>
You can do this by SCP'ing into your Pi and copying the SSH Public Key (`id_rsa.pub`) to the appropriate location on your backup device as the appropriate user. For me, this was something like:<br>
`ssh-copy-id -p 22 your-admin-username@192.168.1.100`<br><br>
Note that to complete the process you will need to enter the password for the specified user once.

8. **Test if Password-less SSH to your destination device is working:** <br>
`ssh -p 22 your-admin-username@192.168.1.100`

9. **Test the Rsync Command Manually to make sure everything is functioning as expected:**<br>
`sudo rsync -avvv -e 'ssh -p 22' /home/pi/Pihole_Backups/ your-admin-username@192.168.1.100:/volume1/Backups/Pi-hole/`

10. **Check the Log Files on your destination directory:**<br>
Open `logfile.log` in your destination directory and inspect the entries to make sure all operations executed as expected.
11. **Setup the script to run automatically (with Cron):**  
`crontab -e`<br><br>
For me, I set it to run on the first of every month by adding the following line to my crontab file:<br> 
`0 0 1 * * /path/to/the_script/name_of_script.sh`
12. **Verify that the Cron Job was added correctly:**<br>
`crontab -l`


## Release History

* 0.6.3
    * Update teleporter command in script to work with Pi-hole v6.x
* 0.6.2
    * Set rsync to keep number of backups the same on both source and destination.
* 0.6.0
    * Tested and finalized.
* 0.5.0
    * The first proper release.
* 0.4.0
    * Testing and tweaks.
* 0.3.0
    * Testing and bugfixes.
* 0.2.0
    * Added Logs.
* 0.1.0
    * Work in progress.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [x] Add Logs
- [ ] Add dialog system for moderate level of automation on setup

See the [open issues](https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#top">back to top</a>)</p>

## Contact and Info

Jacques Laroche – Twitter [@jlar0che](https://twitter.com/jlar0che)

Project Link: [https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution](https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution)

Distributed under the GPLV3 license. See [GPLV3 LICENSE DETAILS](https://choosealicense.com/licenses/gpl-3.0/) for more information.


<p align="right">(<a href="#top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

Big thanks to the following makers, resources and tools. 

* [The Engineer's Workshop](https://engineerworkshop.com/blog/avoid-disaster-how-to-securely-backup-your-pihole-configuration-and-keep-your-network-running-smoothly/)


<p align="right">(<a href="#top">back to top</a>)</p>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork it (<https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution>)
2. Create your feature branch (`git checkout -b feature/Branchname`)
3. Commit your changes (`git commit -am 'Add a message'`)
4. Push to the branch (`git push origin feature/Branchname`)
5. Create a new Pull Request

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
<!-- ----------------------------------------------------------------- -->

<!-- BADGES SECTION -->
[contributors-shield]: https://img.shields.io/github/contributors/jlar0che/Pi-hole-Automated-Backup-Solution?style=for-the-badge
[contributors-url]: https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/contributors

[forks-shield]: https://img.shields.io/github/forks/jlar0che/Pi-hole-Automated-Backup-Solution?style=for-the-badge
[forks-url]: https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/network/members

[stars-shield]: https://img.shields.io/github/stars/jlar0che/Pi-hole-Automated-Backup-Solution?style=for-the-badge
[stars-url]: https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/stargazers

[issues-shield]: https://img.shields.io/github/issues/jlar0che/Pi-hole-Automated-Backup-Solution?style=for-the-badge
[issues-url]: https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/issues

[license-shield]: https://img.shields.io/github/license/jlar0che/Pi-hole-Automated-Backup-Solution?style=for-the-badge
[license-url]: https://github.com/jlar0che/Pi-hole-Automated-Backup-Solution/blob/main/LICENSE

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/jacques-laroche-07032b174/

<!-- SCREENSHOT below "About The Project" -->
[product-screenshot]: https://i.ibb.co/cLWVJ4Q/NodeMCU.jpg

<!-- WIKI LINK in "Usage Example" -->
[wiki]: https://github.com/yourname/yourproject/wiki
