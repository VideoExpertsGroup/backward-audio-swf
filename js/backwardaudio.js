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
		f.vjs_activate(rtmpUrl, codec);
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
