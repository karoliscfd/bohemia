'use strict';

define([
  './customErrorMsg',
  'formulaFunctions',
  'moment',
  'underscore',
  'prompts'
], function(customErrorMsg, formulaFunctions, moment, _) {
  var monthKeys = [
    'month_1',
    'month_2',
    'month_3',
    'month_4',
    'month_5',
    'month_6',
    'month_7',
    'month_8',
    'month_9',
    'month_10',
    'month_11',
    'month_12'
  ];

  var localizedMonths = {
    default: _.map(monthKeys, function (key) {
      return odkCommon.localizeText('', key);
    }),
    pt: _.map(monthKeys, function (key) {
      return odkCommon.localizeText('pt', key);
    }),
    sw: _.map(monthKeys, function (key) {
      return odkCommon.localizeText('sw', key);
    })
  };

  return {
    date_no_time: customErrorMsg.date_no_time.extend({
      timeTemplate: 'YYYY / MMMM / DD',
      afterRender: function () {
        moment.locale('en', {
          months: localizedMonths[formulaFunctions.getCurrentLocale()] || localizedMonths.default
        });
        customErrorMsg.date_no_time.prototype.afterRender.apply(this, []);
      }
    }),
    birth_date: customErrorMsg.birth_date.extend({
      timeTemplate: 'YYYY / MMMM / DD',
      afterRender: function () {
        moment.locale('en', {
          months: localizedMonths[formulaFunctions.getCurrentLocale()] || localizedMonths.default
        });
        customErrorMsg.birth_date.prototype.afterRender.apply(this, []);
      }
    })
  }
});
