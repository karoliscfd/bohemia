define([
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customNote',
  '../../../../assets/customPromptTypes/customErrorMsg'
], function(customToc, customNote, customErrorMsg) {
  return Object.assign({}, customErrorMsg, customToc, customNote);
});
