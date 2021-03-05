'use strict';

define([
  'promptTypes',
  'opendatakit',
  'handlebars',
  'underscore',
  'jquery',
  'prompts'], function (promptTypes, opendatakit, Handlebars, _, $) {
  Handlebars.registerHelper('localizeTextSafe', function (displayObjectField) {
    return new Handlebars.SafeString(Handlebars.helpers['localizeText'](displayObjectField));
  });

  return {
    contents: promptTypes.contents.extend({
      templatePath: '../config/assets/customPromptTypes/templates/contents.handlebars',
      configureRenderContext: function (ctxt) {
        var that = this;

        promptTypes.contents.prototype.configureRenderContext.apply(this, [$.extend({}, ctxt, {
          success: function () {
            that.renderContext.prompts = _.groupBy(that.renderContext.prompts, function (prompt) {
              return prompt.display.section;
            });

            var undefinedSection = that.renderContext.prompts['undefined'];

            delete that.renderContext.prompts['undefined'];
            if (_.isEmpty(that.renderContext.prompts)) {
              // if the undefined section is the only section
              that.renderContext.prompts = undefinedSection;
              that.renderContext.singleSection = true;
            }

            that.renderContext.isSubform = opendatakit.getSettingValue('form_id') !== 'census';

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
