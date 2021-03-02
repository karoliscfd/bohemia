'use strict';

define(['promptTypes', 'prompts'], function(promptTypes) {
  return {
    note: promptTypes.note.extend({
      templatePath: '../config/assets/customPromptTypes/templates/note.handlebars'
    })
  }
});
