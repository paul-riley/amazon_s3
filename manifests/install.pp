# @summary Installs the required software
#
class amazon_s3::install {
  #
  if str2bool($amazon_s3::include_mime_package) {
    $packages = concat($amazon_s3::params::base_packages,
    ['mime-support','libtool'])
  } else {
    $packages = $amazon_s3::params::base_packages
  }

  ensure_packages($packages)

  if $amazon_s3::use_system_package {
    package{ $amazon_s3::s3fs_package:
      ensure  => latest,
      require => Package[$packages],
    }

  }else{
    vcsrepo { $amazon_s3::s3fs_src_dir:
      ensure   => 'present',
      provider => 'git',
      source   => 'git://github.com/s3fs-fuse/s3fs-fuse.git',
      revision => $amazon_s3::s3fs_version,
      require  => Package[$packages],
    }

    exec { 'compile s3fs':
      command     => "${amazon_s3::s3fs_src_dir}/autogen.sh &&\
  ${amazon_s3::s3fs_src_dir}/configure --prefix=/usr &&\
  /usr/bin/make &&\
  /usr/bin/make install",
      cwd         => $amazon_s3::s3fs_src_dir,
      refreshonly => true,
      subscribe   => Vcsrepo[$amazon_s3::s3fs_src_dir],
    }
    exec { 'install s3fs':
      command     => '/usr/bin/make install',
      cwd         => $amazon_s3::s3fs_src_dir,
      refreshonly => true,
      subscribe   => Exec['compile s3fs'],
    }
  }
}
