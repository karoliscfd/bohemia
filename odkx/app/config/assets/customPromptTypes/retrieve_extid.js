'use strict';

define(['promptTypes', 'prompts'], function(promptTypes) {
  var buildDisplayVal = function (resultNum, resultObj) {
    return {
      title: {
        text: resultObj.getData(resultNum, 'name') + ' ' + resultObj.getData(resultNum, 'surname') +
          ' [' + resultObj.getData(resultNum, 'id') + ']'
      }
    };
  };

  return {
    retrieve_extid: promptTypes.select_one_dropdown.extend({
      type: 'retrieve_extid',
      hideInContents: true,
      populateChoicesViaQueryUsingAjax: function (query, ctxt) {
        var that = this;
        var search = (query.uri() || '').trim().replace(/\s/g, '');

        if (!search) {
          that.renderContext.choices = [];
          ctxt.success('success');
          return;
        }

        odkData.query(
          'hh_member',
          "lower(replace(name || surname, ' ', '')) LIKE lower(?) AND length(id) = 11 AND _savepoint_type = ?",
          ['%' + search + '%', 'COMPLETE'],
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
