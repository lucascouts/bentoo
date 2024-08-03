# Bentoo

Bentōō is an initiative to distribute an user-friendly version of Gentoo linux Stage[5] to new users, with more updated packages, focusing on agility, security, privacy and games.

## Overlays

### local Overlay

[Local overlays](https://wiki.gentoo.org/wiki/Creating_an_ebuild_repository) should be managed via `/etc/portage/repos.conf/`.
create a `/etc/portage/repos.conf/bentoo.conf` file containing precisely:

```
[bentoo]
location = /var/db/repos/bentoo
sync-type = git
sync-uri = https://github.com/lucascouts/bentoo.git
priority= 99
```
### eselect repository
```
eselect repository add bentoo git https://github.com/lucascouts/bentoo.git
```

Afterwards, simply run `emerge --sync bentoo`, and Portage should seamlessly make all our ebuilds available.

### Bentoo Portage

Here you can see the portage files configurations : https://github.com/lucascouts/bentoo-files
