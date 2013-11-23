Puppet::Type.newtype(:prefpane) do
  @doc = "Manages OS X System Preference Panes"

  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto(:present)
  end

  newparam(:name, :namevar => true) do
    desc "The name of the preference pane"
  end

  newparam(:source) do
    desc "The network location of the archive containing the preference pane"
    newvalues(/^https?:\/\//)
  end

  newparam(:path) do
    desc "The directory inside the source archive that contains the preference pane"
  end

end
