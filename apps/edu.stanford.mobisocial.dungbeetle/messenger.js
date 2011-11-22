/*
 * Update types
 */

function StatusUpdate(data) {
    var thisUpdate = this;
    this.text = data.text;
    
    this.render = function() {
        return '<span>' + data.text + '</span>';
    }
}

function JoinNotificationUpdate(data) {
    var thisUpdate = this;
    
    this.render = function() {
        return '<span>I\'m here</span>';        
    }
}

function PictureUpdate(data) {
    var thisUpdate = this;
    this.data = data.data;
    
    
    this.render = function() {
        return '<img src="data:image/jpeg;base64,' + this.data + '"/>';
    }
}


function Messenger(feed) {
    var thisMessenger = this;
    
    this.feed = feed;
    this.init = function() {
        if (thisMessenger.feed) {
            $('h1').html(thisMessenger.feed.name);
        
            thisMessenger.feed.onNewMessage(thisMessenger.renderMessage);

            thisMessenger.feed.messages(function(result) {
                result.forEach(thisMessenger.renderMessage);
            });
        }
    }
    
    this.postStatus = function(form) {
        var obj = new Musubi.Obj({type: "status", data: {text: form.status.value}});
        thisMessenger.feed.post(obj);
        
        form.status.value = "";
    }
    
    this.createUpdateFromObj = function(obj) {
        if (obj.type == "status")
            return new StatusUpdate(obj.data);
        else if (obj.type == "join_notification")
            return new JoinNotificationUpdate(obj.data);
        else if (obj.type == "picture") {
            return new PictureUpdate(obj.data);
        }
    }

    this.renderMessage = function(msg) {
        var update = thisMessenger.createUpdateFromObj(msg.obj);
        
        var elem = $('<li class="message"></li>');
        elem.append('<div class="sender">' + msg.sender.name + '</div>');
        elem.append('<div class="contents">' + update.render() + '</div>');
        elem.append('<div class="date">' + msg.date + '</div>');
        $('#messages').prepend(elem);
    }
    
    this.init();
}

var messenger = null;
Musubi.onAppLaunch(function(feed) {
    messenger = new Messenger(feed);
});