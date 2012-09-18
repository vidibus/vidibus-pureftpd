# Vidibus::Pureftpd

Allows control of [Pure-FTPd](http://www.pureftpd.org/project/pure-ftpd), the free, secure, production-quality and standard-conformant FTP server.

This gem is part of [Vidibus](http://vidibus.org), an open source toolset for building distributed (video) applications.

## Installation

Add the dependency to the Gemfile of your application: `gem 'vidibus-pureftpd'`. Then call bundle install on your console.


## Usage

Add a user:

```
Vidibus::Pureftpd.add_user({
  :login => 'someuser',
  :password => 'verysecret',
  :directory => '/tmp'
})
```

Delete a user:

```
Vidibus::Pureftpd.delete_user(:login => 'someuser')
```

Change a user's password:

```
Vidibus::Pureftpd.change_password({
  :login => 'someuser',
  :password => 'whatever'
})
```


## Install Pure-FTPd on Debian Lenny

Get the package:

```
aptitude install pure-ftpd-common pure-ftpd
```

Add group pureftpd_group:

```
groupadd pureftpd_group
```

Add user pureftpd_user without permission to a home directory or any shell:

```
useradd -g pureftpd_group -d /dev/null -s /etc pureftpd_user
```

By default all user data will be saved in /etc/pure-ftpd/pureftpd.passwd, so make sure this file exists:

```
touch /etc/pure-ftpd/pureftpd.passwd
```

For fast access of user data, Pure-FTPd creates a "database", which is a binary file that is ordered and has an index for quick access. Let's create this database:

```
pure-pw mkdb
```

Set Pure-FTPd as a standalone server:

```
vim /etc/default/pure-ftpd-common

  # Replace this:
    STANDALONE_OR_INETD=inetd
  # With this:
    STANDALONE_OR_INETD=standalone
```

Ensure that Pure-FTPd server gets valid users from our pureftpd database file:

```
cd /etc/pure-ftpd/conf
vim PureDB

  # Check if the following line exists:
  /etc/pure-ftpd/pureftpd.pdb
```

Now you have point a symbolic link to the PureDB file:

```
cd /etc/pure-ftpd/auth
ln -s /etc/pure-ftpd/conf/PureDB 50pure
```

You should now see a new file "50pure" linking to ../conf/PureDB:

```
ls -ls
```

Finally, (re)start Pure-FTPd:

```
/etc/init.d/pure-ftpd restart
```

For more instructions, please [check this resource](http://linux.justinhartman.com/PureFTPd_Installation_and_Setup).


## Install Pure-FTPd on OSX for testing

```
brew install pure-ftpd
```

Create the user `pureftpd_user` with ID 483:

```
sudo dscl . create /Users/pureftpd_user uid 483
sudo dscl . create /Users/pureftpd_user gid 483
sudo dscl . create /Users/pureftpd_user UserShell /etc/pure-ftpd
sudo dscl . create /Users/pureftpd_user NFSHomeDirectory /dev/null
```

Create the group `pureftpd_group` with ID 483:

```
sudo dscl . create /Groups/pureftpd_group gid 483
sudo dscl . merge /Groups/pureftpd_group users pureftpd_user
```

Check if user and group exist:

```
dscacheutil -q user
dscacheutil -q group
```

Ensure that the database exists and is writable for the user that executes RSpec:

```
sudo mkdir /etc/pure-ftpd/
sudo touch /etc/pure-ftpd/pureftpd.passwd
sudo chown -R `whoami` /etc/pure-ftpd/
```

To start the server (not needed for testing), type:

```
sudo /usr/local/sbin/pure-ftpd &
```

You should be able to connect via ftp:

```
ftp localhost
```

Shut it down with:

```
pkill pure-ftpd
```


## Copyright

Copyright (c) 2010-2012 Andre Pankratz. See LICENSE for details.
