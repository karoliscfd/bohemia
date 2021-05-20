'use strict';

(function () {
  document.addEventListener('DOMContentLoaded', function () {
    // document.getElementById('enterFwIdForm').addEventListener('submit', function (evt) {
    //   evt.preventDefault();
    //
    //   localStorage.setItem('FW_ID', document.getElementById('fwIdInput').value.trim());
    //   odkCommon.closeWindow(-1);
    // });

    document.getElementById('changeCountrySelect').value = bohemiaUtil.getFwLocation();
    document.getElementById('changeCountryForm').addEventListener('submit', function (evt) {
      evt.preventDefault();
      bohemiaUtil.setFwLocation(document.getElementById('changeCountrySelect').value);
      odkCommon.closeWindow(-1);
    });

    localizeUtil.localizePage();

    document
      .getElementById('wrapper')
      .classList
      .remove('d-none');
  });
})();
