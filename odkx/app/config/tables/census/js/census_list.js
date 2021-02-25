'use strict';

(function () {
  var MAP_ACTION = 'MAP';
  var NAV_ACTION = 'NAV';
  var ACTION_KEY = 'CENSUS_LIST_ACTION';

  var platInfo = JSON.parse(odkCommon.getPlatformInfo());

  var callbackFailure = function (error) {
    localStorage.removeItem(searchParam.hhId.storageKey);
    localStorage.removeItem(searchParam.member.storageKey);
    searchParam.hhId.footer.classList.add('d-none');
    searchParam.member.footer.classList.add('d-none');

    $('#hhRosterModal').modal('hide');

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

        var fields = newListItem.querySelectorAll('.hh-list-field');
        fields[0].textContent = hhId;
        fields[1].textContent = result.getData(i, 'hh_name') + ' ' + result.getData(i, 'hh_surname');

        var buttons = newListItem.querySelectorAll('button');
        buttons[0].dataset['rowId'] = rowId;
        buttons[0].dataset['hhId'] = hhId;
        buttons[0].addEventListener('click', hhOnClick);

        buttons[1].dataset['rowId'] = rowId;
        buttons[1].dataset['hhId'] = hhId;
        buttons[1].dataset['geoRowId'] = result.getData(i, 'geo_rowId');
        buttons[1].addEventListener('click', searchParam[type].navOnClick);

        searchParam[type].listContainer.appendChild(newListItem);
      }
    }
  };

  var openHh = function (hhRowId, hhId) {
    // disable the proceed button before the new roster is populated
    document.getElementById('hhRosterModalProceed').removeEventListener('click', hhRosterConfirm);
    document.getElementById('hhRosterModalProceed').dataset['rowId'] = hhRowId;

    // set the new HH ID and clear the prev. member roster
    document.getElementById('hhRosterModalTitle').textContent = hhId;
    document.getElementById('hhRosterModalBody').textContent = '';

    odkData.arbitraryQuery(
      'hh_member',
      'SELECT name, surname, id FROM hh_member WHERE hh_id = ? ORDER BY id ASC',
      [hhId],
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

        document.getElementById('hhRosterModalProceed').addEventListener('click', hhRosterConfirm);
      },
      callbackFailure
    );

    $('#hhRosterModal').modal('show');
  }

  var hhRosterConfirm = function (evt) {
    // modified from odkTables.editRowWithSurvey
    // to pass fw_id and hh_fw_geolocation

    var uri = odkCommon.constructSurveyUri(
      'census',
      'census',
      evt.currentTarget.dataset['rowId'],
      null,
      {
        fw_id: localStorage.getItem('FW_ID') || null,
        hh_fw_geolocation: true
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
      null,
      "org.opendatakit.survey.activities.SplashScreenActivity",
      intentArgs
    );
  }

  var hhOnClick = function (evt) {
    openHh(evt.currentTarget.dataset['rowId'], evt.currentTarget.dataset['hhId']);
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
        searchParam[type].sqlWhereClause('hh_id'),
        ['%' + localStorage.getItem(searchParam[type].storageKey) + '%'],
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
          'LEFT JOIN hh_geo_location ON census.hh_id = hh_geo_location.hh_id WHERE ' + searchParam[type].sqlWhereClause('census.hh_id'),
          ['%' + searchTerm + '%'],
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
      var searchTerm = localStorage.getItem(searchParam[type].storageKey)
      if (!!searchTerm) {
        odkTables.openTableToMapView(
          {[ACTION_KEY]: MAP_ACTION},
          'hh_geo_location',
          searchParam[type].sqlWhereClause('hh_id'),
          ['%' + searchTerm + '%'],
          null
        );
      }
    };
  };

  var createNewHhOnClick = function () {
    openSurveyNewHh(false);
  };

  var createNewHhRosterMismatchOnClick = function () {
    openSurveyNewHh(true);
  }

  var openSurveyNewHh = function (rosterMismatch) {
    odkTables.addRowWithSurvey(
      null,
      'census',
      'census',
      null,
      {
        fw_id: localStorage.getItem('FW_ID') || null,
        hh_minicenced: 'no',
        hh_roster_mismatch: rosterMismatch,
        hh_fw_geolocation: false,
        hh_new: true
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
    }

    if (!!hhMetadata.hhRowId && !!hhMetadata.hhId) {
      openHh(hhMetadata.hhRowId, hhMetadata.hhId);
    }
  };

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
      sqlWhereClause: function (column) {
        return "replace(" + column + ", '-', '') LIKE ?";
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
      sqlWhereClause: function (column) {
        return column +
          " IN (SELECT DISTINCT hh_id FROM hh_member WHERE lower(replace(name || surname, ' ', '')) LIKE lower(?))";
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
    document.getElementById('hhRosterModalNo').addEventListener('click', createNewHhRosterMismatchOnClick);

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

    odkData.getOdkDataIf().getResponseJSON();
  });
})();
