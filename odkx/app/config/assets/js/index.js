'use strict';

(function () {
  var launchHhSearch = function (hasPaintedId) {
    if (hasPaintedId) {
      localStorage.setItem('hasPaintedId', 'true');
    }
    odkTables.openTableToListView(null, 'census');
  }

  document.addEventListener('DOMContentLoaded', function () {
    // Button set the fw id
    document.getElementById('enterFwId').addEventListener('click', function () {
      odkTables.launchHTML(
        null,
        'config/assets/enterFwId.html'
      );
    });

    // Button to sync
    document.getElementById('syncHhButton').addEventListener('click', function () {
      odkCommon.doAction(
        null,
        'org.opendatakit.services.sync.actions.activities.SyncActivity',
        {
          componentPackage: 'org.opendatakit.services',
          componentActivity: 'org.opendatakit.services.sync.actions.activities.SyncActivity'
        }
      );
    });

    localStorage.removeItem('bohemiaHhSearch');
    localStorage.removeItem('bohemiaMemberSearch');
    localStorage.removeItem('hasPaintedId');

    if (!!localStorage.getItem('FW_ID')) {
      document.getElementById('fwIdSpan').textContent = localStorage.getItem('FW_ID');
      var requiresFwIdElem = document.querySelectorAll('.requires-fw-id');
      for (var i = 0; i < requiresFwIdElem.length; i++) {
        requiresFwIdElem[i].classList.remove('d-none', 'invisible');
      }
    }

    document.getElementById('paintedIdModalYes').addEventListener('click', function () {
      launchHhSearch(true);
    });

    document.getElementById('paintedIdModalNo').addEventListener('click', function () {
      launchHhSearch(false);
    });

    localizeUtil.localizePage();

    document.getElementById('wrapper').classList.remove('d-none');
  });
})();
