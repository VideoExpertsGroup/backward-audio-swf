
BackwardAudio.log = function(s){
	document.getElementById('streaming-log').innerHTML += s + "\n";
}

BackwardAudio.error = function(s){
	document.getElementById('streaming-log').innerHTML += s + "\n";
}

BackwardAudio.warn = function(s){
	document.getElementById('streaming-log').innerHTML += s + "\n";
}

BackwardAudio.startedPublish = function(){
	document.getElementById('streaming-log').innerHTML += "Publishing started\n";
}

BackwardAudio.stoppedPublish = function(){
	document.getElementById('streaming-log').innerHTML += "Publishing stopped\n";
}

BackwardAudio.activityLevel = function(lvl){
	var el = document.getElementById('audiolevel_value');
	if(lvl < 0) lvl = 0;
	var h = Math.floor((lvl/100)*140);
	el.style['height'] = h + "px";
	el.style['margin-top'] = (140-h)+ "px";
	
}

function adobe_start(){
	BackwardAudio.activate(document.getElementById('url').value, "PCMU");
}

function adobe_stop(){
	BackwardAudio.deactivate();
}
