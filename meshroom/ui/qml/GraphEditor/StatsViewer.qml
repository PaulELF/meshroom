import QtQuick 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtCharts 2.2

Item {

    property url statsFilepath
    property int xScaleZoom: 0
    property int yScaleZoom: 0

    property var statsModel

    implicitHeight: content.height

    onStatsFilepathChanged: {
        loadJSON(statsFilepath, function (response) {
            statsModel = JSON.parse(response)
            trace()
        })
    }

    function clear() {
        chartCPU.removeAllSeries()
        //  chartRam.removeAllSeries()
        // chartSwapUsage.removeAllSeries()
        chartMemory.removeAllSeries()
    }

    function trace() {
        clear()
        traceCPU()
        traceRam()
        traceSwapUsage()
        traceMemory()
    }

    function traceSwapUsage() {
        var serie = chartMemory.createSeries(ChartView.SeriesTypeLine,
                                             "SwapUsage ", valueAxisX,
                                             valueAxisY)
        var model = statsModel['computer']['curves']['swapUsage']
        var pointCount = model.length
        for (var j = 0; j < pointCount; j++) {
            serie.append(j, model[j])
        }
    }

    function countCPU() {
        var a = statsModel['computer']['curves']
        var cpuCount = 0
        Object.keys(a).forEach(function (key) {
            if (key.startsWith("cpuUsage")) {
                cpuCount++
            }
        })
        return cpuCount
    }

    function traceCPU() {
        var a = statsModel['computer']['curves']
        var cpuCount = 0
        Object.keys(a).forEach(function (key) {
            if (key.startsWith("cpuUsage")) {
                cpuCount++
            }
        })

        for (var x = 0; x < cpuCount; x++) {
            var models = ['cpuUsage.' + x]
            for (var i = 0; i < models.length; i++) {
                var serie = chartCPU.createSeries(ChartView.SeriesTypeLine,
                                                  "cpu " + x, axisX, axisY)
                var model = statsModel['computer']['curves'][models[i]]
                var timeAxe = timeAxis()
                var pointCount = timeAxe.length
                //serie.color = Qt.rgba(Math.random(),Math.random(),Math.random(),1);
                for (var j = 0; j < pointCount; j++) {
                    var b = timeAxe[j]
                    serie.append(b, model[j])
                }
            }
        }
    }

    function traceRam() {
        var serie = chartMemory.createSeries(ChartView.SeriesTypeLine, "RAM ",
                                             valueAxisX, valueAxisY)
        var model = statsModel['computer']['curves']['ramUsage']
        var timeAxe = timeAxis()
        var pointCount = timeAxe.length
        for (var i = 0; i < pointCount; i++) {
            var a = timeAxe[i]
            serie.append(a, model[i])
        }
    }

    function traceMemory() {
        var serie = chartMemory.createSeries(ChartView.SeriesTypeLine,
                                             "memory ", valueAxisX, valueAxisY)
        var model = statsModel['process']['curves']['memory_percent']
        var timeAxe = timeAxis()
        var pointCount = timeAxe.length
        for (var i = 0; i < pointCount; i++) {
            var e = timeAxe[i]
            serie.append(e, model[i])
        }
    }

    function loadJSON(path, callback) {
        var xobj = new XMLHttpRequest()
        xobj.open('GET', path, true)
        xobj.onreadystatechange = function () {
            if (xobj.readyState == XMLHttpRequest.DONE && xobj.status === 200) {
                callback(xobj.responseText)
            }
        }
        xobj.send(null)
    }

    function timeAxis() {
        // var a = statsModel['times'][0]
        var times = []
        for (var i = 0; i < statsModel['times'].length; i++) {
            var time = statsModel['times'][i] - statsModel['times'][0]
            times.push(time / 60)
        }
        return times
    }
    function maxAxisX() {
        var times = []
        var length = 0
        for (var i = 0; i < statsModel['times'].length; i++) {
            var time = statsModel['times'][i] - statsModel['times'][0]
            times.push(time / 60)
            length++
        }
        return times[length - 1]
    }

    function allTime() {

        var timeOrigin = 0
        for (var i = 0; i < statsModel['times'].length; i++) {
            var time = statsModel['times'][i] - statsModel['times'][0]
            time = time / 60
            time = time.toFixed(4)
        }
        return time
    }

    ColumnLayout {
        id: content
        width: parent.width

        ColumnLayout {
            width: parent.width

            Text {
                Layout.margins: 10
                text: "temps totale : " + allTime() + " min"
                color: "white"
            }

            ChartView {
                id: chartMemory
                title: "Process Memory"
                property int seriesCount: 0
                legend.visible: false
                Layout.fillWidth: true
                Layout.minimumHeight: 350
                antialiasing: true
                theme: ChartView.ChartThemeDark

                onSeriesAdded: seriesCount++
                onSeriesRemoved: seriesCount--

                ValueAxis {
                    id: valueAxisX
                    min: 0
                    max: maxAxisX()
                }
                ValueAxis {
                    id: valueAxisY
                    min: 0
                    max: 100
                }
                Rectangle {
                    id: zoom
                    border.color: "steelblue"
                    border.width: 1
                    color: "steelblue"
                    opacity: 0.3
                    visible: false
                    transform: Scale {
                        origin.x: 0
                        origin.y: 0
                        xScale: xScaleZoom
                        yScale: yScaleZoom
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: {
                        logScrollView.enabled = false
                        zoom.x = mouseX
                        zoom.y = mouseY
                        zoom.visible = true
                    }

                    onMouseXChanged: {
                        if (mouseX - zoom.x >= 0) {
                            xScaleZoom = 1
                            zoom.width = mouseX - zoom.x
                        } else {
                            xScaleZoom = -1
                            zoom.width = zoom.x - mouseX
                        }
                    }
                    onMouseYChanged: {
                        if (mouseY - zoom.y >= 0) {
                            yScaleZoom = 1
                            zoom.height = mouseY - zoom.y
                        } else {
                            yScaleZoom = -1
                            zoom.height = zoom.y - mouseY
                        }
                    }
                    onReleased: {
                        logScrollView.enabled = true
                        var x = (mouseX >= zoom.x) ? zoom.x : mouseX
                        var y = (mouseY >= zoom.y) ? zoom.y : mouseY
                        chartMemory.zoomIn(Qt.rect(x, y, zoom.width,
                                                   zoom.height))
                        zoom.visible = false
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: chartMemory.seriesCount
                    Button {
                        id: buttonRAM
                        checkable: true
                        property var series: chartMemory.series(index)
                        text: series.name
                        checked: series.visible
                        onToggled: series.visible = checked
                        Rectangle {
                            x: 1
                            y: 6
                            height: 11
                            width: 11
                            color: buttonRAM.series.color
                        }
                    }
                }
            }

            Button {
                Layout.margins: 8
                text: "reset"
                onClicked: {
                    chartMemory.zoomReset()
                    //console.log(chartRam.visible)
                }
            }

            ChartView {
                id: chartCPU
                property int seriesCount: 0
                title: "CPU"
                legend.visible: false
                Layout.fillWidth: true
                Layout.minimumHeight: 350
                antialiasing: true
                theme: ChartView.ChartThemeDark

                onSeriesAdded: seriesCount++
                onSeriesRemoved: seriesCount--

                ValueAxis {
                    id: axisX
                    min: 0
                    max: maxAxisX()
                }
                ValueAxis {
                    id: axisY
                    min: 0
                    max: 100
                }
                Rectangle {
                    id: recZoom
                    border.color: "steelblue"
                    border.width: 1
                    color: "steelblue"
                    opacity: 0.3
                    visible: false
                    transform: Scale {
                        origin.x: 0
                        origin.y: 0
                        xScale: xScaleZoom
                        yScale: yScaleZoom
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: {
                        logScrollView.enabled = false
                        recZoom.x = mouseX
                        recZoom.y = mouseY
                        recZoom.visible = true
                    }

                    onMouseXChanged: {
                        if (mouseX - recZoom.x >= 0) {
                            xScaleZoom = 1
                            recZoom.width = mouseX - recZoom.x
                        } else {
                            xScaleZoom = -1
                            recZoom.width = recZoom.x - mouseX
                        }
                    }
                    onMouseYChanged: {
                        if (mouseY - recZoom.y >= 0) {
                            yScaleZoom = 1
                            recZoom.height = mouseY - recZoom.y
                        } else {
                            yScaleZoom = -1
                            recZoom.height = recZoom.y - mouseY
                        }
                    }
                    onReleased: {
                        logScrollView.enabled = true
                        var x = (mouseX >= recZoom.x) ? recZoom.x : mouseX
                        var y = (mouseY >= recZoom.y) ? recZoom.y : mouseY
                        chartCPU.zoomIn(Qt.rect(x, y, recZoom.width,
                                                recZoom.height))
                        recZoom.visible = false
                    }
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: chartCPU.seriesCount
                    Button {
                        id: buttonCPU
                        property var series: chartCPU.series(index)
                        checkable: true
                        height: 24
                        width: 60
                        text: series.name
                        onToggled: buttonCPU.series.visible = !checked
                        Rectangle {
                            x: 1
                            y: 6
                            height: 11
                            width: 11
                            color: buttonCPU.series.color
                        }
                    }
                }
            }
        }
        Button {
            Layout.margins: 8
            text: "reset"
            onClicked: {
                chartCPU.zoomReset()
            }
        }
    }
}
