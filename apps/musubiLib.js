Musubi = {
    platform: {
        _runCommand: function() {
            alert("Musubi.platform should be extended!");
        }
    },
    
    _runCommand: function(className, methodName, parameters, callback) {
        Musubi.platform._runCommand(className, methodName, parameters, callback);
    },
    
    _feed: null,
    _launchCallback: null,
    
    _launchApp: function(json) {
        Musubi._feed = new Musubi.Feed(json);
        
        if (Musubi._launchCallback != null) {
            Musubi._launchCallback(Musubi._feed);
        }
    },
    
    onAppLaunch: function(callback) {
        Musubi._launchCallback = callback
    },
    
    _newMessage: function(msg) {
        // Pass on to responsible Feed instance
        Musubi._feed._newMessage(msg);
    }
};

/*
 * iOS platform interface
 */
Musubi.platform = {
    _commandCallbacks: [],
    
    _runCommand: function(className, methodName, parameters, callback) {
        if (typeof callback == "undefined")
            callback = function() {};
        
        Musubi.platform._commandCallbacks.push(callback);
        
        var cmdUrl = "musubi://" + className + "." + methodName + "?";
        for (var key in parameters) {
            cmdUrl += encodeURIComponent(key) + "=" + encodeURIComponent(parameters[key]) + "&";
        }
        
        window.location = cmdUrl;
    },
    
    _commandResult: function(result) {
        var cb = Musubi.platform._commandCallbacks[0];
        delete Musubi.platform._commandCallbacks[0];
        if (cb != null) {
            cb(result);
        }
    }
}


/*
 * App class
 */

Musubi.App = function(appId, feed) {
    this.appId = appId;
    this.feed = feed;
};

/*
 * User class
 */

Musubi.User = function(json) {
    this.name = json.name;
    this.id = json.id;
};

Musubi.User.prototype.toString = function() {
    return "<User: " + this.id + "," + this.name + ">";
};

/*
 * Feed class
 */

Musubi.Feed = function(json) {
    this.name = json.name;
    this.uri = json.uri;
    this.session = json.session;
    this.key = json.key;
    this.members = [];

    for (var key in json.members) {
        this.members.push( new Musubi.User(json.members[key]) );
    }
    
    this._messageListener = null;
};

// Message listener
Musubi.Feed.prototype.onNewMessage = function(callback) {
    this._messageListener = callback;
};

Musubi.Feed.prototype._newMessage = function(json) {
    if (this._messageListener != null) {
        var msg = new Musubi.SignedMessage(json);
        this._messageListener(msg);
    }
};
    
// Message querying
Musubi.Feed.prototype.messages = function(callback) {
    Musubi._runCommand("Feed", "messages", {feedName: this.session}, function(json) {
        // convert json messages to SignedMessage objects
        var msgs = [];
        for (var key in json) {
            var msg = new Musubi.SignedMessage(json[key]);
            msgs.push(msg);
        }
        callback(msgs);
    });
};

// Message posting
Musubi.Feed.prototype.post = function(obj) {
    Musubi._runCommand("Feed", "post", {feedName: this.session, obj: JSON.stringify(obj)});
};


/*
 * Obj class
 */

Musubi.Obj = function(json) {
    this.type = json.type;
    this.data = json.data;
};

Musubi.Obj.prototype.toString = function() {
    return "<Obj: " + this.type + ">";
};

/*
 * Message class
 */

Musubi.Message = function() {
    this.obj = null;
    this.sender = null;
    this.recipients = [];
    this.appId = null;
    this.feedName = null;
    this.date = null;
    
    this.init(json);
};

Musubi.Message.prototype.init = function(json) {
    this.obj = new Musubi.Obj(json.obj);
    this.sender = new Musubi.User(json.sender);
    this.recipients = [];
    
    for (var key in json.recipients) {
        this.members.push( new Musubi.User(json.recipients[key]) );
    }
    
    this.appId = json.appId;
    this.feedName = json.feedName;
    this.date = new Date(parseInt(json.timestamp));
};

Musubi.Message.prototype.toString = function() {
    return "<Message: " + this.obj.toString() + "," + this.sender.toString() + "," + this.appId + "," + this.feedName + "," + this.timestamp + ">";
};

/*
 * SignedMessage class
 */

Musubi.SignedMessage = function(json) {
    this.hash = null;
    
    this.init(json);
};
Musubi.SignedMessage.prototype = Musubi.Message.prototype;

Musubi.SignedMessage.prototype.superInit = Musubi.SignedMessage.prototype.init;
Musubi.SignedMessage.prototype.init = function(json) {
    this.superInit(json);
    this.hash = json.hash;
};