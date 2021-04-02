define([
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customNote',
  '../../../../assets/customPromptTypes/customErrorMsg',
  '../../../../assets/customPromptTypes/linked_table_counting'
], function(customToc, customNote, customErrorMsg, linked_table_counting) {
  return Object.assign({}, customErrorMsg, customToc, customNote, linked_table_counting);
});
