'use strict';

(function () {
  var MAP_ACTION = 'MAP';
  var NAV_ACTION = 'NAV';
  var SURVEY_ACTION = 'SURVEY';
  var ACTION_KEY = 'CENSUS_LIST_ACTION';

  var platInfo = JSON.parse(odkCommon.getPlatformInfo());

  var callbackFailure = function (error) {
    localStorage.removeItem(searchParam.hhId.storageKey);
    localStorage.removeItem(searchParam.member.storageKey);
    searchParam.hhId.footer.classList.add('d-none');
    searchParam.member.footer.classList.add('d-none');

    $('#hhRosterModal').modal('hide');
    $('#hhDeleteModal').modal('hide');

    if (!!window.reuseHhId) {
      clearTimeout(window.reuseHhId);
    }

    console.error(error);
    alert(error);
  };

  var querySuccessCallback = function (type) {
    return function (result) {
      // clear prev search result
      searchParam[type].listContainer.innerText = '';

      // this should always show
      searchParam[type].footer.classList.remove('d-none');

      var resultCount = result.getCount();
      if (resultCount === 0) {
        searchParam[type].noResult.classList.remove('d-none');
        searchParam[type].notFound.classList.add('d-none');
        return;
      } else {
        searchParam[type].noResult.classList.add('d-none');
        searchParam[type].notFound.classList.remove('d-none');
      }

      // re-enable map after a successful search
      searchParam[type].mapBtn.classList.remove('d-none');

      var template = document.getElementById('hhListTemplate');
      for (var i = 0; i < resultCount; i++) {
        var newListItem = document.importNode(template.content, true);

        var rowId = result.getRowId(i);
        var hhId = result.getData(i, 'hh_id');
        var hhMinicenced = result.getData(i, 'hh_minicenced');

        var fields = newListItem.querySelectorAll('.hh-list-field');
        fields[0].textContent = hhId;
        fields[1].textContent = result.getData(i, 'hh_name') + ' ' + result.getData(i, 'hh_surname');

        var buttons = newListItem.querySelectorAll('button');
        buttons[0].dataset['rowId'] = rowId;
        buttons[0].dataset['hhId'] = hhId;
        buttons[0].dataset['hhMinicenced'] = hhMinicenced;
        buttons[0].addEventListener('click', hhOnClick);

        buttons[1].dataset['rowId'] = rowId;
        buttons[1].dataset['hhId'] = hhId;
        buttons[1].dataset['hhMinicenced'] = hhMinicenced;
        buttons[1].dataset['geoRowId'] = result.getData(i, 'geo_rowId');
        buttons[1].addEventListener('click', searchParam[type].navOnClick);

        searchParam[type].listContainer.appendChild(newListItem);
      }
    }
  };

  var openHh = function (hhRowId, hhId, hhMinicenced) {
    // disable the continue button before the new roster is populated
    var proceedBtn = document.getElementById('hhRosterModalProceed');
    proceedBtn.removeEventListener('click', hhRosterConfirm);
    proceedBtn.dataset['rowId'] = hhRowId;

    var continueBtn = document.getElementById('hhRosterModalContinue');
    continueBtn.removeEventListener('click', hhRosterContinue);
    continueBtn.dataset['rowId'] = hhRowId;
    continueBtn.dataset['hhMinicenced'] = hhMinicenced;
    continueBtn.dataset['fwMoz'] = isFwInMoz();
    continueBtn.dataset['hhId'] = hhId;

    // set the new HH ID and clear the prev. member roster
    document.getElementById('hhRosterModalTitle').textContent = hhId;
    document.getElementById('hhRosterModalBody').textContent = '';
    document.getElementById('rosterConfirm3Div').classList.add('d-none');
    document.getElementById('rosterConfirm3').classList.remove('is-invalid');

    var rosterConfirm1 = document.getElementById('rosterConfirm1');
    var rosterConfirm2 = document.getElementById('rosterConfirm2');
    rosterConfirm2.classList.add('d-none');

    if (!!rosterConfirm1.querySelector('.active')) {
      rosterConfirm1.querySelector('.active').classList.remove('active');
    }
    if (!!rosterConfirm2.querySelector('.active')) {
      rosterConfirm2.querySelector('.active').classList.remove('active');
    }

    rosterConfirm1.addEventListener('change', function () {
      rosterConfirm2.classList.remove('d-none');
    });

    if (hhMinicenced && isFwInMoz()) {
      rosterConfirm1.addEventListener('change', matchToggleListener);
      rosterConfirm2.addEventListener('change', matchToggleListener);
    } else {
      rosterConfirm1.removeEventListener('change', matchToggleListener);
      rosterConfirm2.removeEventListener('change', matchToggleListener);
    }

    odkData.arbitraryQuery(
      'hh_member',
      'SELECT name, surname, id FROM hh_member WHERE hh_id = ? AND form_status_hh_member_exit IS NOT ? ORDER BY id ASC',
      [hhId, 1],
      null,
      null,
      function (result) {
        var rosterList = document.getElementById('hhRosterModalBody');
        var template = document.getElementById('hhRosterTemplate');

        var resultCount = result.getCount();
        for (var i = 0; i < resultCount; i++) {
          var member = document.importNode(template.content, true);

          member.querySelector('span').textContent = result.getData(i, 'name') + ' ' + result.getData(i, 'surname');
          member.querySelector('small').textContent = result.getData(i, 'id');

          rosterList.appendChild(member);
        }

        document.getElementById('hhRosterModalContinue').addEventListener('click', hhRosterContinue);
        document.getElementById('hhRosterModalProceed').addEventListener('click', hhRosterContinue);
      },
      callbackFailure
    );

    $('#hhRosterModal').modal('show');
  };

  var hhRosterContinue = function (evt) {
    var currTarget = evt.currentTarget;

    // Check that both questions have been answered
    if (currTarget.id === 'hhRosterModalContinue') {
      var firstSelected = !!document.querySelector('#rosterConfirm1 .active');
      var secondSelected = !!document.querySelector('#rosterConfirm2 .active');

      if (!firstSelected && !secondSelected) {
        return;
      }
    }

    var hhMinicensed = currTarget.dataset['hhMinicenced'] === 'yes';

    var rosterMatch = selectedRosterMatch();
    var hhIdMatch = selectedHhIdMatch();

    if (rosterMatch || currTarget.id === 'hhRosterModalProceed') {
      hhRosterConfirm(evt, hhIdMatch);
    } else {
      if (currTarget.id === 'hhRosterModalContinue' && isFwInMoz() && hhMinicensed && !rosterMatch && hhIdMatch) {
        // this requires confirmation to delete data
        if (!document.getElementById('rosterConfirm3').checked) {
          document.getElementById('rosterConfirm3').classList.add('is-invalid');
          return;
        }

        $('#hhDeleteModal').modal();

        // MOZ requires marking all members as migrated
        // and HH level data removed

        odkData.query(
          'hh_member',
          'hh_id = ?',
          [currTarget.dataset['hhId']],
          null,
          null,
          null,
          null,
          null,
          null,
          false,
          function (result) {
            var resultCount = result.getCount();

            for (var i = 0; i < resultCount; i++) {
              odkData.updateRow(
                'hh_member',
                { 'form_status_hh_member_exit': 1 },
                result.getRowId(i),
                function () {},
                callbackFailure
              );
            }
          },
          callbackFailure
        );

        odkData.deleteRow(
          'census',
          null,
          currTarget.dataset['rowId'],
          function () {},
          callbackFailure
        );

        window.reuseHhId = setTimeout(function () {
          $('#hhDeleteModal').modal('hide');
          odkTables.addRowWithSurvey(
            {[ACTION_KEY]: SURVEY_ACTION},
            'census',
            'census',
            null,
            {
              fw_id: localStorage.getItem('FW_ID') || null,
              fw_is_in_moz: isFwInMoz(),
              hh_minicenced: 'no',
              hh_fw_geolocation: false,
              hh_new: false,
              hh_id: currTarget.dataset['hhId'],
              hh_id_readonly: true,
              match_roster: false,
              match_hhid: true
            }
          );
        }, 10000);
      } else {
        openSurveyNewHh(rosterMatch, hhIdMatch, false);
      }
    }
  };

  var matchToggleListener = function () {
    var confirm1Selected = document.querySelector('#rosterConfirm1 .active');
    var confirm2Selected = document.querySelector('#rosterConfirm2 .active');

    if (confirm1Selected && confirm2Selected) {
      var rosterMatch = selectedRosterMatch();
      var hhIdMatch = selectedHhIdMatch();

      if (!rosterMatch && hhIdMatch) {
        document.getElementById('rosterConfirm3Div').classList.remove('d-none');
      } else {
        document.getElementById('rosterConfirm3Div').classList.add('d-none');
      }
    }
  };

  var selectedRosterMatch = function () {
    var selected = document.querySelector('#rosterConfirm1 .active');
    return selected && selected.id === 'rosterConfirm1Yes'
  }

  var selectedHhIdMatch = function () {
    var selected = document.querySelector('#rosterConfirm2 .active');
    return selected && selected.id === 'rosterConfirm2Yes'
  }

  var hhRosterConfirm = function (evt, hhIdMatch = true) {
    // modified from odkTables.editRowWithSurvey
    // to pass fw_id and hh_fw_geolocation

    var uri = odkCommon.constructSurveyUri(
      'census',
      'census',
      evt.currentTarget.dataset['rowId'],
      null,
      {
        fw_id: localStorage.getItem('FW_ID') || null,
        fw_is_in_moz: isFwInMoz(),
        hh_fw_geolocation: true,
        hh_id_readonly: true,
        match_roster: true,
        match_hhid: hhIdMatch
      }
    );

    var hashString = uri.substring(uri.indexOf('#'));

    var extrasBundle = {
      url: platInfo.baseUri + 'system/index.html' + hashString
    };

    var intentArgs = {
      data: uri,
      type: "vnd.android.cursor.item/vnd.opendatakit.form",
      action: "android.intent.action.EDIT",
      category: "android.intent.category.DEFAULT",
      extras: extrasBundle
    };

    return odkCommon.doAction(
      {[ACTION_KEY]: SURVEY_ACTION},
      "org.opendatakit.survey.activities.SplashScreenActivity",
      intentArgs
    );
  };

  var hhOnClick = function (evt) {
    openHh(
      evt.currentTarget.dataset['rowId'],
      evt.currentTarget.dataset['hhId'],
      evt.currentTarget.dataset['hhMinicenced']
    );
  };

  var navOnClick = function (type) {
    return function (evt) {
      odkTables.openTableToNavigateView(
        {
          [ACTION_KEY]: NAV_ACTION,
          hhRowId: evt.currentTarget.dataset['rowId'],
          hhId: evt.currentTarget.dataset['hhId']
        },
        'hh_geo_location',
        searchParam[type].sqlWhereClause('hh_id', '_sync_state'),
        ['%' + localStorage.getItem(searchParam[type].storageKey) + '%', 'deleted'],
        evt.currentTarget.dataset['geoRowId']
      );
    };
  };

  var searchOnClick = function (type) {
    var cbSuccess = querySuccessCallback(type);

    return function () {
      var searchTerm = searchParam[type].processSearchTerm();

      if (searchTerm !== '') {
        localStorage.setItem(searchParam[type].storageKey, searchTerm);

        odkData.arbitraryQuery(
          'census',
          'SELECT census.*, ' +
          'hh_member.name AS hh_name, ' +
          'hh_member.surname AS hh_surname, ' +
          'hh_geo_location._id AS geo_rowId ' +
          'FROM census LEFT JOIN hh_member ON census.hh_head_new_select = hh_member._id ' +
          'LEFT JOIN hh_geo_location ON census.hh_id = hh_geo_location.hh_id WHERE ' +
          searchParam[type].sqlWhereClause('census.hh_id', 'census._sync_state'),
          ['%' + searchTerm + '%', 'deleted'],
          null,
          null,
          cbSuccess,
          callbackFailure
        );
      }
    };
  };

  var mapOnClick = function (type) {
    return function () {
      var searchTerm = localStorage.getItem(searchParam[type].storageKey);
      if (!!searchTerm) {
        odkTables.openTableToMapView(
          {[ACTION_KEY]: MAP_ACTION},
          'hh_geo_location',
          searchParam[type].sqlWhereClause('hh_id', '_sync_state'),
          ['%' + searchTerm + '%', 'deleted'],
          null
        );
      }
    };
  };

  var createNewHhOnClick = function () {
    openSurveyNewHh(true, true, true);
  };

  var createNewHhCompleteMismatchOnClick = function () {
    openSurveyNewHh(false, false, false);
  }

  var openSurveyNewHh = function (matchRoster, matchHhId, hhNew) {
    odkTables.addRowWithSurvey(
      null,
      'census',
      'census',
      null,
      {
        fw_id: localStorage.getItem('FW_ID') || null,
        fw_is_in_moz: isFwInMoz(),
        hh_minicenced: 'no',
        hh_fw_geolocation: false,
        hh_new: hhNew,
        hh_id_readonly: false,
        match_roster: matchRoster,
        match_hhid: matchHhId
      }
    );
  }

  var asUnpaintedOnClick = function () {
    localStorage.removeItem('hasPaintedId');
    localStorage.removeItem(searchParam.hhId.storageKey);
    location.reload();
  }

  var actionCallback = function () {
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

    var hhMetadata;
    if (action.dispatchStruct[ACTION_KEY] === NAV_ACTION) {
      // when arrive is clicked
      hhMetadata = action.dispatchStruct;
    } else if (action.dispatchStruct[ACTION_KEY] === MAP_ACTION) {
      // when a household is selected on the map
      hhMetadata = action.jsonValue.result;
    } else if (action.dispatchStruct[ACTION_KEY] === SURVEY_ACTION) {
      if (action.jsonValue &&
        action.jsonValue.result &&
        action.jsonValue.result.savepoint_type &&
        action.jsonValue.result.savepoint_type === 'COMPLETE') {
        // this row has been finalized, exit to Tables home screen
        odkCommon.closeWindow();
      }
    }

    if (!!hhMetadata && !!hhMetadata.hhRowId && !!hhMetadata.hhId) {
      openHh(hhMetadata.hhRowId, hhMetadata.hhId);
    }
  };

  var isFwInMoz = function () {
    return bohemiaUtil.getFwLocation() === bohemiaUtil.MOZ;
  }

  var configSearch = function (type) {
    searchParam[type].searchBtn = document.getElementById(type + 'SearchButton');
    searchParam[type].searchInput = document.getElementById(type + 'SearchInput');
    searchParam[type].mapBtn = document.getElementById(type + 'MapButton');
    searchParam[type].listContainer = document.getElementById(type + 'SearchList');
    searchParam[type].noResult = document.getElementById(type + 'NoResult');
    searchParam[type].notFound = document.getElementById(type + 'NotFound');
    searchParam[type].footer = document.getElementById(type + 'Footer');

    var searchBtn = searchParam[type].searchBtn;
    var searchInput = searchParam[type].searchInput;
    var mapBtn = searchParam[type].mapBtn;

    searchBtn.addEventListener('click', searchOnClick(type));
    searchInput.addEventListener('keyup', function (evt) {
      if (evt.key === 'Enter') {
        searchBtn.click();
        // use blur to hide the keyboard
        searchInput.blur();

        evt.preventDefault();
      }
    });
    searchInput.addEventListener('input', function () {
      // disable map everytime the search changes
      mapBtn.classList.add('d-none');
    });

    mapBtn.addEventListener('click', mapOnClick(type));

    var searchTerm = localStorage.getItem(searchParam[type].storageKey);
    if (!!searchTerm) {
      searchInput.value = searchTerm;
      searchBtn.click();
    }
  };

  var searchParam = {
    hhId: {
      storageKey: 'bohemiaHhSearch',
      sqlWhereClause: function (hhIdCol, syncStateCol) {
        return "replace(" + hhIdCol + ", '-', '') LIKE ? AND " + syncStateCol + " IS NOT ?";
      },
      navOnClick: navOnClick('hhId'),
      processSearchTerm: function () {
        return this.searchInput.value
          .trim()
          .toUpperCase()
          .replace(/\s|-/g, '');
      }
    },
    member: {
      storageKey: 'bohemiaMemberSearch',
      sqlWhereClause: function (hhIdCol, syncStateCol) {
        return hhIdCol +
          " IN (SELECT DISTINCT hh_id FROM hh_member WHERE lower(replace(name || surname, ' ', '')) LIKE lower(?))" +
          " AND " + syncStateCol + " IS NOT ?";
      },
      navOnClick: navOnClick('member'),
      processSearchTerm: function () {
        return this.searchInput.value
          .trim()
          .replace(/\s/g, '');
      }
    }
  };

  document.addEventListener('DOMContentLoaded', function () {
    odkData.getOdkDataIf().getResponseJSON();

    configSearch('hhId');
    configSearch('member');

    $('a[data-toggle="pill"]').on('shown.bs.tab', function (evt) {
      odkCommon.setSessionVariable('TAB', '#' + $(evt.target).attr('id'));

      if (!odkCommon.hasListener()) {
        odkCommon.registerListener(actionCallback);
        actionCallback();
      }
    });

    document.getElementById('hhIdNewHhButton').addEventListener('click', createNewHhOnClick);
    document.getElementById('memberNewHhButton').addEventListener('click', createNewHhOnClick);
    document.getElementById('hhRosterModalNo').addEventListener('click', createNewHhCompleteMismatchOnClick);

    document.getElementById('hhIdAsUnpainted').addEventListener('click', asUnpaintedOnClick);

    var paintedElem = document.querySelectorAll('.hh-painted');
    var notPaintedElem = document.querySelectorAll('.hh-not-painted');
    var hhPainted = !!localStorage.getItem('hasPaintedId');
    for (var i = 0; i < paintedElem.length; i++) {
      paintedElem[i].classList.toggle('d-none', !hhPainted);
    }
    for (var i = 0; i < notPaintedElem.length; i++) {
      notPaintedElem[i].classList.toggle('d-none', hhPainted);
    }

    var modalPaintedElem = document.querySelectorAll('.modal-hh-painted');
    var modalNotPaintedElem = document.querySelectorAll('.modal-hh-not-painted');
    var modalHhPainted = !!localStorage.getItem('modalSelectedPaintedId');
    for (var i = 0; i < modalPaintedElem.length; i++) {
      modalPaintedElem[i].classList.toggle('d-none', !modalHhPainted);
    }
    for (var i = 0; i < modalNotPaintedElem.length; i++) {
      modalNotPaintedElem[i].classList.toggle('d-none', modalHhPainted);
    }

    localizeUtil.localizePage();

    document
      .getElementById('wrapper')
      .classList
      .remove('d-none');

    var selectedTab = odkCommon.getSessionVariable('TAB');
    if (!!selectedTab && !document.querySelector(selectedTab + '.active')) {
      $(selectedTab).tab('show');
    } else {
      // only register a listener when the screen is on the desired tab already.
      // when a tab transition is about to take place, register the listener after the transition
      odkCommon.registerListener(actionCallback);
      actionCallback();
    }
  });
})();
