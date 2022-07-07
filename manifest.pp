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
