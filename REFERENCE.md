# Reference
<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

**Classes**

* [`amazon_s3`](#amazon_s3): Installs and configures S3fs-fuse in order to mount S3 buckets.
* [`amazon_s3::config`](#amazon_s3config): Configures the mounts for amazon s3.
* [`amazon_s3::install`](#amazon_s3install): Installs the required software
* [`amazon_s3::params`](#amazon_s3params): Default parameter valuse for amazon_s3 module

**Defined types**

* [`amazon_s3::s3_mount`](#amazon_s3s3_mount): The individual s3 mount.

**Resource types**

* [`s3mount`](#s3mount): A special mount type that fixes bug in mount for Amazon Linux.

## Classes

### amazon_s3

Installs and configures S3fs-fuse in order to mount S3 buckets.

#### Parameters

The following parameters are available in the `amazon_s3` class.

##### `aws_access_key`

Data type: `Optional[String]`

The access key for AWS.

Default value: `undef`

##### `secret_access_key`

Data type: `Optional[String]`

The secret key for AWS.

Default value: `undef`

##### `s3fs_version`

Data type: `String`

The version of the s3fs.

@see https://github.com/s3fs-fuse/s3fs-fuse

Default value: $amazon_s3::params::s3fs_version

##### `include_mime_package`

Data type: `Boolean`

Installs mime which is a requirement to build; however,
if this is used with the puppetlabs/apache module, a duplicate
resource error will occur even when using ensure_packages.
So if mime_support package is declared outside, set this to false.

Default value: $amazon_s3::params::include_mime_package

##### `use_system_package`

Data type: `Boolean`

If the system being deployed already has s3fs in the repos, use this flag.

Default value: `false`

### amazon_s3::config

Configures the mounts for amazon s3.

### amazon_s3::install

Installs the required software

### amazon_s3::params

Default parameter valuse for amazon_s3 module

## Defined types

### amazon_s3::s3_mount

Requires amazon_s3.

#### Parameters

The following parameters are available in the `amazon_s3::s3_mount` defined type.

##### `mount_point`

Data type: `Any`

The path to mount.  Note, this module ensures the directory exists.

##### `ensure`

Data type: `String`

Controls the mount and accepts the same values as the 'mount' type.

Default value: 'mounted'

##### `options`

Data type: `String`

Options used when mounting.

Default value: '_netdev,nonempty,allow_other,multireq_max=5'

##### `aws_access_key`

Data type: `Optional[String]`

The access key for AWS.

Default value: `undef`

##### `secret_access_key`

Data type: `Optional[String]`

The secret key for AWS.

Default value: `undef`

##### `s3_bucket_name`

Data type: `String`

The name of the s3 bucket. By default, it uses the title.

Default value: $title

# Types

Custom types available

## `s3mount`

Mount type for Linux OS's. Fixed bug in Mount with Amazon Linux 2



