'use strict';

define(['promptTypes', 'handlebarsHelpers', 'handlebars', 'jquery', 'prompts'], function(promptTypes, handlebarsHelpers, Handlebars, $) {
  Handlebars.registerHelper('localizeTextSafe', function (displayObjectField) {
    return new Handlebars.SafeString(Handlebars.helpers['localizeText'](displayObjectField));
  })

  return {
    contents: promptTypes.contents.extend({
      templatePath: '../config/assets/customPromptTypes/templates/contents.handlebars'/*,
      configureRenderContext: function (ctxt) {
        promptTypes.contents.prototype.configureRenderContext(this, $.extend({}, ctxt, {
          success: function () {

          }
        }))
      }*/
    })
  }
  // return {
  //   linked_table_counting: promptTypes.linked_table.extend({
  //     configureRenderContext: function (ctxt) {
  //       var that = this;
  //       var queryDefn = opendatakit.getQueriesDefinition(this.values_list);
  //
  //       var modifiedCtxt = $.extend({}, ctxt, {
  //         success: function () {
  //           var subFormStatusCol = queryDefn.subFormStatusCol;
  //
  //           if (subFormStatusCol === undefined || subFormStatusCol === null || subFormStatusCol === '') {
  //             that.setValueDeferredChange(countInstances(that.renderContext.instances));
  //             ctxt.success();
  //           } else {
  //             var modifiedSel = that._cachedSelection || '';
  //             if (modifiedSel !== '') {
  //               modifiedSel += ' AND ';
  //             }
  //             modifiedSel += '"' + queryDefn.subFormStatusCol + '" = ?';
  //
  //             var modifiedSelArgs = queryDefn.selectionArgs() || [];
  //             modifiedSelArgs.push('1');
  //
  //             database.get_linked_instances($.extend({}, ctxt, {
  //               success: function (instanceList) {
  //                 that.setValueDeferredChange(countInstances(instanceList));
  //                 ctxt.success();
  //               }
  //             }), that.getLinkedTableId(), modifiedSel, modifiedSelArgs);
  //           }
  //         }
  //       });
  //
  //       promptTypes.linked_table.prototype.configureRenderContext.apply(this, [modifiedCtxt]);
  //     }
  //   })
  // }
});
