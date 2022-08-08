# Rucio RSE based on StoRM-webdav with OIDC token Authentication and CephFS as Storage plaform

How to add a Rucio RSE using a puppet StoRM and WebDav deployment with OIDC A&amp;A tokens. 


  * [Requirements](#requirements)
  * [Install StoRM Backend, StoRM Frontend and StoRM WebDav with puppet](#install-storm-backend--storm-frontend-and-storm-webdav-with-puppet)
    + [Setup CephFS storage folder](#setup-cephfs-storage-folder)
    + [Initial configuration](#initial-configuration)
    + [Installing repos, puppet and StoRM services](#installing-repos--puppet-and-storm-services)
  * [Configuring StoRM WebDav A&A](#configuring-storm-webdav-a-a)
  * [Create SSL certificates for HTTPS WebDav service](#create-ssl-certificates-for-https-webdav-service)
  * [Creating an identity](#creating-an-identity)
    + [Updating A&A crendentials in StoRM-WebDav](#updating-a-a-crendentials-in-storm-webdav)
    + [Adding IAM groups](#adding-iam-groups)
    + [Running Rucio Client](#running-rucio-client)
    + [Testing local RSE](#testing-local-rse)
    + [Test TPT (third part transfers)](#test-tpt--third-part-transfers-)
  * [Details of the installation and parameters to connect](#details-of-the-installation-and-parameters-to-connect)
  * [Add a new RSE from RUCIO Administrator console](#add-a-new-rse-from-rucio-administrator-console)
- [References](#references)


## Requirements

- VM or container with CentOS7.
- 4 GB RAM and 4 CPU cores.
- 50 GB of SSD or another storage technology connected.
- In this case we are going to add a CephFS connected to this VM, so a CephFS folder is required.

## Install StoRM Backend, StoRM Frontend and StoRM WebDav with puppet

### Setup CephFS storage folder

Enable shared storage with CephFS in `/storage/` and mount it with the `acl` and `user_xattr` options. 
To enable them, you must first install support for `acl` and `xattr`. Install this two tools related with the StoRM backend and FileSystem management: 
```
yum install acl
yum install attr
```

Type the next to confirm that you have enabled the `acl` support:

```
touch test
setfacl -m u:storm:rw test
```

Now we are test the same with xattr:

```
touch testfile
setfattr -n user.testea -v test testfile
getfattr -d testfile
```

Then add you CephFS to the VM with the attributes of acl, and user_xattr

```
mount -t ceph <IP_1>:6789,<IP_2>:6789,<IP_3>:6789:/volumes/_nogroup/12581a31-7af3-4451-8fe8-e54f5409d293 /storage/dteam/disk -o secretfile=/etc/ceph/ceph.client.storage-rucio.secret,name=user-rucio,acl,user_xattr
```

If you are using a block storage from Ceph instead CephFS, use the following to configure the extended FileSystem configuration:

Add `acl` to `fstab` to support to the folder where you have your storage (after it, remount it)

```
/dev/hda3     /storage      ext4     defaults, acl     0 0 
```

and then add  `user_xattr` to `fstab` to support to the folder where you have your storage (after it, remount it)


```
/dev/hda3     /storage     ext4     defaults,acl,user_xattr     0 0 
```



### Initial configuration

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

Set-up a hostname and check if your hostname is working. In our case we will use `spsrc.local` a localhost and then it will be put under NGINX.

```
hostname -f
```

Install OpenSSL to create self-signed certificates
```
yum install openssl
```

Create our own x509 certificate.
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



### Installing repos, puppet and StoRM services

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

*After install the application, exit from your session and login again to have puppet working*

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

Add a CephFS storage mount point (or a folder that points out) for `/storage/dteam/disk/` with  10TB:

```
TBC
```

Add permissions for this folder and the storm user (same permissions mask of the root folder within `/storage/dteam/`).

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

Apply it with:


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
{"status":"DOWN"}
```

If you see `{"status":"DOWN"}`, check the logs to know what is going on:

```
cat /var/log/storm/webdav/storm-webdav-server.log
```

*By default REDIS is not installed anyway, so you have to install manually.*



Get service metrics
```
curl http://localhost:8085/status/metrics?pretty=true
```

It will return: 

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


## Configuring StoRM WebDav A&A


*Before: stop the service*

```
systemctl stop storm-webdav
```

The config of StoRM-WebFav is spread across three files

```
/etc/systemd/system/storm-webdav.service.d/storm-webdav.conf
/etc/storm/webdav/config/application.yml
/etc/storm/webdav/sa.d/[your storm name].properties
```

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

## Create SSL certificates for HTTPS WebDav service

In order to make transfers from RUCIO it is necessary to provide valid SSL certificates signed by a trusted authority. For this we can use LetsEncript or our root certificate.

Once the certificates are obtained, they must be copied into the WebDAV directories for the web service:

```
/etc/grid-security/storm-webdav/hostkey.pem
/etc/grid-security/storm-webdav/hostcert.pem 
```

Then restart the WebDAV service:

```
systemctl stop storm-webdav
systemctl start storm-webdav
```


## Creating an identity 

Go to this page: https://iam-escape.cloud.cnaf.infn.it/login and create your acount if you dont have one. Once you have this credentials, go to the next link:

https://iam-escape.cloud.cnaf.infn.it/manage/dev/dynreg

- Click on: `Developer` **>>** `Self-service client registration`
- Then: `New Client`

In this screen add the following within the "Main" Tab:
- Client name: spsrc-rucio-storage
- Redirect URI(s): Add http://localhost:47056, http://localhost:8080, http://localhost:4242 (one per line)

Go to the tab "Access" and:
- Select just: `openid`, `profile`, `email`, `offline_access`,`wlcg.groups`

*Note: add the same items you have within the last configuration file under scope:*

After that, click on `Save` button and you will see the following variables:

Client ID: XXXXXX
Client Secret: XXXXXX
Client Configuration URL: XXXX
Registration Access Token: XXXX 

*Store these credentials in a safe place*

### Updating A&A crendentials in StoRM-WebDav

Modify this file /etc/storm/webdav/config/application.yml and complete `client-id:` and `client-secret:` with the client data that you get in the previous step:


```
....
   provider: escape
            client-name: <your clien name, here what we use: spsrc-rucio-storage>
            client-id: <your client id>
            client-secret: <your client id>
            scope:
....
```

Example:

```
....
   provider: escape
            client-name: spsrc-rucio-storage
            client-id: 1234-1234-....
            client-secret: zzzXXXXX
            scope:
....
```


### Adding IAM groups

Go to https://iam-escape.cloud.cnaf.infn.it/dashboard#!/home and click on `Group request` >> `Join a group`. 

Look for the next groups: `escape` and `escape/ska`

Add these groups and confirm, and then check if both groups are set in the group section.

### Running Rucio Client

Start this container:

*Change <iam_username> with your iam user previously created*

```
docker run --rm -it -e RUCIO_CFG_RUCIO_HOST=https://srcdev.skatelescope.org/rucio-dev -e RUCIO_CFG_AUTH_HOST=https://srcdev.skatelescope.org/rucio-dev -e RUCIO_CFG_AUTH_TYPE=oidc -e RUCIO_CFG_ACCOUNT=<iam_username> --name=ska-rucio-client registry.gitlab.com/ska-telescope/src/ska-rucio-client:release-1.28.0
```

Once inside, 

Verify the `/opt/rucio/etc/rucio.cfg`  snippet:

*Note: change <iam_username> to your user*

```
[client]
rucio_host = https://srcdev.skatelescope.org/rucio-dev
auth_host = https://srcdev.skatelescope.org/rucio-dev
ca_cert =
auth_type = oidc
username =
password =
account = <iam_username>
request_retries = 3
oidc_scope = openid profile wlcg.groups rucio fts fts:submit-transfer
oidc_audience = fts https://wlcg.cern.ch/jwt/v1/an
```

Then type:


```
rucio ping
```

or

```
rucio whoami
```

Upon running a rucio command you will be get a browser link to click on, click on this link which will ask you to authenticate with ESCAPE IAM and provide you with an authorization code. Enter this code in your command line terminal to complete authentication. This token is for 1 hour!.

You can export the token to an environment variable 

```
export TOKEN=`cat /tmp/user/.rucio_user/auth_token_for_account_<iam_username>`
```

Example:

```
export TOKEN=`cat /tmp/user/.rucio_user/auth_token_for_account_mparra`
```

### Testing local RSE


Install EPEL repository within this container and davix client:
```
yum install epel-release && yum update -y
yum install davix
```

List files:

```
davix-ls -l -H "Authorization: Bearer $TOKEN" https://<hostname>:<port>/<path>
```

Example:

```
davix-ls -l -H "Authorization: Bearer $TOKEN" https://spsrc14.iaa.csic.es:18026/disk/
```
### Test TPT (third part transfers)

Two options: 
- Install FTS client: To access the FTS REST CLI, run a container from the image ``gitlab-registry.cern.ch/fts/fts-rest:latest``.
- Install the CLI tools with `yum install fts-rest-cli` and `yum install fts-client`

And then run:

```
fts-rest-whoami -s https://fts3-pilot.cern.ch:8446 --access-token=`$TOKEN -s openid -s offline_access -s profile -s wlcg.groups
```

Check third party transfers:

```
fts-rest-transfer-submit --access-token=${TOKEN} -s https://fts3-pilot.cern.ch:8446/ <src> <dest>
```

Add `--insecure` flag if having trouble with certificates at `/etc/grid-security/certificates`



## Details of the installation and parameters to connect

By default a storage area named `dteam-disk` is accessible at the URL https://spsrc-local:8443/dteam-disk or, if anonymous access is granted, at https://dteam-disk:8085/dteam-disk


## Add a new RSE from RUCIO Administrator console

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

# References
- StoRM WebDav: http://italiangrid.github.io/storm/documentation/sysadmin-guide/1.11.21/installation-guides/webdav/storm-webdav-guide/index.html
- Configure StoRM WebDav Token Auth: https://gitlab.com/ska-telescope/src/ska-rucio-prototype/-/blob/master/notes/setup-storm-webdav-rse.md
- Add a new RSE from rucio-admin: https://gitlab.com/ska-telescope/src/ska-rucio-prototype/-/tree/master/#add-storage
- 

