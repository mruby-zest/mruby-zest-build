Widget {
    id: settings
    Forms {
        label: "Global Settings"
        TextField {
            tooltip: "Sample Rate:"
            label: "48 kHz"
        }
        ToggleButton {
            tooltip: "Swap Stereo:"
            label: "Swap Stereo"
            extern: settings.extern+"config/cfg.SwapStereo"
        }
        ToggleButton {
            tooltip: "Enable Output Compressor:"
            label: "Audio Compressor"
            extern: settings.extern+"config/cfg.AudioOutputCompressor"
        }
        TextField {
            tooltip: "Oscil Size:"
            label: "256 samples"
        }
        TextField {
            tooltip: "Buffer Size:"
            label: "128 samples"
        }
        NumEntry {
            tooltip: "XML Compression:"
            extern: settings.extern+"config/cfg.GzipCompression"
        }
        ToggleButton {
            tooltip: "Include disabled parts in save:"
            label: "XML Full Save"
            extern: settings.extern+"config/cfg.SaveFullXml"
        }
        ToggleButton {
            tooltip: "Ignore MIDI Program Change:"
            label: "MIDI PGM Chg"
            extern: settings.extern+"config/cfg.IgnoreProgramChange"
        }
    }
    Widget{
    function draw(vg) {
        vg.path do |v|
            v.rect(0,0,w,h)
            paint = v.linear_gradient(0,0,0,h,
            Theme::ModuleGrad1, Theme::ModuleGrad2)
            v.fill_paint paint
            v.fill
            v.stroke_color(color("000000"))
            v.stroke
        end
    }
        Text {
            label: "bank root"
        }
        Widget {
            Button {
                label: "prioritize"
            }
            Button {
                label: "+"
            }
            Button {
                label: "-"
            }
            function layout(l, selfBox) {
                Draw::Layout::hfill(l, selfBox, children, [0.7, 0.15, 0.15])
            }
        }
        function layout(l, selfBox) {
            Draw::Layout::vfill(l, selfBox, children, [0.9, 0.1])
        }
    }
    Widget {
    function draw(vg) {
        vg.path do |v|
            v.rect(0,0,w,h)
            paint = v.linear_gradient(0,0,0,h,
            Theme::ModuleGrad1, Theme::ModuleGrad2)
            v.fill_paint paint
            v.fill
            v.stroke_color(color("000000"))
            v.stroke
        end
    }
        Text {
            label: "preset roots"
        }
        Widget {
            Button {
                label: "prioritize"
            }
            Button {
                label: "+"
            }
            Button {
                label: "-"
            }
            function layout(l, selfBox) {
                Draw::Layout::hfill(l, selfBox, children, [0.7, 0.15, 0.15])
            }
        }
        function layout(l, selfBox) {
            Draw::Layout::vfill(l, selfBox, children, [0.9, 0.1])
        }
    }
    function layout(l, selfBox) {
        Draw::Layout::hpack(l, selfBox, children, 0, 1, 10)
    }
}
