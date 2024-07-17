# amazon_s3


## Overview

Manages mounting s3 buckets. This was cloned from the [Amazon S3 Project](https://bitbucket.org/landcareresearch/puppet-amazon-s3)

## Module Description

Compiles and installs s3fs-fuse (from source) to provide support for mounting
S3 buckets.  See: [s3fs-fuse](https://github.com/s3fs-fuse/s3fs-fuse).

Using the system packages is now an option if compilation is not required.

## Setup

### Requirements for amazon_s3

* S3 Bucket Permissions (one of the below)
  * [Amazon Access keys](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSGettingStartedGuide/AWSCredentials.html).
  * [IAM Role attached to EC2 Instance](https://aws.amazon.com/blogs/security/easily-replace-or-attach-an-iam-role-to-an-existing-ec2-instance-by-using-the-ec2-console)
* An S3 Bucket.
* Make sure the IAM user has [access](http://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html) to your S3 bucket.

### Beginning with amazon_s3

To install s3fs and setup the configuration for mounting with default parameters.
Note, its recommended to NOT store the access key or secret key in your puppet manifest.
Its a good practice to use [hiera](https://docs.puppetlabs.com/hiera/1/) and [eyaml](https://github.com/TomPoulton/hiera-eyaml).

```puppet
   class {'amazon_s3':
    aws_access_key    => 'ACCESS_KEY',
    secret_access_key => 'SECRET_KEY',
   }
```

Creates a mount with default parameters.

```puppet
   amazon_s3::s3_mount{'s3_mount':
    mount_point => '/mnt/s3_mount',
    require     => Class['amazon_s3'],
   }
```

## API

See REFERENCE.md for details.

## Limitations

Only works with Debian and RedHat based OS's.

## Development

The module is open source and available at [GitHub](https://github.com/paul-riley/amazon_s3).  Please fork or contribute :)
