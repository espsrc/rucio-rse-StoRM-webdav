# Rucio RSE based on StoRM-webdav with Token based Auth
How to add a Rucio RSE using StoRM and WebDav with tokens based A&amp;A

  * [Requirements](#requirements)
  * [Install StoRM Backend, StoRM Frontend and StoRM WebDav with puppet](#install-storm-backend--storm-frontend-and-storm-webdav-with-puppet)
  * [Configuring StoRM WebDav A&A](#configuring-storm-webdav-a-a)
  * [Details of the installation and parameters to connect](#details-of-the-installation-and-parameters-to-connect)
  * [Add a new RSE from RUCIO Admintrator console](#add-a-new-rse-from-rucio-admintrator-console)

## Requirements

- VM or Container with CentOS7.
- 4 GB RAM and 4 CPU cores.
- 50 GB of SSD.

## Install StoRM Backend, StoRM Frontend and StoRM WebDav with puppet


Install wget
```
yum install wget
```
Install NTP server and start it
```
yum install ntp
systemctl enable ntpd
systemctl start ntpd
```

Set-up a hostname and check if your hostname is working

```
hostname -f
```

Install OpenSSL to create self-signed certificates
```
yum install openssl
```

Create our x509 certificate

```
openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem
```

Create certificates folder and copy certificates to the `/etc/grid-security/`

```
mkdir /etc/grid-security/
cp cert.pem /etc/grid-security/hostcert.pem
cp key.pem  /etc/grid-security/hostkey.pem
```

Include permissions:
```
chmod 644 /etc/grid-security/hostcert.pem
chmod 400 /etc/grid-security/hostkey.pem
```

Install two tools related with the StoRM backend and FileSystem management
```
yum install acl
yum install attr
```

Time to install all the repositories for StoRM core environment

```
rpm --import http://repository.egi.eu/sw/production/umd/UMD-RPM-PGP-KEY
yum localinstall https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-12.noarch.rpm
yum localinstall http://repository.egi.eu/sw/production/umd/4/centos7/x86_64/updates/umd-release-4.1.3-1.el7.centos.noarch.rpm
wget http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo -O /etc/yum.repos.d/EGI-trustanchors.repo
yum install ca-policy-egi-core
yum install yum-utils -y
yum-config-manager --add-repo https://repo.cloud.cnaf.infn.it/repository/storm/storm-stable-centos7.repo
yum -y install epel-release
rpm -Uvh https://yum.puppetlabs.com/puppet5/el/7/x86_64/puppet5-release-5.0.0-6.el7.noarch.rpm
```

Install puppet
```
yum install -y puppet
```

Create the next file called `puppet.modules.sh`

```
#!/bin/bash
# EPEL repo
puppet module install puppet-epel
# UMD4 repo
puppet module install cnafsd-umd4
# NTP service
puppet module install puppetlabs-ntp
# fetch-crl and all CA certificates
puppet module install puppet-fetchcrl
# voms
puppet module install lcgdm-voms
# bdii
puppet module install cnafsd-bdii
# storm services and utils
puppet module install cnafsd-storm
# lcmaps module (only for test purpose)
puppet module install cnafsd-lcmaps
```

Then execute

```
sh puppet.modules
```

Create a file named setup.pp and include the next

```
include epel
include umd4
include ntp
include fetchcrl

# install and configure dteam vo
include voms::dteam

# add storm and edguser users and groups
include storm::users

# storage root directories for all the storage areas
# Just for test purpose. In production you should not need this part.
$storage_area_root_directories = [
  '/storage/dteam',
  '/storage/dteam/disk',
  '/storage/dteam/tape',
]
storm::rootdir { '/storage': }
storm::sarootdir { $storage_area_root_directories: }

# install all StoRM repositories and enable only stable repo
# install also UMD4 repo and EPEL
class { 'storm::repo':
  enabled      => ['stable'],
}

# This class installs LCMAPS and LCAS and configure them with some default files stored into the module.
# LCMAPS class is used ONLY FOR TEST PURPOSE. In production, configure LCMAPS/LCAS and pool accounts on your own with YAIM.
class { 'lcmaps':
  pools => [{
    'name'     => 'dteam',
    'size'     => 100,
    'vo'       => 'dteam',
    'group'    => 'dteam',
    'groups'   => ['dteam'],
    'gid'      => 9100,
    'base_uid' => 9100,
    'role'     => 'NULL',
  }],
}

# install bdii
class { 'bdii':
  firewall   => false,
  bdiipasswd => 'supersecretpassword', # avoid service reloading at each run of Puppet agent
}

Class['storm::users']
-> Class['storm::repo']
-> Class['lcmaps']
```

Once created, run the puppet file

```
puppet apply setup.pp
```

Now is time to configure the deployment of the main components of StoRM with puppet. Create a file named  manifest.pp.

```
$host='spsrc.local'

include storm::db

Class['storm::db']
-> Class['storm::backend']
-> Class['storm::frontend']
-> Class['storm::gridftp']
-> Class['storm::webdav']

class { 'storm::backend':
  db_username           => 'storm',
  db_password           => 'storm',
  gsiftp_pool_members   => [
    {
      'hostname' => $host,
    },
  ],
  hostname              => $host,
  service_du_enabled    => true,
  srm_pool_members      => [
    {
      'hostname' => $host,
    }
  ],
  storage_areas         => [
    {
      'name'          => 'dteam-disk',
      'root_path'     => '/storage/dteam/disk',
      'access_points' => ['/disk'],
      'vos'           => ['dteam'],
      'online_size'   => 50,
    },
  ],
  transfer_protocols    => ['file', 'gsiftp', 'webdav'],
  xmlrpc_security_token => 'NS4kYAZuR65XJCq',
  webdav_pool_members   => [
    {
      'hostname' => $host,
    },
  ],
}

class { 'storm::frontend':
  be_xmlrpc_host  => $host,
  be_xmlrpc_token => 'NS4kYAZuR65XJCq',
  db_user         => 'storm',
  db_passwd       => 'storm',
}

class { 'storm::gridftp':
  redirect_lcmaps_log => true,
  llgt_log_file       => '/var/log/storm/storm-gridftp-lcmaps.log',
}



class { 'storm::webdav':
  hostnames     => [$host],
  storage_areas => [
    {
      'name'          => 'dteam-disk',
      'root_path'     => '/storage/dteam/disk',
      'access_points' => ['/disk'],
      'vos'           => ['dteam'],
    },
  ],
}
```

Apply it with 


```
puppet apply manifest.pp
```

Check StoRM status:

```
systemctl status storm-webdav
```

Check that the WebDav service responds
```
curl http://localhost:8085/actuator/health
{"status":"UP"}
```

Get service metrics
```
curl http://localhost:8085/status/metrics?pretty=true
```
```
{
  "version" : "4.0.0",
  "gauges" : {
    "jvm.gc.G1-Old-Generation.count" : {
      "value" : 0
    },
    "jvm.gc.G1-Old-Generation.time" : {
      "value" : 0
    }
    ...
}
```

Check logs of StoRM WebDav 

```
cat /var/log/storm/webdav/storm-webdav-server.log
```

## Configuring StoRM WebDav A&A

The config is spread across three files

/etc/systemd/system/storm-webdav.service.d/storm-webdav.conf
/etc/storm/webdav/config/application.yml
/etc/storm/webdav/sa.d/[your storm name].properties

Edit an existing template `/etc/storm/webdav/sa.d/sa.properties.template` and save it as `storm-webdav-test-sa.properties`
Remove all the directives and use the next:

```
name=dteam-disk
rootPath=/storage/dteam/disk
accessPoints=/disk
orgs=https://iam-escape.cloud.cnaf.infn.it/

anonymousReadEnabled=false
voMapEnabled=false

orgsGrantReadPermission=true
orgsGrantWritePermission=true
wlcgScopeAuthzEnabled=true
```

More info about it here: https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md

Now is time to edit the following file /etc/storm/webdav/config/application.yml to set-up the credentials A&A.

```
oauth:
enable-oidc: true
issuers:
    - name: escape
    issuer: https://iam-escape.cloud.cnaf.infn.it/
spring:
security:
    oauth2:
    client:
        provider:
        escape:
            issuer-uri: https://iam-escape.cloud.cnaf.infn.it/
        registration:
        escape:
            provider: escape
            client-name: ska-storm-webdav
            client-id: <redacted>
            client-secret: <redacted>
            scope:
            - openid
            - profile
            - wlcg.groups
storm:
voms:
    trust-store:
    dir: ${STORM_WEBDAV_VOMS_TRUST_STORE_DIR:/etc/grid-security/certificates}
```

Restart the StoRM WebDav

```
systemctl start storm-webdav
```

Check the status

```
systemctl status storm-webdav
```

Check the service logs here:

```
tail /var/log/storm/webdav/storm-webdav-server.log
```

Again,  validate the status of the service if logs look good.

curl http://spsr.local:8085/actuator/health
curl http://spsr.local:8085/status/metrics?pretty=true 


## Details of the installation and parameters to connect

By default a storage area named `dteam-disk` is accessible at the URL https://spsrc-local:8443/dteam-disk or, if anonymous access is granted, at http://dteam-disk:8085/dteam-disk


## Add a new RSE from RUCIO Admintrator console

Add a deterministic RSE for our SPSRC

```
rucio-admin rse add SPSRC
```

Point the RSE to an FTS

```
rucio-admin rse set-attribute --rse SPSRC --key fts --value https://fts3-pilot.cern.ch:8446
```

Set Tape field to false since where are not providing Tape storage.

```
rucio-admin rse set-attribute --rse SPSRC --key istape --value False
```

Allow the `root` user (unlimited) access

```
rucio-admin account set-limits root SPSRC "infinity"
```

Configure one or more protocols

```
rucio-admin rse add-protocol --hostname spsrc-rucio.iaa.csci.es --scheme https --prefix '....' --port 443 --imp 'rucio.rse.protocols.gfal.Default' --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}' SPSRC
```

If adding more than one, set the TPC priority accordingly. Also, if adding root protocol, the corresponding prefix requires an additional slash (/) at the beginning.

```
rucio-admin rse add-protocol --hostname spsrc-rucio.iaa.csci.es --scheme gsiftp --prefix '....' --port 2811 --imp 'rucio.rse.protocols.gfal.Default' --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy": 2}, "lan": {"read": 1, "write": 1, "delete": 1}}' SPSRC
```

Add links to other RSEs

```
rucio-admin rse add-distance SPSRC XXX
rucio-admin rse add-distance XXX SPSRC
...
```


