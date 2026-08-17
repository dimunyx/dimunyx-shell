pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Item {
  id: root
  property string locale: "en_US"
  property var translations: ({})
  property bool loaded: false
  signal translationsLoaded()
  FileView {
    id: localeLoader
    path: Qt.resolvedUrl("../i18n/" + root.locale + ".json")
    printErrors: true
    onLoaded: {
      try {
        root.translations = JSON.parse(text())
        console.log("Translation: loaded locale", root.locale)
      } catch (e) {
        root.translations = {}
        console.log("Translation: parse error for", root.locale)
      }
      root.loaded = true
      root.revision++
      root.translationsLoaded()
    }
    onLoadFailed: function(err) {
      console.log("Translation: load failed for", root.locale, err)
      root.translations = {}
      root.loaded = true
      root.revision++
      root.translationsLoaded()
    }
  }
  property int revision: 0
  function tr(key) {
    var r = root.revision
    if (root.translations[key] !== undefined) return root.translations[key]
    return "{" + key + "}"
  }
  function trf(key) {
    var args = Array.prototype.slice.call(arguments, 1)
    var val = root.tr(key)
    for (var i = 0; i < args.length; i++) {
      val = val.replace("{" + i + "}", args[i])
    }
    return val
  }
}
