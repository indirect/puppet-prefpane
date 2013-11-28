require 'facter/util/plist'

Puppet::Type.type(:prefpane).provide(:download) do
  desc "Manages OS X system preference panes available on the internet"

  confine :operatingsystem => :darwin

  commands :chown   => "chown"
  commands :cp      => "cp"
  commands :curl    => "/usr/bin/curl"
  commands :ditto   => "ditto"
  commands :hdiutil => "hdiutil"
  commands :rm      => "rm"
  commands :tar     => "tar"

  def self.instances
    return [] unless File.exist?(receipt_path)
    Dir.entries(receipt_path)[2..-1].map{|n| new(:name => n) }
  end

  def self.receipt_path(path = nil)
    File.join ["/var/db/puppet/prefpane", path].compact
  end

  def self.prefpanes_path(path = nil)
    File.join ["/Users", Facter[:boxen_user].value, "/Library/PreferencePanes", path].compact
  end

  def exists?
    File.exist? self.class.receipt_path(@resource[:name])
  end

  def create
    self.fail "Source URL is required" unless @resource[:source]
    self.fail "Name is required" unless @resource[:name]
    download
    extract
  end

  def destroy
    rm "-rf", self.class.prefpanes_path(@resource[:name]+".prefPane")
    rm self.class.receipt_path(@resource[:name])
  end

  def source_ext
    @source_ext ||= @resource[:source].match(/dmg|zip|tgz|tar\.gz|tbz|tar\.bz$/).to_s
    @source_ext || self.fail("Don't know how to install from this kind of source")
  end

  def cached_source
    @cached_source ||= File.join("/opt/boxen/cache", "#{@resource[:name]}.#{source_ext}")
  end

  def download
    unless File.exist?(cached_source)
      curl "-Lks", "-o", cached_source, @resource[:source]
    end
  end

  def extract
    # decompress and/or mount the dmg
    temp_dir = Dir.mktmpdir
    case source_ext
    when "zip"
      ditto "-xk", cached_source, temp_dir
    when "tgz", "tar.gz"
      tar "-zxf", cached_source, temp_dir
    when "tbz", "tar.bz"
      tar "-jxf", cached_source, temp_dir
    when "dmg"
      temp_dmg = File.join(temp_dir, @resource[:name])
      hdiutil "convert", cached_source, "-format", "UDTO", "-o", temp_dmg
      plist = hdiutil "mount", "-plist", "-nobrowse", "-readonly", "-mountrandom", "/tmp", "#{temp_dmg}.cdr"
      mount = Plist.parse_xml(plist)['system-entities'].map{|e| e['mount-point'] }.compact.first
    else
      self.fail "Unknown source type: #{source_ext.inspect}"
    end

    # copy into PreferencePanes
    path_parts = [(mount || temp_dir), (@resource[:path] || '**'), "#{@resource[:name]}.prefPane"]
    prefpane_path = Dir[File.join(*path_parts.compact)][0]
    cp "-a", prefpane_path, self.class.prefpanes_path

    # ensure ownership by user
    installed_path = self.class.prefpanes_path(@resource[:name]+".prefPane")
    chown "-R", "#{Facter[:boxen_user].value}:admin", installed_path

    # write out receipt
    FileUtils.mkpath(self.class.receipt_path)
    File.open(self.class.receipt_path(@resource[:name]), "w") do |f|
      f.puts "name: '#{@resource[:name]}'"
      f.puts "source: '#{@resource[:source]}'"
    end
  ensure
    # clean up after ourselves
    hdiutil "eject", mount if mount
    FileUtils.remove_entry_secure(temp_dir) if temp_dir
  end

end
