#puts "Trying to create a remote instance"
#remote = OSC::Remote.new
#puts "Trying to create a view on the metadata of a parameter"
#meta   = OSC::RemoteMetadata.new(remote, "/part0/kit0/adpars/VoicePar0/FreqLfo/Pfreq")
#puts "Trying to dump some of said metadata"
#puts meta.short_name

delay_size = 5

#                   type of offset
#                   |       root event
#                   |       |  offset
#                   v       v  v
sched.active_event [:frame, 0, 0]

sched.add lambda {|run|
    $remote.settf("/part0/kit0/Psubenabled", true)
    $remote.settf("/part0/kit0/Ppadenabled", true)
    run.set_view_pos(:view, :add_synth)
    run.set_view_pos(:subview, :oscil)
    run.change_view
}

sched.active_event [:frame, 1*delay_size, delay_size]

sched.add lambda {|run|
    run.screenshot("test-screenshot-add-synth.png")

    widgets = run.filter_widgets(nil) do |x|
        ret = false
        if(x.respond_to?(:label))
            ret = true if x.label.downcase == "base func."
            ret = true if x.label.downcase == "to sine"
        end
        ret
    end
    #puts "widget="
    #puts widgets
    #puts "end widgets"
    bb = run.joint_bounding_box(widgets)

    run.screenshot("test-screenshot-close-region.png", bb)

    run.set_view_pos(:view, :pad_synth)
    run.set_view_pos(:subview, :harmonics)
    run.change_view
}

sched.active_event [:frame, 2*delay_size, delay_size]

sched.add lambda {|run|
    run.screenshot("test-screenshot-pad-synth.png")
    #puts "PAD Synth = #{run.get_view_pos(:view)}"

    run.set_view_pos(:view, :sub_synth)
    run.change_view
}

sched.active_event [:frame, 3*delay_size, delay_size]

sched.add lambda {|run| run.screenshot("test-screenshot-sub-synth.png") }

views = [:kit, :effects, :midi_learn, :mixer,
         :banks, :about, :automate, :colors,
         :settings]
views.each_with_index do |v, ind| 
    puts v
    sched.add lambda {|run|
        run.set_view_pos(:view, v)
        run.change_view
    }
    sched.active_event [:frame, (ind+4)*delay_size, delay_size]

    sched.add lambda {|run|
        run.screenshot("test-screenshot-#{v.to_s}.png")
    }
end

sched.add lambda {|run|
    exit
}
