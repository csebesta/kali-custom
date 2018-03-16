Kaliburn Linux
==============

**Kaliburn Linux** is a purely live distribution intended to meet the needs of IT professionals. It is derived from the standard Kali distribution, with a variety of modifications that make it a more useful tool for individuals in the IT industry.

Features
--------

- Simple customization through the kaliburn.sh script
- Inherits all the special features of a standard Kali Linux image
- A subdued and professional look and feel, featuring the popular Solarized color scheme
- Sane software defaults

Installation
------------

The Kaliburn image can be created by running the kaliburn.sh script. This script can take a moderately long amount of time to run depending on your network connection.

```
git clone https://github.com/csebesta/kali-custom
cd kali-custom
./kaliburn.sh
```

Once the script has finished, simply write the image to a device of your choice. The device `/dev/sdf/` is used for this example, though yours may differ. Always be careful when using the `dd` command. A conservative and reliable block size of 512k is shown in this example, as suggested by the Kali documentation.

```
cd live-build-config/images
dd if=kali-linux-light-rolling-amd64.iso of=/dev/sdf bs=512k status=progress
```

License
-------

This project is licensed under the MIT license.
