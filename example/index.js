
BackwardAudio.log = function(s){
	document.getElementById('streaming-log').innerHTML = s + "\n" + document.getElementById('streaming-log').innerHTML;
}

BackwardAudio.error = function(s){
	document.getElementById('streaming-log').innerHTML = s + "\n" + document.getElementById('streaming-log').innerHTML;
}

BackwardAudio.warn = function(s){
	document.getElementById('streaming-log').innerHTML = s + "\n" + document.getElementById('streaming-log').innerHTML;
}

BackwardAudio.startedPublish = function(){
	document.getElementById('streaming-log').innerHTML = "Publishing started\n" + document.getElementById('streaming-log').innerHTML;
}

BackwardAudio.stoppedPublish = function(){
	document.getElementById('streaming-log').innerHTML = "Publishing stopped\n" + document.getElementById('streaming-log').innerHTML;
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
