# This Ruby file is dedicated to generating the Zyn-Fusion UI images used in the manual.
#
# For the sake of readability, the code is split into functions,
# each dedicated to a different to generating different groups of or single images.
#
# Each screenshot is made by taking $delay time to open the appropriate window,
# and $delay time to make and store the screenshot.
#
# Usually, we recommend you start Zyn on port 1337,
# and Zest will automatically look for it there.
#
# On *nix systems, the commands for that (without specified paths) are:
#
# zynaddsubfx -I null -O null -U -P 1337
# zest --script user-manual-screenshots.rb

# ==========================================================================================

$delay = 10
$time  = 0
$time += $delay
$filter_cat = "/part0/kit0/adpars/GlobalPar/GlobalFilter/Pcategory"
#                   type of offset
#                   |       root event
#                   |       |      offset
#                   v       v      v
sched.active_event [:frame, $time, 0]

# Given a runtime run and class cls,
# outputs the bounding box that contains
# all currently instantiated instances of that class
def bb_class(run, cls)
    widgets = run.filter_widgets(nil) do |x|
        x.class == cls
    end
    run.joint_bounding_box(widgets)
end

sched.add lambda {|run|

    # Makes the 'doc' folder if it doesn't exist

    unless File.directory?("doc")
      Dir.mkdir("doc")
      puts "'doc' folder created."
    else
      puts "'doc' folder already exists."
    end

    $remote.settf("/part0/kit0/Psubenabled", true)
    $remote.settf("/part0/kit0/Ppadenabled", true)
    $remote.seti($filter_cat, 0)

    run.screenshot("doc/bank-read.png")
    run.screenshot("doc/info-tray.png",
                   bb_class(run, Qml::LogWidget))
    run.screenshot("doc/footer.png",
                   bb_class(run, Qml::ZynFooter))

    run.set_view_pos(:view, :add_synth)
    run.set_view_pos(:subview, :global)
    run.change_view

}

# ==========================================================================================

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

def capture_osc(sched)
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
end

def capture_osc_midpanel(sched)
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

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/part-settings.png",
                       bb_class(run, Qml::ZynPart))
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
        $remote.sets("/part0/Pname", "Supersaw")

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

def capture_mixer(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :mixer)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/mixer.png",
                       bb_class(run, Qml::ZynMixer))
    }
end

def capture_macro_learn(sched)
    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.set_view_pos(:view, :automate)
        run.change_view
    }

    $time += $delay
    sched.active_event [:frame, $time, $delay]
    sched.add lambda {|run|
        run.screenshot("doc/macro-learn.png",
                       bb_class(run, Qml::ZynAutomation))
    }
end

# ==========================================================================================

# All the commented function generate various images which are currently not used by the manual.
# If you believe the manual is missing images, look there first.

# Synths
capture_add(sched)
capture_pad(sched)
capture_sub(sched)

# Other panels available from the main panel
capture_kit(sched)
capture_mixer(sched)
capture_macro_learn(sched)

# Synthesis modules
capture_osc(sched)
# capture_osc_midpanel(sched)

# Currently unused
# capture_filter(sched)
capture_settings(sched)
# capture_settings_global(sched)
# capture_lfo(sched)
# capture_env(sched)

# ==========================================================================================

# Exiting
delay = $delay
$time += delay
sched.active_event [:frame, $time, delay]
sched.add lambda {|run| exit }
