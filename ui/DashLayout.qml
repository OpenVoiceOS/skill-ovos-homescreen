import QtQuick 2.9
import QtQuick.Layouts 1.12

Item {
    id: layout

    property int spacing: 0
    property int orientation: Qt.Horizontal
    property int currentIndex: 0
    property int count: children.length - 1

    property var panes: []
    property var number_of_panes: 0
    property var active_pane
    property var paneIndex: 0
    property var underUpdate: false
    property var contentWidth: 0

    Connections {
        target: tileRepeater
        onDelegateItemChanged: {
            updateLayout(item)
            console.log("Got A New Item")
            console.log(layout.parent.width)
        }
    }

    function updateContentWidth() {
        contentWidth = 0
        for (var i = 0; i < panes.length; i++) {
            contentWidth += panes[i].width
        }
    }

    function updateLayout(item) {
         var itemString = String(item)
         if (itemString.indexOf("QQuickRepeater") == -1) {
             generate_pane(item)
         }
    }

    function calculate_width_and_height_of_item(pane, item) {
        var paneWidth = pane.width
        var paneHeight = pane.height
        var itemWandH = calculate_cells_required_by_item(paneWidth, paneHeight, item)
        var fetchedWidth = itemWandH.itemWidth
        var fetchedHeight = itemWandH.itemHeight

        return {
            itemWidth: fetchedWidth,
            itemHeight: fetchedHeight
        }
    }

    function calculate_cells_required_by_item(paneWidth, paneHeight, item) {
        var cellWidth = paneWidth / 2
        var cellHeight = paneHeight / 4
        var cellsXAvailable = paneWidth / cellWidth
        var cellsYAvailable = paneHeight / cellHeight

        var calculatedItemWidth
        var calculatedItemHeight
        var xRequired
        var yRequired
        var calculatedPreferredCellWidth = item.contentItem.preferredCellWidth
        if (calculatedPreferredCellWidth > 4) {
            calculatedPreferredCellWidth = 4
        } else if (calculatedPreferredCellWidth % 2 == 0) {
            calculatedPreferredCellWidth = calculatedPreferredCellWidth
        } else {
            calculatedPreferredCellWidth = calculatedPreferredCellWidth + 1
        }

        var calculatedPreferredCellHeight = item.contentItem.preferredCellHeight
        if (calculatedPreferredCellHeight > 8) {
            calculatedPreferredCellHeight = 8
        } else if (calculatedPreferredCellHeight % 2 == 0) {
            calculatedPreferredCellHeight = calculatedPreferredCellHeight
        } else {
            calculatedPreferredCellHeight = calculatedPreferredCellHeight + 1
        }

        if (calculatedPreferredCellHeight >= 4) {
            calculatedPreferredCellWidth = 4
        }

        if (calculatedPreferredCellWidth == 2) {
            calculatedItemWidth = cellWidth
            xRequired = calculatedPreferredCellWidth
        }

        if (calculatedPreferredCellWidth == 4) {
            calculatedItemWidth = cellWidth * 2
            xRequired = calculatedPreferredCellWidth
        }

        if (calculatedPreferredCellWidth > 4) {
            calculatedItemWidth = cellWidth * 2
            xRequired = calculatedPreferredCellWidth
        }

        if (calculatedPreferredCellHeight == 2) {
            calculatedItemHeight = cellHeight
            yRequired = calculatedPreferredCellHeight
        }

        if (calculatedPreferredCellHeight == 4) {
            calculatedItemHeight = cellHeight * 2
            yRequired = calculatedPreferredCellHeight + 4
        }

        if (calculatedPreferredCellHeight == 6) {
            calculatedItemHeight = cellHeight * 3
            yRequired = calculatedPreferredCellHeight + 6
        }

        if (calculatedPreferredCellHeight == 8) {
            calculatedItemHeight = cellHeight * 4
            yRequired = calculatedPreferredCellHeight + 8
        }

        if (calculatedPreferredCellHeight > 8) {
            calculatedItemHeight = cellHeight * 4
            yRequired = calculatedPreferredCellHeight + 8
        }

        return {
            cellsXRequired: xRequired,
            cellsYRequired: yRequired,
            itemWidth: calculatedItemWidth,
            itemHeight: calculatedItemHeight
        }
    }

    function calculate_available_cells_in_pane(pane, paneWidth, paneHeight) {
        var cellsXAvailable = pane.cellsXAvailable
        var cellsYAvailable = pane.cellsYAvailable

        return {
            cellsXAvailable: cellsXAvailable,
            cellsYAvailable: cellsYAvailable
        }
    }

    function add_item_to_pane(pane, item) {
        var paneWidth = pane.width
        var paneHeight = pane.height
        var paneNumber = pane.number
        var cellWidth = paneWidth / 2
        var cellHeight = paneHeight / 4

        var cellsXAvailable = pane.cellsXAvailable
        var cellsYAvailable = pane.cellsYAvailable

        var cellsXRequired = calculate_cells_required_by_item(paneWidth, paneHeight, item).cellsXRequired
        var cellsYRequired = calculate_cells_required_by_item(paneWidth, paneHeight, item).cellsYRequired
        var itemWandH = calculate_cells_required_by_item(paneWidth, paneHeight, item)

        var paneX

        if (pane.items.length < 1) {
            if(paneNumber == 0) {
                paneX = 0
                item.x = 0
                item.y = 0
                item.width = itemWandH.itemWidth
                item.height = itemWandH.itemHeight
            } else if (paneNumber > 0) {
                paneX = pane.x
                item.x = pane.x
                item.y = 0
                item.width = itemWandH.itemWidth
                item.height = itemWandH.itemHeight
            }
        } else if(pane.items.length > 0) {
            if (cellsXAvailable >= cellsXRequired && cellsYAvailable >= cellsYRequired) {
                if (paneNumber == 0) {
                    paneX = pane.x
                    var lastItem = pane.items[pane.items.length - 1]
                    var lastItemX = lastItem.x
                    var lastItemY = lastItem.y
                    var lastItemWidth = lastItem.width
                    var lastItemHeight = lastItem.height
                    if (lastItemY == 0) {
                        if (lastItemX + lastItemWidth + itemWandH.itemWidth <= paneWidth) {
                            item.x = lastItemX + lastItemWidth
                            item.y = lastItemY
                            item.width = itemWandH.itemWidth
                            item.height = itemWandH.itemHeight
                        }
                        else if (lastItemX + lastItemWidth + itemWandH.itemWidth > paneWidth) {
                            if (lastItemY + lastItemHeight + itemWandH.itemHeight <= paneHeight) {
                                item.x = 0
                                item.y = lastItemY + lastItemHeight
                                item.width = itemWandH.itemWidth
                                item.height = itemWandH.itemHeight
                            } else {
                                var lastItemToTheRight = pane.items[pane.items.length - 2]
                                var lastItemToTheRightX = lastItemToTheRight.x
                                var lastItemToTheRightY = lastItemToTheRight.y
                                var lastItemToTheRightWidth = lastItemToTheRight.width
                                var lastItemToTheRightHeight = lastItemToTheRight.height
                                if (lastItemToTheRightX + lastItemToTheRightWidth + itemWandH.itemWidth <= paneWidth) {
                                    item.x = lastItemToTheRightX + lastItemToTheRightWidth
                                    item.y = lastItemToTheRightY
                                    item.width = itemWandH.itemWidth
                                    item.height = itemWandH.itemHeight
                                }
                            }
                        }
                    } else if (lastItemY > 0) {
                        if (lastItemX + lastItemWidth + itemWandH.itemWidth <= paneWidth) {
                            item.x = lastItemX + lastItemWidth
                            item.y = lastItemY
                            item.width = itemWandH.itemWidth
                            item.height = itemWandH.itemHeight
                        }
                        else if (lastItemX + lastItemWidth + itemWandH.itemWidth > paneWidth) {
                            if (lastItemY + lastItemHeight + itemWandH.itemHeight <= paneHeight) {
                                item.x = 0
                                item.y = lastItemY + lastItemHeight
                                item.width = itemWandH.itemWidth
                                item.height = itemWandH.itemHeight
                            } else {
                                var lastItemToTheRight = pane.items[pane.items.length - 2]
                                var lastItemToTheRightX = lastItemToTheRight.x
                                var lastItemToTheRightY = lastItemToTheRight.y
                                var lastItemToTheRightWidth = lastItemToTheRight.width
                                var lastItemToTheRightHeight = lastItemToTheRight.height
                                if (lastItemToTheRightX + lastItemToTheRightWidth + itemWandH.itemWidth <= paneWidth) {
                                    item.x = lastItemToTheRightX + lastItemToTheRightWidth
                                    item.y = lastItemToTheRightY
                                    item.width = itemWandH.itemWidth
                                    item.height = itemWandH.itemHeight
                                }
                            }
                        }
                    }

                }  else if (paneNumber >= 1) {
                    paneX = pane.x
                    var lastItem = pane.items[pane.items.length - 1]
                    var lastItemX = lastItem.x
                    var lastItemY = lastItem.y
                    var lastItemWidth = lastItem.width
                    var lastItemHeight = lastItem.height
                    var paneXOffset = lastItemX - paneX
                    if (lastItemY == 0) {
                        if (paneXOffset + lastItemWidth + itemWandH.itemWidth <= paneWidth) {
                            item.x = lastItemX + lastItemWidth
                            item.y = lastItemY
                            item.width = itemWandH.itemWidth
                            item.height = itemWandH.itemHeight
                        }
                        else if (paneXOffset + lastItemWidth + itemWandH.itemWidth > paneWidth) {
                            if (lastItemY + lastItemHeight + itemWandH.itemHeight <= paneHeight) {
                                item.x = paneX
                                item.y = lastItemY + lastItemHeight
                                item.width = itemWandH.itemWidth
                                item.height = itemWandH.itemHeight
                            } else {
                                var lastItemToTheRight = pane.items[pane.items.length - 2]
                                var lastItemToTheRightX = lastItemToTheRight.x
                                var lastItemToTheRightY = lastItemToTheRight.y
                                var lastItemToTheRightWidth = lastItemToTheRight.width
                                var lastItemToTheRightHeight = lastItemToTheRight.height
                                if (lastItemToTheRightX + lastItemToTheRightWidth + itemWandH.itemWidth <= paneWidth) {
                                    item.x = lastItemToTheRightX + lastItemToTheRightWidth
                                    item.y = lastItemToTheRightY
                                    item.width = itemWandH.itemWidth
                                    item.height = itemWandH.itemHeight
                                }
                            }
                        }
                    } else if (lastItemY > 0) {
                        if (paneXOffset + lastItemWidth + itemWandH.itemWidth <= paneWidth) {
                            item.x = lastItemX + lastItemWidth
                            item.y = lastItemY
                            item.width = itemWandH.itemWidth
                            item.height = itemWandH.itemHeight
                        }
                        else if (paneXOffset + lastItemWidth + itemWandH.itemWidth > paneWidth) {
                            if (lastItemY + lastItemHeight + itemWandH.itemHeight <= paneHeight) {
                                item.x = paneX
                                item.y = lastItemY + lastItemHeight
                                item.width = itemWandH.itemWidth
                                item.height = itemWandH.itemHeight
                            } else {
                                var lastItemToTheRight = pane.items[pane.items.length - 2]
                                var lastItemToTheRightX = lastItemToTheRight.x
                                var lastItemToTheRightY = lastItemToTheRight.y
                                var lastItemToTheRightWidth = lastItemToTheRight.width
                                var lastItemToTheRightHeight = lastItemToTheRight.height
                                if (lastItemToTheRightX + lastItemToTheRightWidth + itemWandH.itemWidth <= paneWidth) {
                                    item.x = lastItemToTheRightX + lastItemToTheRightWidth
                                    item.y = lastItemToTheRightY
                                    item.width = itemWandH.itemWidth
                                    item.height = itemWandH.itemHeight
                                }
                            }
                        }
                    }
                }
            }
        }

        pane.cellsXAvailable = cellsXAvailable - cellsXRequired
        pane.cellsYAvailable = cellsYAvailable - cellsYRequired
        pane.items.push(item)
        updateContentWidth()
    }

    function generate_pane(item){
        var paneWidth = gridBoxRoot.width / 2
        var paneHeight
        if (orientation == Qt.Horizontal) {
            paneHeight = layout.height
        } else {
            paneHeight = paneWidth
        }

        var pane

        if (panes.length == 0) {
            pane = panes[paneIndex]
        } else {
            pane = active_pane
        }

        if (panes.length == 0) {
            pane = {
                name: "Pane 1",
                number: 0,
                x: 0,
                y: 0,
                width: paneWidth,
                height: paneHeight,
                items: [],
                cellsXAvailable: 16,
                cellsYAvailable: 16,
                full: false
            }
            panes.push(pane)
            number_of_panes = 1
            active_pane = pane
            add_item_to_pane(pane, item)
        } else {
            var cellsXAvailable = calculate_available_cells_in_pane(pane, paneWidth, paneHeight).cellsXAvailable
            var cellsYAvailable = calculate_available_cells_in_pane(pane, paneWidth, paneHeight).cellsYAvailable
            var cellsXRequired = calculate_cells_required_by_item(paneWidth, paneHeight, item).cellsXRequired
            var cellsYRequired = calculate_cells_required_by_item(paneWidth, paneHeight, item).cellsYRequired

            if (cellsXAvailable < cellsXRequired || cellsYAvailable < cellsYRequired) {
                pane.full = true
                paneIndex = panes.length
                pane = {
                    name: "Pane " + (paneIndex + 1),
                    number: paneIndex,
                    x: pane.x + pane.width,
                    y: 0,
                    width: paneWidth,
                    height: paneHeight,
                    items: [],
                    cellsXAvailable: 16,
                    cellsYAvailable: 16,
                    full: false
                }
                panes.push(pane)
                number_of_panes = panes.length
                paneIndex = panes.length

                active_pane = pane
                add_item_to_pane(pane, item)
            } else {
                add_item_to_pane(pane, item)
            }
        }
    }
}

