import QtQuick

Canvas {
    id: root

    property int cornerSize: 18
    property string corner: "topLeft"
    property color fillColor: "#000000"

    width: cornerSize
    height: cornerSize

    antialiasing: true

    onCornerSizeChanged: requestPaint()
    onCornerChanged: requestPaint()
    onFillColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        const size = root.cornerSize

        let centerX = size
        let centerY = size

        if (root.corner === "topRight") {
            centerX = 0
            centerY = size
        } else if (root.corner === "bottomLeft") {
            centerX = size
            centerY = 0
        } else if (root.corner === "bottomRight") {
            centerX = 0
            centerY = 0
        }

        ctx.clearRect(0, 0, width, height)
        ctx.globalCompositeOperation = "source-over"
        ctx.fillStyle = root.fillColor
        ctx.fillRect(0, 0, width, height)

        ctx.globalCompositeOperation = "destination-out"
        ctx.beginPath()
        ctx.arc(centerX, centerY, size, 0, Math.PI * 2)
        ctx.fill()
        ctx.globalCompositeOperation = "source-over"
    }
}
