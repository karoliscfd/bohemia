define([
  '../../../../assets/customPromptTypes/linked_table_counting',
  '../../../../assets/customPromptTypes/customToc',
  '../../../../assets/customPromptTypes/customNote',
], function(linked_table_counting, customToc, customNote) {
  return Object.assign({}, linked_table_counting, customToc, customNote);
});
