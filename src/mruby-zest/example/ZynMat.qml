Widget {
    id: mat
    property Object valueRef: nil
    h: 400
    w: 800

    onExtern: {
    }



    ZynMatTable {
        extern: mat.extern
        h: 300
        w: 500
    }

    function layout(l, selfBox) {
        Draw::Layout::vfill(l, selfBox, children, [1.0])
    }
}
