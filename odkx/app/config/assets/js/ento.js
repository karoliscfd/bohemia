'use strict';

(function () {
  document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('entoHhForm').addEventListener('click', function () {
      odkTables.addRowWithSurvey(
        null,
        'ento_household',
        'ento_household',
        null,
        null
      );
    });

    document.getElementById('entoHhFollowupForm').addEventListener('click', function () {
      odkTables.addRowWithSurvey(
        null,
        'ento_household',
        'ento_household_followup',
        null,
        null
      );
    });

    document.getElementById('entoLivestockForm').addEventListener('click', function () {
      odkTables.addRowWithSurvey(
        null,
        'ento_livestock',
        'ento_livestock',
        null,
        null
      );
    });

    localizeUtil.localizePage();

    document.getElementById('wrapper').classList.remove('d-none');
  });
})();
