define([
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customDate',
  '../../../../assets/customPromptTypes/customErrorMsg'
], function(customToc, customDate, customErrorMsg) {
  return Object.assign({}, customErrorMsg, customToc, customDate);
});
