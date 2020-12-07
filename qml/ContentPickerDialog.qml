/*
 * Copyright (C) 2020  RedFox3
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * vkontakte is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3 as Popups
import Ubuntu.Content 1.3
import "MimeTypeMapper.js" as MimeTypeMapper
import "."

Popups.PopupBase {
  id: picker
  objectName: "contentPickerDialog"

  // Set the parent at construction time, instead of letting show()
  // set it later on, which for some reason results in the size of
  // the dialog not being updated.
  parent: QuickUtils.rootItem(this)

  property var activeTransfer
  property bool allowMultipleFiles

  signal accept(var files)
  signal reject()

  onAccept: hide()
  onReject: hide()

  Rectangle {
    anchors.fill: parent

    ContentTransferHint {
      anchors.fill: parent
      activeTransfer: picker.activeTransfer
    }

    ContentPeerPicker {
      id: peerPicker
      anchors.fill: parent
      visible: true
      contentType: ContentType.All
      handler: ContentHandler.Source

      onPeerSelected: {
        if (allowMultipleFiles) {
          peer.selectionType = ContentTransfer.Multiple
        } else {
          peer.selectionType = ContentTransfer.Single
        }
        picker.activeTransfer = peer.request()
        stateChangeConnection.target = picker.activeTransfer
      }

      onCancelPressed: {
        reject()
      }
    }
  }

  Connections {
    id: stateChangeConnection
    target: null
    onStateChanged: {
      if (picker.activeTransfer.state === ContentTransfer.Charged) {
        var selectedItems = []
        for(var i in picker.activeTransfer.items) {
          // ContentTransfer.Single seems not to be handled properly, e.g. selected items with file manager
          // -> only select the first item
          if ((i > 0) && ! allowMultipleFiles) {
            break;
          }

          selectedItems.push(String(picker.activeTransfer.items[i].url).replace("file://", ""))
        }
        accept(selectedItems)
      }
    }
  }

  Component.onCompleted: {
    if(acceptTypes.length === 1) {
      var contentType = MimeTypeMapper.mimeTypeToContentType(acceptTypes[0])
      if(contentType == ContentType.Unknown) {
        // If we don't recognise the type, allow uploads from any app
        contentType = ContentType.All
      }
      peerPicker.contentType = contentType
    } else {
      peerPicker.contentType = ContentType.All
    }
    show()
  }
}
