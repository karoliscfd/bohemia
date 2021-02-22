'use strict';

define(['promptTypes', 'jquery', 'database', 'prompts'], function(promptTypes, $, database) {
  return {
    next_extid: promptTypes.base.extend({
      type: 'next_extid',
      template: function () { return ''; },
      hideInContents: true,
      valid: true,
      configureRenderContext: function (ctxt) {
        var that = this;
        var hhId = database.getDataValue('hh_id');

        odkData.arbitraryQuery(
          'hh_member',
          'SELECT max(CAST(substr(id, 10) AS INT)) AS maxId ' +
          'FROM hh_member WHERE length(id) = 11 AND hh_id = ? AND _savepoint_type = ?',
          [hhId, 'COMPLETE'],
          null,
          null,
          function (result) {
            var rawMaxId = result.get('maxId');
            var next = !!rawMaxId ? Number(rawMaxId) + 1 : 1;

            that.setValueDeferredChange({
              resident: hhId + '-' + odkCommon.padWithLeadingZeros(next, 3),
              non_resident: hhId + '-' + (900 + next)
            });

            ctxt.success();
          },
          function (error) {
            ctxt.failure({message: error});
          }
        );
      }
    }),
    next_extid_deceased: promptTypes.base.extend({
      type: 'next_extid_deceased',
      template: function () { return ''; },
      hideInContents: true,
      valid: true,
      configureRenderContext: function (ctxt) {
        var that = this;
        var hhId = database.getDataValue('hh_id');

        odkData.arbitraryQuery(
          'hh_member',
          'SELECT max(CAST(substr(hh_death_id, 10) AS INT)) AS maxId ' +
          'FROM hh_death WHERE length(hh_death_id) = 11 AND hh_id = ? AND _savepoint_type = ?',
          [hhId, 'COMPLETE'],
          null,
          null,
          function (result) {
            var rawMaxId = result.get('maxId');
            var next = !!rawMaxId ? Number(rawMaxId) + 1 : 1;

            that.setValueDeferredChange(hhId + '-' + (700 + next));
            ctxt.success();
          },
          function (error) {
            ctxt.failure({message: error});
          }
        );
      }
    })
  }
});
