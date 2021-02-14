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
        $remote.action("/bank/blist", bank_name.selected_val)
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
        if not ins_sel.selected_val.nil?
            $remote.action("/bank/save_to_slot", part, ins_sel.selected_val.to_i)
        else
            return
        end
    }
    
    function doSavePart()
    {
        part = root.get_view_pos(:part)
        $remote.action("/part#{part}/savexml")
    }

    function doInsSelect()
    {
        doLoad if self.mode == :read
        doSave if self.mode == :write
    }
    
    function doRescan()
    {
        $remote.action("/bank/rescan")
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
                whenValue: lambda { bank.doBank }
            }
            SelColumn {
                id: bank_type
                label: "type"
                extern: "/bank/types"
                whenValue: lambda { bank.doType }
            }
            SelColumn {
                id: bank_tag
                label: "tag"
                extern: "/bank/tags"
                whenValue: lambda { bank.doSearch }
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
                label: "overwrite"
                whenValue: lambda { bank.doSavePart() }
            }
            TriggerButton {
                label: "rescan"
                whenValue: lambda { bank.doRescan() }
            }
            function setrw(x)
            {
                if(x == 0)
                    bank.mode = :read
                    children[0].value = true
                    children[1].value = false
                else
                    bank.mode = :write
                    children[0].value = false
                    children[1].value = true
                end
                bank_type.clear
                children[0].damage_self
                children[1].damage_self
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
