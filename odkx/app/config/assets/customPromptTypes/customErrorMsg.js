'use strict';

define(['promptTypes', 'formulaFunctions', 'underscore', 'prompts'], function(promptTypes, formulaFunctions, _) {
  var buildErrMsg = function (that, messageKey, fieldDisplayName, locale) {
    var messageToken = that.display[messageKey];
    var localizedMessage = formulaFunctions.localize(locale, messageToken);

    // the error message is the stock error message,
    // append the prompt display
    if (messageToken === promptTypes.base.prototype._baseProtoDisplay[messageKey]) {
      localizedMessage += ' ' + (fieldDisplayName || '');
    }

    return {message: localizedMessage };
  }

  var patchIsValid = function (isStrict) {
    // modified from prompts.js

    var that = this;
    var isRequired = false;

    // compute the locale and field display name...
    // used when presenting error messages.
    var locale = formulaFunctions.getCurrentLocale();

    var fieldDisplayName;
    if (that.renderContext.display && (that.renderContext.display.title || that.renderContext.display.prompt)) {
      var textOrMap = (that.renderContext.display.title ?
        that.renderContext.display.title : that.renderContext.display.prompt);
      textOrMap = odkCommon.lookupToken(textOrMap);
      fieldDisplayName = formulaFunctions.localize(locale, textOrMap);
    } else {
      fieldDisplayName = '';
    }

    try {
      isRequired = that.required ? that.required() : false;
    } catch (e) {
      if ( isStrict ) {
        odkCommon.log('E',"prompts."+that.type+"._isValid.required.exception.strict px: " +
          that.promptIdx + " exception: " + e.message + " e: " + String(e));

        return buildErrMsg(that, 'required_exception_message', fieldDisplayName, locale);
      } else {
        odkCommon.log("W","prompts."+that.type+"._isValid.required.exception.ignored px: " +
          that.promptIdx + " exception: " + e.message + " e: " + String(e));
        isRequired = false;
      }
    }
    that.valid = true;
    if ( !('name' in that) ) {
      // no data validation if no persistence...
      return null;
    }

    var value = that.getValue();
    if ( value === undefined || value === null || value === "" ) {
      if ( isRequired ) {
        that.valid = false;
        return buildErrMsg(that, 'required_message', fieldDisplayName, locale);
      }
    } else if ( 'validateValue' in that ) {
      if ( !that.validateValue() ) {
        that.valid = false;
        return buildErrMsg(that, 'invalid_value_message', fieldDisplayName, locale);
      }
    }
    if ( 'constraint' in that ) {
      var outcome = false;
      try {
        outcome = that.constraint({"allowExceptions":true});
        if ( !outcome ) {
          that.valid = false;
          return buildErrMsg(that, 'constraint_message', fieldDisplayName, locale);
        }
      } catch (e) {
        odkCommon.log('E',"prompts."+that.type+".baseValidate.constraint.exception px: " +
          that.promptIdx + " exception: " + e.message + " e: " + String(e));
        outcome = false;
        that.valid = false;
        return buildErrMsg(that, 'constraint_exception_message', fieldDisplayName, locale);
      }
    }
    return null;
  };

  var toModify = _.keys(promptTypes);
  return _.chain(toModify)
    .object(toModify)
    .mapObject(function (prompt) {
      return promptTypes[prompt].extend({
        _isValid: patchIsValid
      });
    })
    .value();
});
