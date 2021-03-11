define([
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customErrorMsg'
], function(customToc, customErrorMsg) {
  return Object.assign({}, customErrorMsg, customToc);
});
