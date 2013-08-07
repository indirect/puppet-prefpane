Puppet::Type.newtype(:safari_ext) do
  @doc = "Manages Safari browser extensions on OS X"

  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the extension"
  end

  newparam(:source) do
    desc "The location of the extension"
    newvalues(/^https?:\/\//)
  end

end
