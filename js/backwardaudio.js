window.BackwardAudio = window.BackwardAudio || {};
BackwardAudio.elemId = "audio_streaming_swf";
BackwardAudio.obj = undefined;
BackwardAudio.log = function(s){
	console.log("[AUDIO-STREAMING-JS] " + s);
}

BackwardAudio.warn = function(s){
	console.warn("[AUDIO-STREAMING-JS] " + s);
}
	
BackwardAudio.error = function(s){
	console.error("[AUDIO-STREAMING-JS] " + s);
}

/* override functions */
BackwardAudio.startedPublish = function(){ /* you can override */ }
BackwardAudio.stoppedPublish = function(){ /* you can override */ }
BackwardAudio.showSecuritySettings = function(){ /* you can override */ }
BackwardAudio.hideSecuritySettings = function(){ /* you can override */ }

BackwardAudio.activityLevel = function(lvl){
	console.log("audio lvl " + lvl);
}

BackwardAudio.flash = function(){
	if(!BackwardAudio.obj){
		BackwardAudio.obj = document.getElementById(BackwardAudio.elemId);
		if(!BackwardAudio.obj){
			BackwardAudio.error("Element '" + BackwardAudio.elemId + "' not found");
		}
		BackwardAudio.log("Init");
	}else if(!BackwardAudio.obj.vjs_activate){
		// try again
		BackwardAudio.obj = document.getElementById(BackwardAudio.elemId);
		if(!BackwardAudio.obj){
			BackwardAudio.error("Element '" + BackwardAudio.elemId + "' not found");
		}
		BackwardAudio.log("reinit");
	}
	return BackwardAudio.obj;
};
	
BackwardAudio.activate = function(rtmpUrl, codec){

	var f = BackwardAudio.flash();
	if(!f) return;
	if(f.vjs_activate){
		var is_private = BackwardAudio.private.is() || false;
		f.vjs_activate(rtmpUrl, is_private, codec);
	}else{
		BackwardAudio.error("Function vjs_activate not found");
		BackwardAudio.obj = undefined;
	}
};

BackwardAudio.support = function(){
	var f = BackwardAudio.flash();
	if(!f) return;
	if(f.vjs_support)
		return f.vjs_support();
	else{
		BackwardAudio.error("Function vjs_support not found");
		BackwardAudio.obj = undefined;
	}
};

BackwardAudio.status = function(){
	var f = BackwardAudio.flash();
	if(!f) return;
	if(f.vjs_status)
		return f.vjs_status();
	else{
		BackwardAudio.error("Function vjs_status not found");
		BackwardAudio.obj = undefined;
	}
};
	
BackwardAudio.deactivate = function(){
	var f = BackwardAudio.flash();
	if(!f) return;
	if(f.vjs_deactivate)
		f.vjs_deactivate();
	else{
		console.error("Function vjs_deactivate not found");
		BackwardAudio.obj = undefined;
	}
};

BackwardAudio.isActivated = function(){
	return (BackwardAudio.status() == "activated");
};

BackwardAudio.isDeactivated = function(){
	return (BackwardAudio.status() == "deactivated");
};

BackwardAudio.isTransitive = function(){
	return (BackwardAudio.status() == "transitive");
};

/* private mode opened */
BackwardAudio.private = {};
BackwardAudio.private.retry = function(isDone, next) {
    var current_trial = 0, max_retry = 50, interval = 10, is_timeout = false;
    var id = window.setInterval(
        function() {
            if (isDone()) {
                window.clearInterval(id);
                next(is_timeout);
            }
            if (current_trial++ > max_retry) {
                window.clearInterval(id);
                is_timeout = true;
                next(is_timeout);
            }
        },
        10
    );
}

BackwardAudio.private.isIE10OrLater = function(user_agent) {
    var ua = user_agent.toLowerCase();
    if (ua.indexOf('msie') === 0 && ua.indexOf('trident') === 0) {
        return false;
    }
    var match = /(?:msie|rv:)\s?([\d\.]+)/.exec(ua);
    if (match && parseInt(match[1], 10) >= 10) {
        return true;
    }
    return false;
}

BackwardAudio.private.detectPrivateMode = function(callback) {
    var is_private;

    if (window.webkitRequestFileSystem) {
        window.webkitRequestFileSystem(
            window.TEMPORARY, 1,
            function() {
                is_private = false;
            },
            function(e) {
                console.log(e);
                is_private = true;
            }
        );
    } else if (window.indexedDB && /Firefox/.test(window.navigator.userAgent)) {
        var db;
        try {
            db = window.indexedDB.open('test');
        } catch(e) {
            is_private = true;
        }

        if (typeof is_private === 'undefined') {
            BackwardAudio.private.retry(
                function isDone() {
                    return db.readyState === 'done' ? true : false;
                },
                function next(is_timeout) {
                    if (!is_timeout) {
                        is_private = db.result ? false : true;
                    }
                }
            );
        }
    } else if (isIE10OrLater(window.navigator.userAgent)) {
        is_private = false;
        try {
            if (!window.indexedDB) {
                is_private = true;
            }                 
        } catch (e) {
            is_private = true;
        }
    } else if (window.localStorage && /Safari/.test(window.navigator.userAgent)) {
        try {
            window.localStorage.setItem('test', 1);
        } catch(e) {
            is_private = true;
        }

        if (typeof is_private === 'undefined') {
            is_private = false;
            window.localStorage.removeItem('test');
        }
    }

    BackwardAudio.private.retry(
        function isDone() {
			return typeof is_private !== 'undefined' ? true : false;
        },
        function next(is_timeout) {
            callback(is_private);
        }
    );
}

BackwardAudio.private.is = function(){
	if(typeof BackwardAudio.private.is_ === 'undefined'){
		console.error('[BackwardAudio.private] cannot detect');
	}
	return BackwardAudio.private.is_;
}

BackwardAudio.private.detectPrivateMode(
	function(is_private) {
		BackwardAudio.private.is_ = is_private;
		
		if(typeof is_private === 'undefined'){
			console.error('[BackwardAudio.private] cannot detect');
		}else{
			BackwardAudio.private.is_ = is_private;
			console.log(is_private ? '[BackwardAudio.private] private' : '[BackwardAudio.private] not private')
		}
	}
);
