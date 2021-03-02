'use strict';

define(['promptTypes', 'handlebars', 'underscore', 'jquery', 'prompts'], function(promptTypes, Handlebars, _, $) {
  Handlebars.registerHelper('localizeTextSafe', function (displayObjectField) {
    return new Handlebars.SafeString(Handlebars.helpers['localizeText'](displayObjectField));
  });

  return {
    contents: promptTypes.contents.extend({
      templatePath: '../config/assets/customPromptTypes/templates/contents.handlebars',
      configureRenderContext: function(ctxt) {
        var that = this;

        promptTypes.contents.prototype.configureRenderContext.apply(this, [$.extend({}, ctxt, {
          success: function () {
            that.renderContext.prompts = _.groupBy(that.renderContext.prompts, function (prompt) {
              return prompt.display.section;
            });

            delete that.renderContext.prompts['undefined'];

            ctxt.success();
          }
        })]);
      },
      afterRender: function () {
        // remove empty sections
        $('.panel:has(.list-group:empty)').remove();
      }
    })
  }
});
