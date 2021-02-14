Button {
    id: copy_button

    property Int index: nil

    onExtern: {
        copy_button.tooltip = "copy from " + copy_button.extern.to_s
    }

    function layout(l, selfBox) {
        l.aspect(selfBox, 1, 1)
        selfBox
    }

    function animate()
    {
        return if self.value == 0
        return if self.value == false
        return if self.value == true
        self.value *= 0.9
        self.value  = 0 if self.value < 0.02
        damage_self
    }

    function onMousePress(ev) {
        return if !self.active
        self.value = 1.0
        if($remote && extern && !extern.empty?)
            if(self.index)
                $remote.action("/presets/copy", extern, self.index)
            else
                $remote.action("/presets/copy", extern)
            end
        end
        damage_self
    }
    label: "C"
}
