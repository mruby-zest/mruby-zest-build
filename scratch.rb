#puts "Trying to create a remote instance"
#remote = OSC::Remote.new
#puts "Trying to create a view on the metadata of a parameter"
#meta   = OSC::RemoteMetadata.new(remote, "/part0/kit0/adpars/VoicePar0/FreqLfo/Pfreq")
#puts "Trying to dump some of said metadata"
#puts meta.short_name

#                   type of offset
#                   |       root event
#                   |       |  offset
#                   v       v  v
sched.active_event [:frame, 0, 0]

sched.add lambda {|run|
    run.set_view_pos(:view, :add_synth)
    run.change_view
}

sched.active_event [:frame, 0, 2]

sched.add lambda {|run|
    run.screenshot("test-screenshot-add-synth.png")
    run.set_view_pos(:view, :pad_synth)
    run.change_view
}

sched.active_event [:frame, 2, 2]

sched.add lambda {|run|
    run.screenshot("test-screenshot-pad-synth.png")
    run.set_view_pos(:view, :sub_synth)
    run.change_view
}

sched.active_event [:frame, 4, 2]

sched.add lambda {|run|
    exit
}
