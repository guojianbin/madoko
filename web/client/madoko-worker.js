/*---------------------------------------------------------------------------
  Copyright 2013 Microsoft Corporation.
 
  This is free software; you can redistribute it and/or modify it under the
  terms of the Apache License, Version 2.0. A copy of the License can be
  found in the file "license.txt" at the root of this distribution.
---------------------------------------------------------------------------*/

importScripts("lib/require.js");

require.config({
  baseUrl: "lib",
});

var languages = ["javascript","cpp","css","xml","markdown","coffeescript","java"
                ,"haskell","go","fsharp","r","cs","scala"]
                .map(function(name){ return "languages/" + name; });

require(["../scripts/util","webmain","highlight.js"].concat(languages), function(util,madoko) 
{
  // remove duplicates
  function nub( xs ) {
    if (!xs || xs.length <= 0) return [];
    var seen = {};
    var ys = [];
    for(var i = 0; i < xs.length; i++) {
      if (!(seen["$" + xs[i]])) {
        seen["$" + xs[i]] = true;
        ys.push(xs[i]);
      }
    }
    return ys;
  }

  // split a string of files (one per line) into an array of files
  function fileList( files ) {
    if (!files) return [];
    return nub(files.split("\n").filter(function(s) { return (s != null && s !== ""); }))
  }

  self.addEventListener( "message", function(ev) {
    try {    
      var req = ev.data;
      if (req.files) {
        req.files.forEach( function(f) {
          madoko.writeTextFile(f.name,f.content);  
        });
      }

      var t0 = Date.now();            
      madoko.markdown(req.name,req.content,req.options, 
                       function(md,stdout,runOnServer,options1,filesRead,filesReferred) 
      {
        self.postMessage( {
          messageId  : req.messageId, // message id is required to call the right continuation
          content    : md,
          time       : (Date.now() - t0).toString(),
          options    : options1,
          runOnServer: runOnServer,
          message    : stdout,
          filesRead  : fileList(filesRead),         
          filesReferred: fileList(filesReferred)
        });
      });
    }
    catch(exn) {
      self.postMessage( {
        messageId: req.messageId,
        message  : exn.toString()
      });
    }
  });
});
