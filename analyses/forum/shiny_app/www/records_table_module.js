


function records_table_module_js(ns_prefix) {


  $("#" + ns_prefix + "record_table").on("click", ".edit_btn", function() {
    Shiny.setInputValue(ns_prefix + "record_id_to_edit", this.id, { priority: "event"});
    $(this).tooltip('hide');
  });
}

