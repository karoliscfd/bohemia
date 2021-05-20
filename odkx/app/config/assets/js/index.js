'use strict';

(function () {
  var launchHhSearch = function (hasPaintedId) {
    if (hasPaintedId) {
      localStorage.setItem('hasPaintedId', 'true');
      localStorage.setItem('modalSelectedPaintedId', 'true');
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

    // Button to change country
    document.getElementById('changeFwCountry').addEventListener('click', function () {
      odkTables.launchHTML(
        null,
        'config/assets/enterCountry.html'
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

    document.getElementById('entoForm').addEventListener('click', function () {
      odkTables.launchHTML(
        null,
        'config/assets/entoForms.html'
      );
    });

    document.getElementById('incompleteHh').addEventListener('click', function () {
      odkTables.openTableToListView(
        null,
        'census',
        null,
        null,
        'config/tables/census/html/census_incomplete.html'
      );
    });

    localStorage.removeItem('bohemiaHhSearch');
    localStorage.removeItem('bohemiaMemberSearch');
    localStorage.removeItem('hasPaintedId');
    localStorage.removeItem('modalSelectedPaintedId');

    if (!!localStorage.getItem('FW_ID')) {
      document.getElementById('fwIdSpan').textContent = localStorage.getItem('FW_ID');
      var requiresFwIdElem = document.querySelectorAll('.requires-fw-id');
      for (var i = 0; i < requiresFwIdElem.length; i++) {
        requiresFwIdElem[i].classList.remove('d-none', 'invisible');
      }

      if (localStorage.getItem('FW_ID') === '9999') {
        var entoItems = document.querySelectorAll('.requires-ento-fw-id');
        for (var i = 0; i < entoItems.length; i++) {
          entoItems[i].classList.remove('d-none', 'invisible');
        }
      }

      document.getElementById('fwCountrySpan').textContent = bohemiaUtil.getFwLocation();
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
