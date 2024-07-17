# @summary Configures the mounts for amazon s3.
#
class amazon_s3::config {
  #
  file { $amazon_s3::s3fs_cred_dir:
    ensure => directory,
    mode   => '0750',
  }

  if $amazon_s3::aws_access_key and $amazon_s3::secret_access_key {
    file { '/etc/passwd-s3fs':
      ensure  => file,
      content => inline_template("${amazon_s3::aws_access_key}:${amazon_s3::secret_access_key}"),
      mode    => '0640',
      require => File[$amazon_s3::s3fs_cred_dir],
    }
  }
}
