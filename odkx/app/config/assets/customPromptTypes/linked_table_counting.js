'use strict';

define(['promptTypes', 'opendatakit', 'database', 'jquery', 'underscore', 'prompts'], function (promptTypes, opendatakit, database, $, _) {
  var getDataSingleRow = function (backingObj, index) {
    return function (elementKeyOrPath) {
      return backingObj.getData(index, elementKeyOrPath);
    }
  }

  var get_linked_instances = function (ctxt, dbTableName, selection, selectionArgs, displayElementName, orderBy) {
    // copied from database.js, added raw_result

    if (dbTableName === 'framework') {
      ctxt.success([]);
      return;
    }

    var ss = database._selectMostRecentFromDataTableStmt(dbTableName, selection, selectionArgs, orderBy);
    odkData.arbitraryQuery(dbTableName, ss.stmt, ss.bind, null, null,
      function (reqData) {
        var instanceList = [];
        for (var rowCntr = 0; rowCntr < reqData.getCount(); rowCntr++) {
          var ts = odkCommon.toDateFromOdkTimeStamp(reqData.getData(rowCntr, '_savepoint_timestamp'));
          instanceList.push({
            display_field: (displayElementName === undefined || displayElementName === null) ?
              ((ts === null) ? '' : ts.toISOString()) : reqData.getData(rowCntr, displayElementName),
            instance_id: reqData.getData(rowCntr, '_id'),
            savepoint_timestamp: ts,
            savepoint_type: reqData.getData(rowCntr, '_savepoint_type'),
            savepoint_creator: reqData.getData(rowCntr, '_savepoint_creator'),
            locale: reqData.getData(rowCntr, '_locale'),
            form_id: reqData.getData(rowCntr, '_form_id'),
            default_access: reqData.getData(rowCntr, '_default_access'),
            row_owner: reqData.getData(rowCntr, '_row_owner'),
            group_read_only: reqData.getData(rowCntr, '_group_read_only'),
            group_modify: reqData.getData(rowCntr, '_group_modify'),
            group_privileged: reqData.getData(rowCntr, '_group_privileged'),
            effective_access: reqData.getData(rowCntr, '_effective_access'),
            raw_result: Object.assign({}, reqData, {
              getData: getDataSingleRow(reqData, rowCntr)
            })
          });
        }
        ctxt.log('D', 'get_linked_instances.inside', dbTableName + ' instanceList: ' + instanceList.length);
        ctxt.success(instanceList);
      }, function (errorMsg) {
        ctxt.failure({message: errorMsg});
      });
  };

  var processInstances = function (instanceList, display, subFormStatusCol) {
    var instanceCount = 0;

    for (var i = 0; i < instanceList.length; i++) {
      if (!!subFormStatusCol) {
        instanceList[i].savepoint_type = instanceList[i].raw_result.getData(subFormStatusCol) === 1 ?
          opendatakit.savepoint_type_complete :
          opendatakit.savepoint_type_incomplete;
      }

      if (instanceList[i].savepoint_type === opendatakit.savepoint_type_complete) {
        instanceList[i].icon_class = 'glyphicon-ok';
        instanceCount++;
      } else {
        instanceList[i].icon_class = 'glyphicon-warning-sign';
      }

      if (!!display.showResident) {
        instanceList[i].resident = odkCommon.localizeText(
          database.getInstanceMetaDataValue('_locale') || opendatakit.getCachedLocale(),
          instanceList[i].raw_result.getData('resident_status')
        );
      }

      if (!!display.showExtId) {
        instanceList[i].extId = instanceList[i].raw_result.getData('id');
      }

      instanceList[i].savepoint_timestamp =
        opendatakit.getShortDateFormat(instanceList[i].savepoint_timestamp) || instanceList[i].savepoint_timestamp;
    }

    return instanceCount;
  };

  var standardColumns = [
    {title: 'last_saved'},
    {title: 'name'},
    {title: 'finalized'},
    {title: ''}
  ];

  var columnsWithResident = [
    {title: 'last_saved'},
    {title: 'name'},
    {title: 'resident'},
    {title: 'finalized'},
    {title: ''}
  ];

  var columnsWithExtId = [
    {title: 'last_saved'},
    {title: 'name'},
    {title: 'extid'},
    {title: 'finalized'},
    {title: ''}
  ];

  return {
    linked_table: promptTypes.linked_table.extend({
      templatePath: '../config/assets/customPromptTypes/templates/linked_table.handlebars',
      configureRenderContext: function (ctxt) {
        var that = this;

        promptTypes.linked_table.prototype.configureRenderContext.apply(this, [$.extend({}, ctxt, {
          success: function () {
            that.renderContext.columns = standardColumns;
            ctxt.success();
          }
        })])
      }
    }),

    linked_table_counting: promptTypes.linked_table.extend({
      templatePath: '../config/assets/customPromptTypes/templates/linked_table.handlebars',
      configureRenderContext: function (ctxt) {
        var that = this;
        var queryDefn = opendatakit.getQueriesDefinition(this.values_list);

        promptTypes.linked_table.prototype.configureRenderContext.apply(this, [$.extend({}, ctxt, {
          success: function () {
            that.renderContext.columns = standardColumns;
            if (!!that.display.showResident) {
              that.renderContext.columns = columnsWithResident;
            } else if (!!that.display.showExtId) {
              that.renderContext.columns = columnsWithExtId;
            }

            var subFormStatusCol = queryDefn.subFormStatusCol;
            get_linked_instances($.extend({}, ctxt, {
              success: function (instanceList) {
                instanceList = _.filter(instanceList, function(instance) {
                  return that.choice_filter(instance);
                });

                that.setValueDeferredChange(processInstances(instanceList, that.display, subFormStatusCol));
                that.renderContext.instances = instanceList;
                ctxt.success();
              }
            }), that.getLinkedTableId(), that._cachedSelection, queryDefn.selectionArgs(), that._linkedCachedInstanceName, that._cachedOrderBy);
          }
        })]);
      },
      afterRender: function () {
        if (!!this.display.hideStatus) {
          this.$el.find('table tr').find('td:eq(-2),th:eq(-2)').remove();
        }
      }
    })
  }
});
