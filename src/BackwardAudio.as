package{

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.geom.Rectangle;
    import flash.system.Security;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.utils.ByteArray;
    import flash.utils.Timer;
    import flash.utils.setTimeout;
    import flash.events.EventDispatcher;
    import flash.events.NetStatusEvent;
    import flash.events.StatusEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.media.Video;
    import flash.media.Microphone;
    import flash.media.SoundTransform;
    import flash.media.SoundCodec;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.utils.ByteArray;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import flash.system.Security;
    import flash.system.SecurityPanel;
    import flash.external.ExternalInterface;

    [SWF(backgroundColor="#000000", frameRate="60", width="480", height="270")]
    public class BackwardAudio extends Sprite{

        public const VERSION:String = CONFIG::version;

        private var _nc:NetConnection;
		private var _ns:NetStream;
		private var _stageSizeTimer:Timer;

		public static const DEACTIVATED:String = "deactivated"; 
		public static const ACTIVATED:String = "activated"; 
		public static const TRANSITIVE:String = "transitive"; 

        private var _status:String = DEACTIVATED;
        private var _live_mic:Microphone = null;
        private var _soundTrans:SoundTransform = null;
        private var mRtmpConn:String = "";
        private var mRtmpStream:String = "";
        private var mCodec:String = "";
        private var mIsPrivate:Boolean = false;
        private var mShowedSecurityDialog:Boolean = false;
        private var _timerActivityLevel:Timer = null;
        private var mTimerPolingAllowChrome:Timer = null;
        
        public function BackwardAudio(){
			consoleLog("BackwardAudio init " + Security.sandboxType);

            Security.allowDomain("*");
            Security.allowInsecureDomain("*");
			
			if(!checkMicrophoneAllowedChrome()){
				consoleWarn("Microphone deny");
			}

            if (ExternalInterface.available){
				try{
					ExternalInterface.addCallback("vjs_support", onSupportCalled);
					ExternalInterface.addCallback("vjs_activate", onActivateCalled);
					ExternalInterface.addCallback("vjs_deactivate", onDeactivateCalled);
					ExternalInterface.addCallback("vjs_status", onStatusCalled);
					ExternalInterface.addCallback("vjs_getProperty", onGetPropertyCalled);
					ExternalInterface.addCallback("vjs_setProperty", onSetPropertyCalled);
				}catch(e:SecurityError){
					throw new SecurityError(e.message);
				}catch(e:Error){
					throw new Error(e.message);
				}
				finally{}
			}else{
				consoleError("ExternalInterface is not available");
			}
			
			var _ctxVersion:ContextMenuItem = new ContextMenuItem("BackwardAudio Flash Component v" + VERSION, false, false);
			var _ctxAbout:ContextMenuItem = new ContextMenuItem("Copyright © 2016 VXG, Inc.", false, false);
			var _ctxMenu:ContextMenu = new ContextMenu();
			_ctxMenu.hideBuiltInItems();
			_ctxMenu.customItems.push(_ctxVersion, _ctxAbout);
			this.contextMenu = _ctxMenu;
			_timerActivityLevel = new Timer(1000);
			_timerActivityLevel.addEventListener(TimerEvent.TIMER, onTickActivityLevel);
			_timerActivityLevel.start();
        }

		private function onTickActivityLevel(event:TimerEvent):void{
			if(_live_mic != null && _status == ACTIVATED){
				if(ExternalInterface.available){
					ExternalInterface.call("BackwardAudio.activityLevel", _live_mic.activityLevel);
				}
			}
		}

		public function get support():Boolean{
			return Microphone.isSupported;
		}

		private function consoleLog(s:String):void{
			if(ExternalInterface.available){
				ExternalInterface.call("BackwardAudio.log", "BackwardAudio log: " + s);
			}
		}
		
		private function consoleWarn(s:String):void{
			if(ExternalInterface.available){
				ExternalInterface.call("BackwardAudio.warn", "BackwardAudio warn: " + s);
			}
		}
		
		private function consoleError(s:String):void{
			if(ExternalInterface.available){
				ExternalInterface.call("BackwardAudio.error", "BackwardAudio error: " + s);
			}
		}

		private function startPublish():Boolean{
			if(status != ACTIVATED){
				nsClose();
				_ns = new NetStream(_nc);
				_ns.attachAudio(_live_mic);
				_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler);
				_ns.publish(mRtmpStream);
				return true;
			}
			return false;
		}

		private function onMicStatus(evt:StatusEvent):void{
			switch (evt.code) {
				case "Microphone.Unmuted":
					consoleLog("User allow use microphone");
					if(_nc == null){
						initConn();
						break;
					}
					if(!startPublish())
						changeStatus(DEACTIVATED);
					break;
				case "Microphone.Muted":
					consoleError("User deny use microphone");
					changeStatus(TRANSITIVE);
					ncClose();
					changeStatus(DEACTIVATED);
					break;
				default:
					consoleError(" evt.code " + evt.code);
					break;
			}
		}

		private function nsClose(): void{
			if(_ns != null){
				try{
					_ns.close();
				}catch(err:Error){
				}
				_ns = null;
			}
		}

		private function ncClose(): void{
			nsClose();
			if(_nc != null){
				try{
					_nc.close();
				}catch(err:Error){
				}
				_nc = null;
			}
		}

		private function changeStatus(newVal:String): void{
			if (_status != newVal){
				_status = newVal;
				consoleLog("Status: " + _status);
				if(_status == DEACTIVATED){
					ncClose();
					consoleLog("BackwardAudio publish stopped");
					callback("BackwardAudio.stoppedPublish");
				}
				if(_status == ACTIVATED){
					consoleLog("BackwardAudio publish started");
					callback("BackwardAudio.startedPublish");
				}
			}
		}

		private function configureMichrophone():void{
			if(_live_mic != null){
				if(mCodec == "NELLYMOSER"){
					_live_mic.codec = SoundCodec.NELLYMOSER;
				}else if(mCodec == "PCMA"){
					_live_mic.codec = SoundCodec.PCMA;
				}else if(mCodec == "PCMU"){
					_live_mic.codec = SoundCodec.PCMU;
				}else if(mCodec == "SPEEX"){
					_live_mic.codec = SoundCodec.SPEEX;
				}else{
					// default value
					_live_mic.codec = SoundCodec.SPEEX;
				}
				_live_mic.rate = 16;

				_live_mic.setSilenceLevel(0);
				_soundTrans = new SoundTransform();
				_soundTrans.volume = 6;
				_live_mic.soundTransform = _soundTrans;
			}
		}

		private function callback(event:String):void{
			if(ExternalInterface.available){
				ExternalInterface.call(event);
			}
		}
		
		private function isEmptyString(s:String):Boolean{
			if(s == null){
				return true;
			}else if (s == "" || s == " "){
				return true;
			}
			return false;
		}

		private function checkMicrophoneAllowedChrome():Boolean{
			var nCountEmptyNames:Number = 0;
			var nCountMicrophones:Number = Microphone.names.length;
			for(var i = 0; i < nCountMicrophones; i++){
				if(isEmptyString(Microphone.names[i])){
					nCountEmptyNames = nCountEmptyNames + 1;
				}
			}
			return nCountMicrophones > 0 && nCountEmptyNames < nCountMicrophones;
		}

		private function stopPolingAllowMicrophoneInChrome():void{
			consoleLog("stopPolingAllowMicrophoneInChrome");
			if(mTimerPolingAllowChrome != null){
				mTimerPolingAllowChrome.stop();
				mTimerPolingAllowChrome = null;
			}
		}

		private function startPolingAllowMicrophoneInChrome():void{
			stopPolingAllowMicrophoneInChrome();

			consoleLog("startPolingAllowMicrophoneInChrome");
			mTimerPolingAllowChrome = new Timer(1000);
			mTimerPolingAllowChrome.addEventListener(TimerEvent.TIMER, onPolingAllowMicrophoneInChrome);
			mTimerPolingAllowChrome.start();
		}
		
		private function onPolingAllowMicrophoneInChrome(event:TimerEvent):void{
			consoleLog("onPolingAllowMicrophoneInChrome");
			if(checkMicrophoneAllowedChrome()){
				_live_mic = Microphone.getEnhancedMicrophone();
				showSecuritySettings();
				stopPolingAllowMicrophoneInChrome();
			}
		}
		
		private function showSecuritySettings():void{
			consoleLog("Show security settings");
			if(!checkMicrophoneAllowedChrome()){
				consoleError("Not allowed in browser (chrome)");
				if(_live_mic != null){
					startPolingAllowMicrophoneInChrome();
					return;
				}else{
					consoleError("Microphone is empty");
				}
			}
			stopPolingAllowMicrophoneInChrome();
			
			if(mShowedSecurityDialog){
				consoleWarn("Already showed security dialog");
				return;
			}
			mShowedSecurityDialog = true;
			
			consoleLog("Show security settings adobe");
			if(mIsPrivate){
				// Security.showSettings(SecurityPanel.PRIVACY);
				Security.showSettings(SecurityPanel.MICROPHONE);
			}else{
				Security.showSettings(SecurityPanel.PRIVACY);
			}
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, showSecuritySettings_Closed);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, showSecuritySettings_Closed);
			callback("BackwardAudio.showSecuritySettings");
		}

		private function showSecuritySettings_Closed(e:Event):void{
			consoleLog("showSecuritySettings_Closed");
			if(mIsPrivate && _live_mic != null && _live_mic.muted == true){
				// mShowedSecurityDialog = false;
				consoleWarn("Reopen security settings");
				Security.showSettings(SecurityPanel.PRIVACY);
				Security.showSettings(SecurityPanel.MICROPHONE);
				// showSecuritySettings();
				return;
			}

			consoleLog("Hide security settings");
			callback("BackwardAudio.hideSecuritySettings");
			mShowedSecurityDialog = false;
			//REMOVE THE LISTENER ON FIRST TIME
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, showSecuritySettings_Closed);
			_live_mic.removeEventListener(StatusEvent.STATUS, onMicStatus);
			if(_live_mic != null && _live_mic.muted == true){
				changeStatus(DEACTIVATED);
			}else if(_live_mic == null){
				changeStatus(DEACTIVATED);
			}
		}
		
		private function onNetStatusHandler(e:NetStatusEvent):void{
            switch(e.info.code){
                case "NetConnection.Connect.Success":
					consoleLog("NetConnection.Connect.Success");
					if(_live_mic == null){
						consoleLog("Get microphone 2");
						_live_mic = Microphone.getEnhancedMicrophone();
						if(_live_mic == null){
							changeStatus(DEACTIVATED);
							return;
						}
						configureMichrophone();
						showSecuritySettings();
						_live_mic.addEventListener(StatusEvent.STATUS, onMicStatus);
					}else{
						if(_live_mic.muted == true){
							consoleError("Microphone access was denied");
							_live_mic = Microphone.getEnhancedMicrophone();
							if(_live_mic == null){
								changeStatus(DEACTIVATED);
								return;
							}
							showSecuritySettings();
							configureMichrophone();
							_live_mic.addEventListener(StatusEvent.STATUS, onMicStatus);
						}else{
							consoleLog("Microphone access was allowed");
							if(!startPublish()){
								changeStatus(DEACTIVATED);
							}
						}	
					}
                    break;
				case "NetStream.Publish.Start":
					consoleLog("starting publish");
					changeStatus(ACTIVATED);
					break;
                case "NetConnection.Connect.Failed":
                    consoleError("NetConnection.Connect.Failed");
                    ncClose();
                    changeStatus(DEACTIVATED);
                    break;
                default:
                    if(e.info.level == "error"){
						consoleError("failed " + e.info.description);
						changeStatus(DEACTIVATED);
                    }
                    break;
            }
        }

		private function initConn():void{
			if(_nc == null){
				changeStatus(TRANSITIVE);
				_nc = new NetConnection();
				_nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler);
				_nc.connect(mRtmpConn);
				consoleLog("url: " + mRtmpConn + "/" + mRtmpStream);
			}
		}

		public function activate(rtmpUrl:String, isPrivate:Boolean, codec:String):void{
			if(status == ACTIVATED || _status == TRANSITIVE)
				return; // already activated
			
			mIsPrivate = isPrivate;
			if(codec == null || codec == ""){
				mCodec = "SPEEX";
				consoleWarn ("Will be used default codec: SPEEX");
			}else{
				if(codec != "SPEEX" && codec != "NELLYMOSER" && codec != "PCMA" && codec != "PCMU"){
					consoleError("Codec must be one of them: SPEEX, NELLYMOSER, PCMA, PCMU (got: " + codec + ")");
					return;
				}
				mCodec = codec;
			}
			consoleLog("Will be used codec: " + mCodec);

			var arr:Array = rtmpUrl.split("/");

			if(arr.length != 5){
				consoleError("URL incorrect (expected: 'rtmp://host:port/application/stream')");
				changeStatus(DEACTIVATED);
				return;
			}

			if(arr[0] != "rtmp:"){
				consoleError("Expected rtmp protocol");
				changeStatus(DEACTIVATED);
				return;
			}

			mRtmpConn = arr[0] + "//" + arr[2] + "/" + arr[3];
			mRtmpStream = arr[4];

			if(mRtmpStream == ""){
				consoleError("Stream has not name");
				changeStatus(DEACTIVATED);
				return;
			}
			ncClose();
				
			if(_live_mic == null){
				consoleLog("Get microphone on activate");
				_live_mic = Microphone.getEnhancedMicrophone();
				_live_mic.addEventListener(StatusEvent.STATUS, onMicStatus);
				if(_live_mic == null){
					// TODO callback could not get mic
					changeStatus(DEACTIVATED);
					return;
				}
				configureMichrophone();
				showSecuritySettings();	
			}else if(_live_mic.muted == true){
				configureMichrophone();
				showSecuritySettings();
			}
			initConn();
		}

		public function deactivate():void{
			if(status == DEACTIVATED || status == TRANSITIVE)
				return; // already deactivated
			changeStatus(TRANSITIVE);
			changeStatus(DEACTIVATED);
		}
		
		public function get status():String{
			return _status;
		}

        /*private function onAddedToStage(e:Event):void{
            stage.addEventListener(MouseEvent.CLICK, onStageClick);
            stage.addEventListener(Event.RESIZE, onStageResize);
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            _stageSizeTimer.start();
        }*/

        /*private function onStageSizeTimerTick(e:TimerEvent):void{
            if(stage.stageWidth > 0 && stage.stageHeight > 0){
                _stageSizeTimer.stop();
                _stageSizeTimer.removeEventListener(TimerEvent.TIMER, onStageSizeTimerTick);
                init();
            }
        }*/

        /*private function onStageResize(e:Event):void{
            if(_app != null){
                _app.model.stageRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
                // _app.model.broadcastEvent(new VideoJSEvent(VideoJSEvent.STAGE_RESIZE, {}));
            }
        }*/

        private function onGetPropertyCalled(pPropertyName:String = ""):*{
            switch(pPropertyName){
                case "support":
                    // nothing
                case "currentSrc":
                    // nothing
                    break;
                case "networkState":
                    // nothing
                    break;
                case "readyState":
					// nothing
                    break;
            }
            return null;
        }

        private function onSetPropertyCalled(pPropertyName:String = "", pValue:* = null):void{
            switch(pPropertyName){
                case "nothing":
                    // nothing
                    break;
                default:
					consoleWarn("Property not found");
                    break;
            }
        }

        private function onSupportCalled():*{
          return this.support;
        }

		private function onActivateCalled(rtmpUrl:* = "", isPrivate:* = false, codec:* = ""):void{
            this.activate(String(rtmpUrl), Boolean(isPrivate), String(codec));
        }

        private function onDeactivateCalled():void{
            this.deactivate();
        }

		private function onStatusCalled():*{
          return _status;
        }

        private function onUncaughtError(e:Event):void{
            e.preventDefault();
        }

		/*private function onStageClick(e:MouseEvent):void{
			// TODO
        }*/
    }
}
