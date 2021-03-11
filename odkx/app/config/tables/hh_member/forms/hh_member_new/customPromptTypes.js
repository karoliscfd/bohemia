define([
  '../../../../assets/customPromptTypes/retrieve_extid',
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customDate',
  '../../../../assets/customPromptTypes/customErrorMsg'
], function(retrieve_extid, customToc, customDate, customErrorMsg) {
  return Object.assign({}, customErrorMsg, retrieve_extid, customToc, customDate);
});
