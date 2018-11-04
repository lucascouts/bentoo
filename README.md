# Bentoo
An user-friendly Stage4 of Funtoo Linux.

## with local overlays

[Local overlays](https://www.funtoo.org/Local_Overlay) should be managed via `/etc/portage/repos.conf/`.
create a `/etc/portage/repos.conf/bentoo.conf` file containing precisely:

```
[bentoo]
location = /usr/local/portage/bentoo
sync-type = git
sync-uri = https://github.com/lucascouts/bentoo.git
priority= 99
```

Afterwards, simply run `ego sync`, and Portage should seamlessly make all our ebuilds available.

## with layman

Invoke the following:

```
# layman -o https://raw.github.com/lucascouts/bentoo/master/repositories.xml -f -a bentoo
```

### Bentoo Portage config

Here you can see the portage files configurations : https://github.com/lucascouts/bentoo-portagedir
