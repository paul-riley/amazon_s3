# @summary The individual s3 mount.
#
# Requires amazon_s3.
#
# @param mount_point
#   The path to mount.  Note, this module ensures the directory exists.
#
# @param ensure
#   Controls the mount and accepts the same values as the 'mount' type.
#
# @param options
#   Options used when mounting.
#
# @param aws_access_key
#   The access key for AWS.
#
# @param secret_access_key
#   The secret key for AWS.
#
# @param s3_bucket_name
#   The name of the s3 bucket. By default, it uses the title.
#
define amazon_s3::s3_mount (
  $mount_point,
  String $ensure                       = 'mounted',
  String $options                      = '_netdev,nonempty,allow_other,multireq_max=5',
  Optional[String] $aws_access_key     = undef,
  Optional[String] $secret_access_key  = undef,
  String $s3_bucket_name               = $title,
) {
  #
  if $aws_access_key and $secret_access_key {
    $creds_file = "${amazon_s3::s3fs_cred_dir}/${s3_bucket_name}"
    file { $creds_file:
      ensure  => file,
      content => inline_template("${aws_access_key}:${secret_access_key}"),
      mode    => '0600',
      require => File[$amazon_s3::s3fs_cred_dir],
      before  => File[$mount_point],
    }
    $new_options = "${options},passwd_file=${creds_file}"
  } else {
    $new_options = $options
  }

  file { $mount_point:
    ensure => directory,
  }

  # mount the s3 bucket
  mount { $title:
    ensure    => $ensure,
    name      => $mount_point,
    device    => "s3fs#${s3_bucket_name}",
    fstype    => 'fuse',
    options   => $new_options,
    remounts  => true,
    subscribe => File[$mount_point],
  }
}
