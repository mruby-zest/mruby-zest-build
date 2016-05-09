puts "Trying to create a remote instance"
remote = OSC::Remote.new
puts "Trying to create a view on the metadata of a parameter"
meta   = OSC::RemoteMetadata.new(remote, "/part0/kit0/adpars/VoicePar0/FreqLfo/Pfreq")
puts "Trying to dump some of said metadata"
puts meta.short_name

