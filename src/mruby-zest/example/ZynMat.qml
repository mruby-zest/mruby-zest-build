Widget {
    id: mat
    property Object valueRef: nil

    onExtern: {
    }



    ZynMatTable {
        extern: mat.extern
    }

    function layout(l, selfBox) {
        Draw::Layout::vfill(l, selfBox, children, [0.05,0.95], 0, 2)
    }
}
