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
