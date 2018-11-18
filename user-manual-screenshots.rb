$delay = 10
$time  = 0
$filter_cat = "/part0/kit0/adpars/GlobalPar/GlobalFilter/Pcategory"
#                   type of offset
#                   |       root event
#                   |       |  offset
#                   v       v  v
sched.active_event [:frame, 0, 0]

sched.add lambda {|run|
    $remote.settf("/part0/kit0/Psubenabled", true)
    $remote.settf("/part0/kit0/Ppadenabled", true)
    $remote.seti($filter_cat, 0)
    run.set_view_pos(:view, :add_synth)
    run.set_view_pos(:subview, :global)
    run.change_view
}

def bb_class(run, cls)
    widgets = run.filter_widgets(nil) do |x|
        x.class == cls
    end
    run.joint_bounding_box(widgets)
end

def capture_filter(sched)
    puts "Capture Filter images..."
    delay = $delay
    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.screenshot("doc/add-synth.png",
                       bb_class(run, Qml::ZynAddSynth))
        run.set_view_pos(:subsubview, :filter)
        run.change_view
    }

    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.screenshot("doc/filter-analog.png",
                       bb_class(run,Qml::ZynAnalogFilter))
        $remote.seti($filter_cat, 1)
    }

    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.screenshot("doc/filter-formant.png", 
                       bb_class(run, Qml::ZynAnalogFilter))
        $remote.seti($filter_cat, 2)
    }

    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.screenshot("doc/filter-svf.png", 
                       bb_class(run, Qml::ZynAnalogFilter))
    }
end

def capture_oscil(sched)
    delay = $delay
    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :add_synth)
        run.set_view_pos(:subview, :oscil)
        run.change_view
    }


    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.screenshot("doc/osc-overall.png", 
                       bb_class(run, Qml::ZynOscil))
    }

    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        widgets = run.filter_widgets(nil) do |x|
            ret = false
            if(x.parent.class == Qml::ZynOscil &&
               x.parent.middle_panel == x)
                ret = true
            end
            ret
        end
        bb = run.joint_bounding_box(widgets)
        run.screenshot("doc/osc-tight.png", bb)
    }
end

def capture_settings(sched)
    delay = $delay
    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :part)
        run.change_view
    }

    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        widgets = run.filter_widgets(nil) do |x|
            x.label == "part settings"
        end
        bb = run.joint_bounding_box(widgets)
        run.screenshot("doc/part-settings-button.png", bb)
        
        widgets = run.filter_widgets(nil) do |x|
            a = x.label == "part settings"
            if(!a && x.parent.class == Qml::ZynSidebar)
                a = x.parent.part == x
            end
            a
        end
        bb = run.joint_bounding_box(widgets)
        run.screenshot("doc/part-settings-selection.png", bb)

        widgets = run.filter_widgets(nil) do |x|
            ret = false
            if(x.respond_to?(:extern))
                ret ||= x.extern == "/part0/Penabled"
                ret ||= x.extern == "/part15/Pname"
            end
            ret
        end
        bb = run.joint_bounding_box(widgets)
        run.screenshot("doc/part-settings-labelenable.png", bb)
        
        widgets = run.filter_widgets(nil) do |x|
            ret = false
            if(x.respond_to?(:extern))
                ret ||= x.extern == "/part0/Penabled"
                ret ||= x.extern == "/part2/Pname"
            end
            ret
        end
        bb = run.joint_bounding_box(widgets)
        run.screenshot("doc/part-settings-labelenable-close.png", bb)
        
        run.screenshot("doc/part-settings-controllers.png",
                       bb_class(run, Qml::ZynControllers))
        run.screenshot("doc/part-settings-portamento.png", 
                       bb_class(run, Qml::ZynPortamento))
    }
end

def capture_lfo(sched)
end
def capture_env(sched)
end
def capture_pad(sched)
end

capture_filter(sched)
capture_oscil(sched)
capture_settings(sched)

#TODO
capture_lfo(sched)
capture_env(sched)
capture_pad(sched)

delay = $delay
$time += delay
sched.active_event [:frame, $time, delay]
sched.add lambda {|run| exit }
