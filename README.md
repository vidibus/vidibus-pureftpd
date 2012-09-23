# Vidibus::Pureftpd

Provides an ActiveModel-based abstraction of Pure-FTPd's [virtual users](http://download.pureftpd.org/pub/pure-ftpd/doc/README.Virtual-Users). [Pure-FTPd](http://www.pureftpd.org/project/pure-ftpd) is a free, secure, production-quality and standard-conformant FTP server.

This gem is part of [Vidibus](http://vidibus.org), an open source toolset for building distributed (video) applications. It has been tested with Ruby 1.8.7 and 1.9.3.


## Usage

Basic CRUD operations are available for `Vidibus::Pureftpd::User`:

```ruby
user = Vidibus::Pureftpd::User.new(
  :login => 'my_user',
  :password => 'verysecret',
  :directory => '/home/my_user'
)
# => returns a new user instance

user = Vidibus::Pureftpd::User.create(
  :login => 'my_user',
  :password => 'verysecret',
  :directory => '/home/my_user'
)
# => creates a new user and returns the instance

user = Vidibus::Pureftpd::User.find_by_login('my_user')
# => reads user from database and returns an user instance

user.save
# => saves user to database and returns true

user.destroy
# => removes user from database
```

Additionally, some methods are provided for your convenience:

```ruby
user.valid?
# => returns true if user is valid

user.persisted?
# => returns true if user has been saved to database

user.reload
# => reloads user from database
```

By default, `Vidibus::Pureftpd` will use these settings which you may override:

```ruby
Vidibus::Pureftpd.settings[:sysuser]        # => 'pureftpd_user'
Vidibus::Pureftpd.settings[:sysgroup]       # => 'pureftpd_group'
Vidibus::Pureftpd.settings[:password_file]  # => '/etc/pure-ftpd/pureftpd.passwd'
```


## Installation

Add the dependency to the Gemfile of your application: `gem 'vidibus-pureftpd'`. Then call bundle install on your console.

Installation of the Pure-FTPd server itself is quite simple:


### Install Pure-FTPd on Debian Lenny

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


### Install Pure-FTPd on OSX (if you want to test this gem on OSX)

```
brew install pure-ftpd
```

In order to perform the tests, a certain user is required. Create the user `pureftpd_user` with ID 483:

```
sudo dscl . create /Users/pureftpd_user uid 483
sudo dscl . create /Users/pureftpd_user gid 483
sudo dscl . create /Users/pureftpd_user UserShell /etc/pure-ftpd
sudo dscl . create /Users/pureftpd_user NFSHomeDirectory /dev/null
```

Then create the group `pureftpd_group`, also with ID 483:

```
sudo dscl . create /Groups/pureftpd_group gid 483
sudo dscl . merge /Groups/pureftpd_group users pureftpd_user
```

Check if user and group exist:

```
dscacheutil -q user
dscacheutil -q group
```

#### Debugging

To start the server, e.g. for debugging the users you've created, type `sudo /usr/local/sbin/pure-ftpd &`

You should now be able to connect via ftp by entering `ftp localhost`. To shut it down, call `sudo pkill pure-ftpd`

In order to check which users have been created, call `pure-pw list`.

If you really want to use Pure-FTPd as FTP server on OSX, you should consider installing [PureFTPd Manager](http://jeanmatthieu.free.fr/pureftpd/).


#### Troubleshooting

When using this gem in a web application, it may happen that the execution of the `pure-ftp` command fails. A reason for that may be that your webserver is not able access the command.

I solved this issue by adding a symlink:

```
sudo ln -s /usr/local/bin/pure-pw /usr/bin/pure-pw
```

## TODO

Implement all user options offered by Pure-FTPd:

```
-t <download bandwidth>
-T <upload bandwidth>
-n <max number of files>
-N <max Mbytes>
-q <upload ratio>
-Q <download ratio>
-r <allow client host>
-R <deny client host>
-i <allow local host>
-I <deny local host>
-y <max number of concurrent sessions>
-z <hhmm>-<hhmm>
```


## Copyright

Copyright (c) 2010-2012 Andre Pankratz. See LICENSE for details.
