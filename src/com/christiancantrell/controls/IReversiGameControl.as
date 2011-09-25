package com.christiancantrell.controls
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public interface IReversiGameControl extends IEventDispatcher
	{
		public function startNewGame():void;
		public function endCurrentGame():void;
		public function makeMove( player:String, x:int, y:int ):void;
		public function moveHistoryForward():void;
		public function moveHistoryBack():void;
		public function get historyLength():int;
	}
}