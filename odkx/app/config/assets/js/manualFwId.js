'use strict';

(function () {
  document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('fwIdConstraintAlert').style.display = "hide";

    document.getElementById('manualFwIdForm').addEventListener('submit', function (evt) {
      evt.preventDefault();

      var fwIdVal = document.getElementById('fwIdInput').value.trim()
      if (!bohemiaUtil.isValidFwId(fwIdVal)) {
        document.getElementById('fwIdInput').value = null;
        document.getElementById('fwIdConstraintAlert').style.display = "block";
        return;
      }
      document.getElementById('fwIdConstraintAlert').style.display = "hide";

      localStorage.setItem('FW_ID', fwIdVal);
      bohemiaUtil.updateLocationFromFwId(fwIdVal);
      odkCommon.closeWindow(-1, {
        fwId: fwIdVal,
      });
    });

    if (!!odkCommon.getSessionVariable('fwIdInput')) {
      document.getElementById('fwIdInput').value = odkCommon.getSessionVariable('fwIdInput');
    }

    localizeUtil.localizePage();

    document
      .getElementById('wrapper')
      .classList
      .remove('d-none');
  });
})();
