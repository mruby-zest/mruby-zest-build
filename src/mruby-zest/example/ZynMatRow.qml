Widget {
    id: mat_row
    property Array weights: [0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10]
    property Int rownum: nil


    Knob{
        extern: mat_row.extern + "col1/"
        label: mat_row.label;
        layoutOpts: [:no_constraint]
    }
    
    Knob{
        extern: mat_row.extern + "col2/"
        label: mat_row.label;
        layoutOpts: [:no_constraint]
    }


    function class_name() { "matrow" }
    function layout(l, selfBox) {
        Draw::Layout::hfill(l, selfBox, children, mat_row.weights, 0, 3)
        puts "mat_row"
        puts selfBox
    }

    function onSetup(old=nil)
    {
        children.each do |ch|
            mat_row.extern()
        end
    }
}
