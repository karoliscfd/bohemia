'use strict';

(function () {
  var platInfo = JSON.parse(odkCommon.getPlatformInfo());

  var callbackFailure = function (error) {
    console.error(error);
    alert(error);
  };

  var callbackSuccess = function (result) {
    // clear the list
    var listContainer = document.getElementById('hhIncompleteList');
    listContainer.innerText = '';

    var resultCount = result.getCount();
    if (resultCount === 0) {
      document.getElementById('hhIncompleteNoResult').classList.remove('d-none');
      return;
    } else {
      document.getElementById('hhIncompleteNoResult').classList.add('d-none');
    }

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
      buttons[0].addEventListener('click', openHh);

      listContainer.appendChild(newListItem);
    }
  };

  var openHh = function (evt) {
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
  };

  document.addEventListener('DOMContentLoaded', function () {
    odkData.getOdkDataIf().getResponseJSON();

    odkData.arbitraryQuery(
      'census',
      'SELECT census.*, ' +
      'hh_member.name AS hh_name, ' +
      'hh_member.surname AS hh_surname ' +
      'FROM census LEFT JOIN hh_member ON census.hh_head_new_select = hh_member._id ' +
      'WHERE census._savepoint_type = ?',
      ['INCOMPLETE'],
      null,
      null,
      callbackSuccess,
      callbackFailure
    );

    localizeUtil.localizePage();

    document
      .getElementById('wrapper')
      .classList
      .remove('d-none');
  });
})();
