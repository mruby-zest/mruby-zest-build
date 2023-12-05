Widget {
    id: mat_item
    property Array weights: [0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10]


    Knob{
        extern: mat_item.extern + "Penabled"
        label: mat_item.label;
        layoutOpts: [:no_constraint]
    }


    function class_name() { "matrow" }
    function layout(l, selfBox) {
        Draw::Layout::hfill(l, selfBox, children, mat_item.weights, 0, 3)
    }

    function onSetup(old=nil)
    {
        children.each do |ch|
            ch.extern()
        end
    }
}
