Widget {
    id: bank

    property Symbol mode: :read
    property Symbol ind_selected: nil

    function doSearch()
    {
        search_  = bank_name.selected_val
        search_ += " " + bank_type.selected
        search_ += " " + bank_tag.selected
        search_ += " " + search.label
        $remote.action("/bank/search", search_)
    }

    function doBank()
    {
        doSearch if self.mode == :read
        setBank  if self.mode == :write
    }

    function setBank()
    {
        # If no bank is selected, clear the patch column, otherwise
        # it will display EMPTY PRESET in each slot, but with no
        # bank to write to, it's not possible to write anything.
        if (bank_name.selected_val.empty?)
            ins_sel.clear_all
        else
            $remote.action("/bank/blist", bank_name.selected_val)
        end
    }

    function doType()
    {
        doSearch if self.mode == :read
        setType  if self.mode == :write
    }

    function setType()
    {
        part = root.get_view_pos(:part)
        sel = bank_type.selected_id
        $remote.action("/part#{part}/info.Ptype", sel)
    }

    function doLoad()
    {
        ins = ins_sel.selected_val
        self.ind_selected = ins.to_i
        part = root.get_view_pos(:part)
        return if part.class != Fixnum
        $remote.action("/load_xiz", part, ins) if !ins.empty?
        $remote.damage("/part#{part}/");
    }

    function doSave()
    {
        part = root.get_view_pos(:part)
        if bank_name.selected_val.empty?
            self.root.log(:warning, "Can't save - no bank selected")
        elsif ins_sel.selected_val.empty?
            self.root.log(:warning, "Can't save - no patch slot selected")
        else
            $remote.action("/bank/save_to_slot", part, ins_sel.selected_val.to_i)
            self.root.log(:success, "Save to slot " + ins_sel.selected_val)
            # Reload list because contents may have changed due to save
            bank.setBank
        end
    }
    
    function doOverwrite()
    {
        part = root.get_view_pos(:part)
        $remote.action("/part#{part}/savexml")
        if (ins_sel.selected_val.empty?)
            self.root.log(:success, "overwrite current patch")
        else
            self.root.log(:success, "write to: " + ins_sel.selected_val)
        end
    }

    function doWrite()
    {
        doOverwrite() if bank.mode == :read
        doSave() if bank.mode == :write
    }

    function doInsSelect()
    {
        doLoad if self.mode == :read
    }
    
    function doRescan()
    {
        $remote.action("/bank/rescan")
        doBank
    }

    Widget {
        id: lhs
        SearchBox {
            id: search
            whenValue: lambda { bank.doSearch }
        }
        Widget {
            SelColumn {
                id: bank_name
                label:  "bank"
                skip:   true
                extern: "/bank/bank_list"
                whenValue: lambda { ins_sel.clear_sel
                                    bank.doBank }
            }
            SelColumn {
                id: bank_type
                label: "type"
                extern: "/bank/types"
                whenValue: lambda { ins_sel.clear_sel
                                    bank.doType }
            }
            SelColumn {
                id: bank_tag
                label: "tag"
                extern: "/bank/tags"
                whenValue: lambda { ins_sel.clear_sel
                                    bank.doSearch }
            }
            function layout(l, selfBox) {
                Draw::Layout::hfill(l, selfBox, children, [0.3, 0.3, 0.4])
            }
        }

        function layout(l, selfBox) {
            children[0].fixed(l, selfBox, 0, 0.00, 1, 0.05)
            children[1].fixed(l, selfBox, 0, 0.05, 1, 0.95)

            selfBox
        }
    }
    Widget {
        id: rhs
        Widget {
            id: rwbox
            TabButton {
                label: "read"
                value: true
                whenClick: lambda { rwbox.setrw(0) }
                layoutOpts: [:no_constraint]
            }
            TabButton {
                label: "write"
                whenClick: lambda { rwbox.setrw(1) }
                layoutOpts: [:no_constraint]
            }
            TriggerButton {
                id: trigger
                label: "overwrite"
                whenValue: lambda { bank.doWrite() }
            }
            TriggerButton {
                label: "rescan"
                whenValue: lambda { bank_name.clear
                                    bank.doRescan() }
            }
            function setrw(x)
            {
                if(x == 0)
                    bank.mode = :read
                    ins_sel.childTooltipPrefix = "File: "
                    trigger.label = "overwrite"
                    trigger.damage_self
                    children[0].value = true
                    children[1].value = false
                else
                    bank.mode = :write
                    ins_sel.childTooltipPrefix = "Slot  "
                    trigger.label = "execute"
                    trigger.damage_self
                    children[0].value = false
                    children[1].value = true
                end
                bank.doBank
                children[0].tooltip = "read mode (overwrite re-saves latest loaded patch)"
                children[1].tooltip = "write mode (to write: select slot, then press execute)"
                children[0].damage_self
                children[1].damage_self
                # Clear selection, so that a previous read selection does
                # not remain in write mode (the selections in read mode
                # are path name strings, and slot numbers in write mode;
                # so a string will be converted to slot 0).
                ins_sel.clear_sel
            }

            function layout(l, selfBox) {
                Draw::Layout::hpack(l, selfBox, children)
            }
        }
        Widget {
            SelColumn {
                id: ins_sel
                extern: "/bank/search_results"
                label: "preset"
                number: false
                skip:   true
                childTooltipPrefix: "File: "
                whenValue: lambda {bank.doInsSelect}
            }
            ZynPatchInfo {}

            function layout(l, selfBox) {
                children[0].fixed(l, selfBox, 0.0, 0, 0.5, 1)
                children[1].fixed(l, selfBox, 0.5, 0, 0.5, 1)

                selfBox
            }
        }
        function layout(l, selfBox)
        {
            children[0].fixed(l, selfBox, 0, 0.00, 1, 0.05)
            children[1].fixed(l, selfBox, 0, 0.05, 1, 0.95)

            selfBox
        }
    }
    function layout(l, selfBox)
    {
        rhs.fixed(l,  selfBox, 0.5, 0, 0.5, 1)
        lhs.fixed(l, selfBox, 0.0, 0, 0.5, 1)

        selfBox
    }

    function setup(old=nil)
    {
    }

}
