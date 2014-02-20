(function() {
  'use strict';

  var specFiles = null;
  var baseUrl = '';
  var requirejsCallback = null;

  // if invoked in karma-runner environment
  if (typeof window !== 'undefined' && window.__karma__ !== undefined) {
    // Karma serves files from '/base'
    baseUrl = 'base';
    requirejsCallback = window.__karma__.start;

    // Looking for *_spec.js files
    specFiles = [];
    for (var file in window.__karma__.files) {
      if (window.__karma__.files.hasOwnProperty(file)) {
        if (/_spec\.js$/.test(file)) {
          specFiles.push(file);
        }
      }
    }
  }

  requirejs.config({
    baseUrl: baseUrl,
    paths: {
      'd3'         : 'bower_components/d3/d3',
      'chai'       : 'node_modules/chai/chai',
      'sinon'      : 'node_modules/sinon/pkg/sinon/sinon',
      'underscore' : 'bower_components/underscore/underscore'
    },

    // ask Require.js to load these files (all our tests)
    deps : specFiles,

    callback : requirejsCallback
  });
}());