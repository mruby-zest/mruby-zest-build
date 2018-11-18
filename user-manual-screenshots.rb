$delay = 10
$time  = 0
$time += $delay
$filter_cat = "/part0/kit0/adpars/GlobalPar/GlobalFilter/Pcategory"
#                   type of offset
#                   |       root event
#                   |       |  offset
#                   v       v  v
sched.active_event [:frame, $time, 0]

def bb_class(run, cls)
    widgets = run.filter_widgets(nil) do |x|
        x.class == cls
    end
    run.joint_bounding_box(widgets)
end

sched.add lambda {|run|
    $remote.settf("/part0/kit0/Psubenabled", true)
    $remote.settf("/part0/kit0/Ppadenabled", true)
    $remote.seti($filter_cat, 0)
    run.screenshot("doc/bank-read.png")
    run.screenshot("doc/info-tray.png",
                   bb_class(run, Qml::LogWidget))
    run.set_view_pos(:view, :add_synth)
    run.set_view_pos(:subview, :global)
    run.change_view
}

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
        run.set_view_pos(:vis, :filter)
        run.change_view
    }

    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.screenshot("doc/filter-formant.png",
                       bb_class(run, Qml::ZynAnalogFilter))
        # XXX something looks wrong with the formant visualization
        run.screenshot("doc/filter-formant-vis.png",
                       bb_class(run, Qml::VisFormant))
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
        $remote.sets("/part0/Pname", "supersaw")

        run.screenshot("doc/part-settings-controllers.png",
                       bb_class(run, Qml::ZynControllers))
        run.screenshot("doc/part-settings-portamento.png",
                       bb_class(run, Qml::ZynPortamento))
        run.screenshot("doc/part-settings-instrument.png",
                       bb_class(run, Qml::ZynInstrumentSettings))
        run.screenshot("doc/part-settings-scale.png",
                       bb_class(run, Qml::ZynScale))
    }

    $time += delay
    sched.active_event [:frame, $time, delay]

    sched.add lambda {|run|
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
    }
end

def capture_settings_global(sched)
    delay = $delay
    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :settings)
        run.change_view
    }

    $time += delay
    sched.active_event [:frame, $time, delay]
    sched.add lambda {|run|
        run.screenshot("doc/logo.png",
                       bb_class(run,Qml::ZynLogo))
        run.screenshot("doc/settings-global.png",
                       bb_class(run,Qml::Forms))
        widgets = run.filter_widgets(nil) do |x|
            x.children.length > 0 &&
                x.children[0].label == "bank root"
        end
        bb = run.joint_bounding_box(widgets)
        run.screenshot("doc/settings-bank-roots.png", bb)
        widgets = run.filter_widgets(nil) do |x|
            x.children.length > 0 &&
                x.children[0].label == "preset roots"
        end
        bb = run.joint_bounding_box(widgets)
        run.screenshot("doc/settings-preset-roots.png", bb)
    }
end

def capture_lfo(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :add_synth)
        run.set_view_pos(:subview, :global)
        run.set_view_pos(:subsubview, :amp)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/lfo.png",
                       bb_class(run, Qml::ZynLFO))
    }
end
def capture_env(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :add_synth)
        run.set_view_pos(:subview, :global)
        run.set_view_pos(:subsubview, :amp)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/env.png",
                       bb_class(run, Qml::ZynAmpEnv))
    }
end

def capture_add(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :add_synth)
        run.set_view_pos(:subview, :global)
        run.set_view_pos(:vis, :env)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/add-synth.png",
                       bb_class(run, Qml::ZynAddSynth))
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/amp-control.png",
                       bb_class(run, Qml::ZynAmpGeneral))
    }
end


def capture_pad(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :pad_synth)
        run.set_view_pos(:subview, :harmonics)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/pad-synth.png",
                       bb_class(run, Qml::ZynPadSynth))
    }
end

def capture_sub(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :sub_synth)
        run.set_view_pos(:subview, :global)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/sub-synth.png",
                       bb_class(run, Qml::ZynSubSynth))
    }
end

def capture_kit(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :kits)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/kit.png",
                       bb_class(run, Qml::ZynKit))
    }
end

capture_filter(sched)
capture_oscil(sched)
capture_settings(sched)
capture_settings_global(sched)

capture_lfo(sched)
capture_env(sched)

capture_add(sched)
capture_pad(sched)
capture_sub(sched)

capture_kit(sched)

delay = $delay
$time += delay
sched.active_event [:frame, $time, delay]
sched.add lambda {|run| exit }
