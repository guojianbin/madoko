/*---------------------------------------------------------------------------
  Copyright 2013 Microsoft Corporation.
 
  This is free software; you can redistribute it and/or modify it under the
  terms of the Apache License, Version 2.0. A copy of the License can be
  found in the file "license.txt" at the root of this distribution.
---------------------------------------------------------------------------*/

define(["../scripts/promise","../scripts/util"], function(Promise,Util) {

function createAt(folder) {
  return Promise.resolved( new LocalRemote(folder) );
}

function unpersist(obj) {
  return new LocalRemote(obj ? obj.folder : "");
}

function type() {
  return "local";
}


function logo() {
  return "icon-local.png";
}


var LocalRemote = (function() {
  function LocalRemote(folder) {
    var self = this;
    self.folder = folder || "";    
  }

  LocalRemote.prototype.createNewAt = function(folder) {
    return createAt(folder);
  }

  LocalRemote.prototype.type = function() {
    return type();
  }

  LocalRemote.prototype.logo = function() {
    return logo();
  }

  LocalRemote.prototype.readonly = false;
  LocalRemote.prototype.canSync  = false;
  LocalRemote.prototype.needSignin = false;
  
  LocalRemote.prototype.getFolder = function() {
    var self = this;
    return self.folder;
  }

  LocalRemote.prototype.getDisplayFolder = function() {
    var self = this;
    return self.getFolder();
  }

  LocalRemote.prototype.persist = function() {
    var self = this;
    return { folder: self.folder };
  }

  LocalRemote.prototype.fullPath = function(fname) {
    var self = this;
    return Util.combine(self.folder,fname);
  }

  LocalRemote.prototype.connect = function() {
    return Promise.resolved(0);
  }

  LocalRemote.prototype.login = function() {
    return Promise.resolved();
  }

  LocalRemote.prototype.logout = function(force) {
    return Promise.resolved();
  }

  LocalRemote.prototype.getUserName = function() {
    return Promise.resolved("");
  }

  LocalRemote.prototype.pushFile = function( fpath, content ) {
    return Promise.rejected( new Error("Not connected to cloud storage: cannot store files") );
  }

  LocalRemote.prototype.pullFile = function( fpath, binary ) {
    var self = this;
    return Promise.rejected( new Error("Not connected to cloud storage: unable to read: " + fpath) );
  }

  LocalRemote.prototype.getRemoteTime = function( fpath ) {
    return Promise.resolved(null);
  }

  LocalRemote.prototype.createSubFolder = function( path ) {
    return Promise.resolved({folder: path, created: true });
  }

  LocalRemote.prototype.listing = function( fpath ) {
    return Promise.resolved([]);
  }

  LocalRemote.prototype.getShareUrl = function(fname) {
    return Promise.resolved(null);
  }

  return LocalRemote;
})();


return {
  createAt  : createAt,
  unpersist : unpersist,
  type      : type,
  logo      : logo,
  LocalRemote: LocalRemote,
}

});