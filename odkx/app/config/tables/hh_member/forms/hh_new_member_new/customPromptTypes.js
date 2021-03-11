define([
  '../../../../assets/customPromptTypes/retrieve_extid',
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customErrorMsg'
], function(retrieve_extid, customToc, customErrorMsg) {
  return Object.assign({}, customErrorMsg, retrieve_extid, customToc);
});
