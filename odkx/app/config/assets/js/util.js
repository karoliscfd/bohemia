'use strict';

(function () {
  window.bohemiaUtil = {
    TAZ: 'TAZ',
    MOZ: 'MOZ',
    LOC_KEY: 'FW_LOC',

    fwIdToLocation: function (fwId) {
      fwId = Number(fwId);
      return ((fwId > 300 && fwId < 600) || (fwId > 1300 && fwId < 1600)) ? this.MOZ : this.TAZ;
    },
    updateLocationFromFwId: function (fwId) {
      var fwLocation = this.fwIdToLocation(fwId);
      localStorage.setItem(this.LOC_KEY, fwLocation);

      return fwLocation;
    },
    getFwLocation: function () {
      return localStorage.getItem(this.LOC_KEY) || this.updateLocationFromFwId(localStorage.getItem('FW_ID'));
    },
    setFwLocation: function (fwLocation) {
      localStorage.setItem(this.LOC_KEY, fwLocation);
    }
  };
})();
