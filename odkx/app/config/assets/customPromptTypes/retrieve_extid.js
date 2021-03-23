'use strict';

define(['./customErrorMsg', 'prompts'], function(customErrorMsg) {
  var buildDisplayVal = function (resultNum, resultObj) {
    return {
      title: {
        text: resultObj.getData(resultNum, 'name') + ' ' + resultObj.getData(resultNum, 'surname') +
          ' [' + resultObj.getData(resultNum, 'id') + ']'
      }
    };
  };

  return {
    retrieve_extid: customErrorMsg.select_one_dropdown.extend({
      type: 'retrieve_extid',
      hideInContents: true,
      populateChoicesViaQueryUsingAjax: function (query, ctxt) {
        var that = this;

        var name = query.uri() || {};
        var firstName = (name.firstName || '').trim().replace(/\s/g, '');
        var lastName = (name.lastName || '').trim().replace(/\s/g, '');

        if (!firstName || !lastName) {
          that.renderContext.choices = [];
          ctxt.success('success');
          return;
        }

        odkData.query(
          'hh_member',
          "lower(replace(name, ' ', '')) LIKE lower(?) AND " +
          "lower(replace(surname, ' ', '')) LIKE lower(?) AND " +
          "length(id) = 11 AND _savepoint_type = ?",
          ['%' + firstName + '%', '%' + lastName + '%', 'COMPLETE'],
          null,
          null,
          'id',
          'ASC',
          null,
          null,
          true,
          function (result) {
            var instanceList = []
            var instanceCount = result.getCount();

            for (var i = 0; i < instanceCount; i++) {
              instanceList.push({
                display: buildDisplayVal(i, result),
                data_value: result.getData(i, 'id'),
              });
            }

            that.renderContext.choices = instanceList;
            ctxt.success('success');
          },
          function (error) {
            console.error(error);
            ctxt.failure({message: error});
          }
        )
      }
    })
  }
});
