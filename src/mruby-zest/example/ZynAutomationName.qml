Widget {
    Text {
        id: textrender
        label: ""
        height: 1.0
    }

    function update_path(path)
    {
        textrender.label = path if path.length > 0
        textrender.label = "Unconnected" if path.length <= 0
        damage_self
    }
}
