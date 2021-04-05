'use strict';

define(['screenTypes', 'underscore', 'jquery', 'screens'], function (screenTypes, _, $) {
  // Copied from ODK-X screens.js
  // modified debounce interval from 500ms to 50ms

  return {
    screen: screenTypes.screen.extend({
      reRender: function(ctxt) {
        var that = this;

        that.pendingCtxt.push(ctxt);
        odkCommon.log("D","screens.reRender: called");
        that.debouncedReRender();
      },
      debouncedReRender: _.debounce(function() {
        var that = this;
        that.focusScrollPos = null;
        that.horizontalFocusScrollPos = null;
        that.$focusPromptTest = null;
        var ctxt = null;

        that.focusScrollPos = $(window).scrollTop();
        if ( that.screenOverflowClass ) {
          that.horizontalFocusScrollPos = $(that.screenOverflowClass).scrollLeft();
        }
        odkCommon.log("D","screens.reRender.debouncedReRender: focusScrollPos = " + that.focusScrollPos);
        odkCommon.log("D","screens.reRender.debouncedReRender: horizontalFocusScrollPos = " + that.horizontalFocusScrollPos);

        // Find the element in focus
        that.$focusPromptTest = $(':focus');
        if (that.$focusPromptTest.length === 0) {
          that.$focusPromptTest = null;
        }

        odkCommon.log("D","screens.reRender.debouncedReRender: pendingCtxtLength: " + that.pendingCtxt.length);
        if (that.pendingCtxt.length > 0) {
          // we should at least have one on the queue.
          // process the first queued action first
          ctxt = that.pendingCtxt.shift();
        } else {
          odkCommon.log("W","screens.reRender.debouncedReRender: no pendingCtxts!!!");
          return;
        }

        // and we want to then process all subsequent reRender requests that aren't the same as the one we already have...
        var nextCtxt;
        while (that.pendingCtxt.length > 0) {
          nextCtxt = that.pendingCtxt.shift();
          if ( nextCtxt !== ctxt ) {
            odkCommon.log("W","screens.reRender.debouncedReRender: chaining an extra pendingCtxt!!!");
            ctxt.setTerminalContext(nextCtxt);
          }
        }

        // and process the first reRender first...
        that._screenManager.refreshScreen(ctxt);
      }, 50)
    })
  };
});
