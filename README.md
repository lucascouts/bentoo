# Bentoo 'Gentoo GO'

Bentōō is an initiative to distribute an user-friendly version of Gentoo and Funtoo linux Stage4/5 to new users, with more updated packages, focusing on agility, security, privacy and games.

## with local overlays

[Local overlays](https://wiki.gentoo.org/wiki/Creating_an_ebuild_repository) should be managed via `/etc/portage/repos.conf/`.
create a `/etc/portage/repos.conf/bentoo.conf` file containing precisely:

```
[bentoo]
location = /var/db/repos/bentoo
sync-type = git
sync-uri = https://github.com/lucascouts/bentoo.git
priority= 99
```
#### then change to new branch.
```
cd /var/db/repos && git clone https://github.com/lucascouts/bentoo.git && cd bentoo && git checkout GG
```

Afterwards, simply run `emaint sync -r bentoo`, and Portage should seamlessly make all our ebuilds available.

### Bentoo Portage config

Here you can see the portage files configurations : https://github.com/lucascouts/bentoo-cfg
