'use strict';

(function () {
  window.localizeUtil = {
    getLocale: function () {
      var cache = odkCommon.getSessionVariable('bohemiaLocale');
      if (!cache) {
        cache = odkCommon.getPreferredLocale();
        odkCommon.setSessionVariable('bohemiaLocale', cache);
      }

      return cache;
    },
    localizePage: function () {
      var locale = this.getLocale();

      var elemToLocalize = document.querySelectorAll('[data-localize]');
      for (var i = 0; i < elemToLocalize.length; i++) {
        var elem = elemToLocalize[i];
        var token = elem.dataset['localize'];
        elem.innerText = odkCommon.localizeText(locale, token) || token;
      }

      var placeholderToLocalize = document.querySelectorAll('[data-localize-placeholder]');
      for (var i = 0; i < placeholderToLocalize.length; i++) {
        var elem = placeholderToLocalize[i];
        var token = elem.dataset['localizePlaceholder'];
        elem.placeholder = odkCommon.localizeText(locale, token) || token;
      }
    }
  };
})();
