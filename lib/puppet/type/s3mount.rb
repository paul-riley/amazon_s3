require 'puppet/property/boolean'

# We want the mount to refresh when it changes.
Puppet::Type.newtype(:s3mount, self_refresh: true) do
  @doc = "@summary Manages mounted filesystems, including putting mount information into the mount table.

      The actual behavior depends on the value of the 'ensure' parameter.

      **Refresh:** `mount` resources can respond to refresh events (via
      `notify`, `subscribe`, or the `~>` arrow). If a `mount` receives an event
      from another resource **and** its `ensure` attribute is set to `mounted`,
      Puppet will try to unmount then remount that filesystem.

      **Autorequires:** If Puppet is managing any parents of a mount resource ---
      that is, other mount points higher up in the filesystem --- the child
      mount will autorequire them.

      **Autobefores:**  If Puppet is managing any child file paths of a mount
      point, the mount resource will autobefore them."

  feature :refreshable, 'The provider can remount the filesystem.',
          methods: [:remount]

  # Use the normal parent class, because we actually want to
  # call code when sync is called.
  newproperty(:ensure) do
    desc "Control what to do with this mount. Set this attribute to
        `unmounted` to make sure the filesystem is in the filesystem table
        but not mounted (if the filesystem is currently mounted, it will be
        unmounted).  Set it to `absent` to unmount (if necessary) and remove
        the filesystem from the fstab.  Set to `mounted` to add it to the
        fstab and mount it. Set to `present` to add to fstab but not change
        mount/unmount status."

    #  IS        -> SHOULD     In Sync  Action
    #  ghost     -> present    NO       create
    #  absent    -> present    NO       create
    # (mounted   -> present    YES)
    # (unmounted -> present    YES)
    newvalue(:defined) do
      provider.create
      return :mount_created
    end

    aliasvalue :present, :defined

    #  IS        -> SHOULD     In Sync  Action
    #  ghost     -> unmounted  NO       create, unmount
    #  absent    -> unmounted  NO       create
    #  mounted   -> unmounted  NO       unmount
    newvalue(:unmounted) do
      case retrieve
      when :ghost # (not in fstab but mounted)
        provider.create
        @resource.flush
        provider.unmount
        return :mount_unmounted
      when nil, :absent # (not in fstab and not mounted)
        provider.create
        return :mount_created
      when :mounted # (in fstab and mounted)
        provider.unmount
        syncothers # I guess it's more likely that the mount was originally mounted with
        # the wrong attributes so I sync AFTER the umount
        return :mount_unmounted
      else
        raise Puppet::Error, _('Unexpected change from %{current} to unmounted') % { current: current_value }
      end
    end

    #  IS        -> SHOULD     In Sync  Action
    #  ghost     -> absent     NO       unmount
    #  mounted   -> absent     NO       provider.destroy AND unmount
    #  unmounted -> absent     NO       provider.destroy
    newvalue(:absent, event: :mount_deleted) do
      current_value = retrieve
      provider.unmount if provider.mounted?
      provider.destroy unless current_value == :ghost
    end

    #  IS        -> SHOULD     In Sync  Action
    #  ghost     -> mounted    NO       provider.create
    #  absent    -> mounted    NO       provider.create AND mount
    #  unmounted -> mounted    NO       mount
    newvalue(:mounted, event: :mount_mounted) do
      # Create the mount point if it does not already exist.
      current_value = retrieve
      currently_mounted = provider.mounted?
      provider.create if [nil, :absent, :ghost].include?(current_value)

      syncothers

      # The fs can be already mounted if it was absent but mounted
      provider.property_hash[:needs_mount] = true unless currently_mounted
    end

    # insync: mounted   -> present
    #         unmounted -> present
    def insync?(is)
      if should == :defined && [:mounted, :unmounted].include?(is)
        true
      else
        super
      end
    end

    def syncothers
      # We have to flush any changes to disk.
      currentvalues = @resource.retrieve_resource

      # Determine if there are any out-of-sync properties.
      oos = @resource.send(:properties).select { |prop|
        unless currentvalues.include?(prop)
          raise Puppet::DevError, _("Parent has property %{name} but it doesn't appear in the current values") % { name: prop.name }
        end
        if prop.name == :ensure
          false
        else
          !prop.safe_insync?(currentvalues[prop])
        end
      }.each { |prop| prop.sync }.length
      @resource.flush if oos > 0
    end
  end

  newproperty(:device) do
    desc "The device providing the mount.  This can be whatever device
        is supporting by the mount, including network devices or
        devices specified by UUID rather than device path, depending
        on the operating system. On Linux systems it can contain
        whitespace."

    validate do |value|
      unless Facter.value(:kernel) == 'Linux'
        raise Puppet::Error, _('device must not contain whitespace: %{value}') % { value: value } if %r{\s}.match?(value)
      end
    end
  end

  # Solaris specifies two devices, not just one.
  newproperty(:blockdevice) do
    desc "The device to fsck.  This is property is only valid
        on Solaris, and in most cases will default to the correct
        value."

    # Default to the device but with "dsk" replaced with "rdsk".
    defaultto do
      if Facter.value('os.family') == 'Solaris'
        if (device = resource[:device]) && device.include?('/dsk/')
          device.sub(%r{/dsk/}, '/rdsk/')
        elsif (fstype = resource[:fstype]) && fstype == 'nfs'
          '-'
        else
          nil
        end
      else
        nil
      end
    end

    validate do |value|
      raise Puppet::Error, _('blockdevice must not contain whitespace: %{value}') % { value: value } if %r{\s}.match?(value)
    end
  end

  newproperty(:fstype) do
    desc "The mount type.  Valid values depend on the
        operating system.  This is a required option."

    validate do |value|
      raise Puppet::Error, _('fstype must not contain whitespace: %{value}') % { value: value } if %r{\s}.match?(value)
      raise Puppet::Error, _('fstype must not be an empty string') if value.empty?
    end
  end

  newproperty(:options) do
    desc "A single string containing options for the mount, as they would
        appear in fstab on Linux. For many platforms this is a comma-delimited
        string. Consult the fstab(5) man page for system-specific details.
        AIX options other than dev, nodename, or vfs can be defined here. If
        specified, AIX options of account, boot, check, free, mount, size,
        type, vol, log, and quota must be ordered alphabetically at the end of
        the list."

    validate do |value|
      raise Puppet::Error, _('options must not contain whitespace: %{value}') % { value: value } if %r{\s}.match?(value)
      raise Puppet::Error, _('options must not be an empty string') if value.empty?
    end
  end

  newproperty(:pass) do
    desc 'The pass in which the mount is checked.'

    defaultto do
      if @resource.managed?
        if Facter.value('os.family') == 'Solaris'
          '-'
        else
          0
        end
      end
    end
  end

  newproperty(:atboot, parent: Puppet::Property::Boolean) do
    desc "Whether to mount the mount at boot.  Not all platforms
        support this."

    def munge(value)
      munged = super
      if munged
        :yes
      else
        :no
      end
    end
  end

  newproperty(:dump) do
    desc "Whether to dump the mount.  Not all platform support this.
        Valid values are `1` or `0` (or `2` on FreeBSD). Default is `0`."

    if Facter.value('os.name') == 'FreeBSD'
      newvalue(%r{(0|1|2)})
    else
      newvalue(%r{(0|1)})
    end

    defaultto do
      0 if @resource.managed?
    end
  end

  newproperty(:target) do
    desc "The file in which to store the mount table.  Only used by
        those providers that write to disk."

    defaultto do
      if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
        @resource.class.defaultprovider.default_target
      else
        nil
      end
    end
  end

  newparam(:name) do
    desc 'The mount path for the mount. On Linux systems it can contain whitespace.'

    isnamevar

    validate do |value|
      unless Facter.value(:kernel) == 'Linux'
        raise Puppet::Error, _('name must not contain whitespace: %{value}') % { value: value } if %r{\s}.match?(value)
      end
    end

    munge do |value|
      value.gsub(%r{^(.+?)/*$}, '\1')
    end
  end

  newparam(:remounts) do
    desc "Whether the mount can be remounted  `mount -o remount`.  If
        this is false, then the filesystem will be unmounted and remounted
        manually, which is prone to failure."

    newvalues(:true, :false)
    defaultto do
      case Facter.value('os.name')
      when 'FreeBSD', 'Darwin', 'DragonFly', 'OpenBSD', "Amazon"
        false
      when 'AIX'
        if Facter.value(:kernelmajversion) == '5300'
          false
        elsif resource[:device]&.match(%r{^[^/]+:/})
          false
        else
          true
        end
      else
        true
      end
    end
  end

  def refresh
    # Only remount if we're supposed to be mounted.
    provider.remount if should(:fstype) != 'swap' && provider.mounted?
  end

  def value(name)
    name = name.to_sym
    property = @parameters[name]
    property&.value
  end

  # Ensure that mounts higher up in the filesystem are mounted first
  autorequire(:mount) do
    dependencies = []
    Pathname.new(@parameters[:name].value).ascend do |parent|
      dependencies.unshift parent.to_s
    end
    dependencies[0..-2]
  end

  # Autobefore the mount point's child file paths
  autobefore(:file) do
    dependencies = []
    file_resources = catalog.resources.select { |resource| resource.type == :file }
    children_file_resources = file_resources.select { |resource| File.expand_path(resource[:path]) =~ %r{^#{self[:name]}/.} }
    children_file_resources.each do |child|
      dependencies.push Pathname.new(child[:path])
    end
    dependencies
  end
end
