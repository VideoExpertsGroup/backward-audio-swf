
AudioStreaming.log = function(s){
	document.getElementById('streaming-log').innerHTML += s + "\n";
}

AudioStreaming.error = function(s){
	document.getElementById('streaming-log').innerHTML += s + "\n";
}

AudioStreaming.startedPublish = function(){
	document.getElementById('streaming-log').innerHTML += "Publishing started\n";
}

AudioStreaming.stoppedPublish = function(){
	document.getElementById('streaming-log').innerHTML += "Publishing stopped\n";
}

AudioStreaming.activityLevel = function(lvl){
	var el = document.getElementById('audiolevel_value');
	if(lvl < 0) lvl = 0;
	var h = Math.floor((lvl/100)*140);
	el.style['height'] = h + "px";
	el.style['margin-top'] = (140-h)+ "px";
	
}

function adobe_start(){
	AudioStreaming.activate(document.getElementById('url').value);
}

function adobe_stop(){
	AudioStreaming.deactivate();
}

// test html5

function html5_start(){
	navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;
	if (navigator.getUserMedia) {
		navigator.getUserMedia({ audio: true }, function(stream) {
			window.rec_thread =  new MediaRecorder(stream);
			window.rec_thread.ondataavailable = function(obj){ console.log("ondataavailable", obj); };

			var audio = document.querySelector('audio');
			console.log("stream: ", stream);
			stream.onactive = function(obj){ console.log("onactive: ", obj);}
			stream.onaddtrack = function(obj){console.log("onaddtrack: ", obj);}
			stream.oninactive = function(obj){console.log("oninactive: ", obj);}
			stream.onremovetrack = function(obj){console.log("onremovetrack: ", obj);}

			audio.srcObject = stream;
			audio.onloadedmetadata = function(e) {
				audio.play();
			};
		},function(err) {
			console.log("The following error occurred: " + err.name);
		});
	} else {
		console.log("getUserMedia not supported");
	}
}
