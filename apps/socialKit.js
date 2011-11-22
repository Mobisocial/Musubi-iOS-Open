SocialKit = {
};

Musubi = {
    platform: {
        _runCommand: function() {
            alert("Musubi.platform should be extended!");
        }
    },
    
    _runCommand: function(className, methodName, parameters, callback) {
        Musubi.platform._runCommand(className, methodName, parameters, callback);
    },
    
    _launchCallback: null,
    _launchApp: function(json) {
        Musubi.feed = new SocialKit.Feed(json);
        
        if (Musubi._launchCallback != null) {
            Musubi._launchCallback(Musubi.feed);
        }
    },
    
    _newMessage: function(msg) {
        // Pass on to Feed instance
        Musubi.feed._newMessage(msg);
    },

    feed: null,

    ready: function(callback) {
        Musubi._launchCallback = callback
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
};


/*
 * App class
 */

SocialKit.App = function(json) {
    this.appId = json.appId;
    this.feed = new SocialKit.Feed(json.feed);
    this.obj = new SocialKit.Obj(json.obj);
};

/*
 * User class
 */

SocialKit.User = function(json) {
    this.name = json.name;
    this.id = json.id;
};

SocialKit.User.prototype.toString = function() {
    return "<User: " + this.id + "," + this.name + ">";
};

/*
 * Feed class
 */

SocialKit.Feed = function(json) {
    this.name = json.name;
    this.uri = json.uri;
    this.session = json.session;
    this.key = json.key;
    this.members = [];

    for (var key in json.members) {
        this.members.push( new SocialKit.User(json.members[key]) );
    }
    
    this._messageListener = null;
};

// Message listener
SocialKit.Feed.prototype.onNewMessage = function(callback) {
    this._messageListener = callback;
};

SocialKit.Feed.prototype._newMessage = function(json) {
    if (this._messageListener != null) {
        var msg = new SocialKit.SignedMessage(json);
        this._messageListener(msg);
    }
};
    
// Message querying
SocialKit.Feed.prototype.messages = function(callback) {
    Musubi._runCommand("Feed", "messages", {feedName: this.session}, function(json) {
        // convert json messages to SignedMessage objects
        var msgs = [];
        for (var key in json) {
            var msg = new SocialKit.SignedMessage(json[key]);
            msgs.push(msg);
        }
        callback(msgs);
    });
};

// Message posting
SocialKit.Feed.prototype.post = function(obj) {
    Musubi._runCommand("Feed", "post", {feedName: this.session, obj: JSON.stringify(obj)});
};


/*
 * Obj class
 */

SocialKit.Obj = function(json) {
    this.type = json.type;
    this.data = json.data;
};

SocialKit.Obj.prototype.toString = function() {
    return "<Obj: " + this.type + ">";
};

/*
 * Message class
 */

SocialKit.Message = function() {
    this.obj = null;
    this.sender = null;
    this.recipients = [];
    this.appId = null;
    this.feedName = null;
    this.date = null;
    
    this.init(json);
};

SocialKit.Message.prototype.init = function(json) {
    this.obj = new SocialKit.Obj(json.obj);
    this.sender = new SocialKit.User(json.sender);
    this.recipients = [];
    
    for (var key in json.recipients) {
        this.members.push( new SocialKit.User(json.recipients[key]) );
    }
    
    this.appId = json.appId;
    this.feedName = json.feedName;
    this.date = new Date(parseInt(json.timestamp));
};

SocialKit.Message.prototype.toString = function() {
    return "<Message: " + this.obj.toString() + "," + this.sender.toString() + "," + this.appId + "," + this.feedName + "," + this.timestamp + ">";
};

/*
 * SignedMessage class
 */

SocialKit.SignedMessage = function(json) {
    this.hash = null;
    
    this.init(json);
};
SocialKit.SignedMessage.prototype = SocialKit.Message.prototype;

SocialKit.SignedMessage.prototype.superInit = SocialKit.SignedMessage.prototype.init;
SocialKit.SignedMessage.prototype.init = function(json) {
    this.superInit(json);
    this.hash = json.hash;
};