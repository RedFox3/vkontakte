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

import QtQuick 2.9
import Ubuntu.Components 1.3
import QtQuick.Window 2.2
import Morph.Web 0.1
import QtWebEngine 1.10
import Qt.labs.settings 1.0
import QtSystemInfo 5.5
import QtQuick.Controls 2.2
import "UCSComponents"

ApplicationWindow {
  id: window
  color: theme.palette.normal.background

  ScreenSaver {
    id: screenSaver
    screenSaverEnabled: !Qt.application.active || !webView.recentlyAudible
  }

  objectName: 'mainView'
  // applicationName: 'vkontakte.redfox3'
  // automaticOrientation: true

  // width: units.gu(45)
  // height: units.gu(75)

  property bool loaded: false

  WebView {
    id: webView
    anchors.fill: parent

    // Alternative for anchorToKeyboard: true
    anchors.bottomMargin: Qt.inputMethod.visible ?
      Qt.inputMethod.keyboardRectangle.height / (units.gridUnit / 8) : 0
    Behavior on anchors.bottomMargin {
      NumberAnimation {
        duration: 175
        easing.type: Easing.OutQuad
      }
    }

    settings.fullScreenSupportEnabled: true
    property var currentWebView: webView
    settings.pluginsEnabled: true

    onFullScreenRequested: function(request) {
      nav.visible = !nav.visible

      request.accept();
    }

    profile: WebEngineProfile {
      id: webContext
      persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
      property alias dataPath: webContext.persistentStoragePath

      dataPath: dataLocation
      offTheRecord: false

      httpUserAgent: "Mozilla/5.0 (Linux; Android 10; Pixel 4 XL) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.79 Mobile Safari/537.36"

      // TODO: Replace with css injection that fully remove BottomMenu
      /*
      userScripts: [
        WebEngineScript {
          id: jsInjection
          injectionPoint: WebEngineScript.DocumentReady
          sourceUrl: Qt.resolvedUrl('UbuntuTheme.js')
          worldId: WebEngineScript.UserWorld
        }
      ]
      */
    }

    url: "https://www.vk.com"

    onLoadingChanged: {
      if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
        window.loaded = true
      }
    }

    // Handle click on links
    onNewViewRequested: function(request) {
      console.log(request.destination, request.requestedUrl)

      var url = request.requestedUrl.toString()
      // Handle redirection links
      if (url.startsWith('https://www.vk.com')) {
        // Get query params
        var reg = new RegExp('[?&]q=([^&#]*)', 'i');
        var param = reg.exec(url);
        if (param) {
          console.log("url to open:", decodeURIComponent(param[1]))
          Qt.openUrlExternally(decodeURIComponent(param[1]))
        } else {
          Qt.openUrlExternally(url)
        }
      } else {
        Qt.openUrlExternally(url)
      }
    }
  }

  RadialBottomEdge {
    id: nav
    visible: window.loaded

    actions: [
      RadialAction {
        id: reload
        iconName: "reload"
        onTriggered: {
          webView.reload()
        }
        text: qsTr("Reload")
      },

      RadialAction {
        id: forward
        enabled: webView.canGoForward
        iconName: "go-next"
        onTriggered: {
          webView.goForward()
        }
        text: qsTr("Forward")
      },

      RadialAction {
        id: menu
        iconName: "navigation-menu"
        onTriggered: {
          webView.url = 'https://m.vk.com/menu'
        }
        text: qsTr("Menu")
      },

      RadialAction {
        id: notifications
        iconName: "notification"
        onTriggered: {
          webView.url = 'https://m.vk.com/feed?section=notifications'
        }
        text: qsTr("Notifications")
      },

      RadialAction {
        id: mail
        iconName: "message"
        onTriggered: {
          webView.url = 'https://m.vk.com/mail'
        }
        text: qsTr("Mail")
      },

      RadialAction {
        id: recommended
        iconName: "find"
        onTriggered: {
          webView.url = 'https://m.vk.com/feed?section=recommended'
        }
        text: qsTr("Recommended")
      },

      RadialAction {
        id: feed
        iconName: "event"
        onTriggered: {
          webView.url = 'http://m.vk.com/feed'
        }
        text: qsTr("Feed")
      },

      RadialAction {
        id: back
        enabled: webView.canGoBack
        iconName: "go-previous"
        onTriggered: {
          webView.goBack()
        }
        text: qsTr("Back")
      }
    ]
  }

  Rectangle {
    id: splashScreen
    color: theme.palette.normal.background
    anchors.fill: parent

    ActivityIndicator {
      id: loadingFlag
      anchors.centerIn: parent

      running: splashScreen.visible
    }

    states: [
      State { when: !window.loaded;
        PropertyChanges { target: splashScreen; opacity: 1.0 }
      },
      State { when: window.loaded;
        PropertyChanges { target: splashScreen; opacity: 0.0 }
      }
    ]

    transitions: Transition {
      NumberAnimation { property: "opacity"; duration: 400 }
    }
  }

  Connections {
    target: Qt.inputMethod
    onVisibleChanged: nav.visible = !nav.visible
  }

  Connections {
    target: webview

    onIsFullScreenChanged: {
      console.log('onIsFullScreenChanged:')
      window.setFullscreen(webView.isFullScreen)
      if (webView.isFullScreen) {
        nav.state = "hidden"
      }
      else {
        nav.state = "shown"
      }
    }
  }

  Connections {
    target: UriHandler

    onOpened: {
      if (uris.length > 0) {
        console.log('Incoming call from UriHandler ' + uris[0]);
        webView.url = uris[0];
      }
    }
  }

  Component.onCompleted: {
    // Check if opened the app because we have an incoming call
    if (Qt.application.arguments && Qt.application.arguments.length > 0) {
      for (var i = 0; i < Qt.application.arguments.length; i++) {
        if (Qt.application.arguments[i].match(/^http/)) {
          console.log(' open link to:', Qt.application.arguments[i])
          webView.url = Qt.application.arguments[i];
        }
      }
    }
  }

  function setFullscreen(fullscreen) {
    if (fullscreen) {
      if (window.visibility != Window.FullScreen) {
        window.visibility = Window.FullScreen
      }
    } else {
      window.visibility = Window.Windowed
    }
  }
}
