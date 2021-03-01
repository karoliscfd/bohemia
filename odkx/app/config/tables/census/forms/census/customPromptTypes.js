'use strict';

define([
  '../../../../assets/customPromptTypes/linked_table_counting',
  '../../../../assets/customPromptTypes/next_extid',
  '../../../../assets/customPromptTypes/customToc',
  'promptTypes',
  'controller',
  'jquery',
  '../../../../assets/customPromptTypes/hamlet_info'
], function(linked_table_counting, next_extid, customToc, promptTypes, controller, $) {
  return Object.assign({}, linked_table_counting, next_extid, customToc, {
    exit_survey: promptTypes.base.extend({
      type: 'exit_survey',
      template: function () { return ''; },
      valid: true,
      afterRender: function () {
        $(document)
          .on('bohemiaExitSurvey', function (evt) {
            controller.screenManager.ignoreChanges(evt);
          })
          .trigger('bohemiaExitSurvey');
      }
    })
  });
});
