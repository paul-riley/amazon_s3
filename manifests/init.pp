# @summary Installs and configures S3fs-fuse in order to mount S3 buckets.
#
# @param aws_access_key
#   The access key for AWS.
#
# @param secret_access_key
#   The secret key for AWS.
#
# @param s3fs_version
#   The version of the s3fs.
#
#   @see https://github.com/s3fs-fuse/s3fs-fuse
#
# @param include_mime_package
#   Installs mime which is a requirement to build; however,
#   if this is used with the puppetlabs/apache module, a duplicate
#   resource error will occur even when using ensure_packages.
#   So if mime_support package is declared outside, set this to false.
#
# @param use_system_package
#   If the system being deployed already has s3fs in the repos, use this flag.
#
class amazon_s3 (
  Optional[String] $aws_access_key       = undef,
  Optional[String] $secret_access_key    = undef,
  String           $s3fs_version         = $amazon_s3::params::s3fs_version,
  Boolean          $include_mime_package = $amazon_s3::params::include_mime_package,
  Boolean          $use_system_package   = false,
) inherits amazon_s3::params {
  # == Variables == #

  # The source directory for compiling s3fs
  $s3fs_src_dir  = '/opt/s3fs'

  # The credentials directory for mount specific credentials.
  $s3fs_cred_dir = '/etc/s3fs.d'

  # Check supported operating systems
  unless $facts['os']['family'] == 'debian' or $facts['os']['family'] == 'RedHat' {
  fail("Unsupported OS ${facts['os']['family']}.\
    Please use a debian or redhat based system")
  }

  contain amazon_s3::install

  class { 'amazon_s3::config':
    require => Class['amazon_s3::install'],
  }
  contain amazon_s3::config
}
