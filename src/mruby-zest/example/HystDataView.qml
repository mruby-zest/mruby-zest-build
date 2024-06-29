Widget {
    layer: 1
    property Array data: nil;
    property Bool  normal: false
    property Float pad:   1.0/32
    property Float fixedpad: 0
    property Bool under_highlight: false

    function class_name() { "HystDataView" }

    function draw(vg)
    {
        pad2 = (1-2*pad)
        box = Rect.new(w*pad  + fixedpad,   h*pad  + fixedpad,
                       w*pad2 - 2*fixedpad, h*pad2 - 2*fixedpad)

        Draw::WaveForm::plotHyst(vg, self.data, box, normal, 0, under_highlight) if not self.data.nil?

    }
}

