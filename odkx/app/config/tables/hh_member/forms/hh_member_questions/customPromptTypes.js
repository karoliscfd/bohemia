define([
  '../../../../assets/customPromptTypes/linked_table_counting',
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customNote',
  '../../../../assets/customPromptTypes/customErrorMsg',
  '../../../../assets/customPromptTypes/customDate',
], function(linked_table_counting, customToc, customNote, customErrorMsg, customDate) {
  return Object.assign({}, customErrorMsg, linked_table_counting, customToc, customNote, customDate);
});
