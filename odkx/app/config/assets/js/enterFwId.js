'use strict';

(function () {
  var doActionCallback = function () {
    if (document.visibilityState !== 'visible') {
      return;
    }

    var action = odkCommon.viewFirstQueuedAction();
    if (action === undefined || action === null) {
      return;
    }

    odkCommon.removeFirstQueuedAction();

    if (action.jsonValue.status !== -1) {
      return;
    }

    var fwId = null;
    if (action.jsonValue.result.SCAN_RESULT) {
      fwId = action.jsonValue.result.SCAN_RESULT;
    } else if (action.jsonValue.result.fwId) {
      fwId = action.jsonValue.result.fwId;
    }

    document.getElementById('fwIdInput').value = fwId;
    odkCommon.setSessionVariable('fwIdInput', fwId);
  }

  document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('enterFwIdForm').addEventListener('submit', function (evt) {
      evt.preventDefault();

      localStorage.setItem('FW_ID', document.getElementById('fwIdInput').value.trim());
      odkCommon.closeWindow(-1);
    });

    document.getElementById('manualFwIdEntry').addEventListener('click', function () {
      odkTables.launchHTML(
        {fwId: null},
        'config/assets/manualFwId.html'
      );
    });

    document.getElementById('enterFwIdScan').addEventListener('click', function () {
      odkCommon.doAction(
        {},
        'com.google.zxing.client.android.SCAN',
        null
      );
    });

    if (!!odkCommon.getSessionVariable('fwIdInput')) {
      document.getElementById('fwIdInput').value = odkCommon.getSessionVariable('fwIdInput');
    }

    localizeUtil.localizePage();

    document
      .getElementById('wrapper')
      .classList
      .remove('d-none');

    odkCommon.registerListener(doActionCallback);
    doActionCallback();
  });
})();
