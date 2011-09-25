package com.christiancantrell.controls
{
	import flash.events.Event;
	
	public class TwoPlayerReversiGameControl implements IReversiGameControl
	{
		public function TwoPlayerReversiGameControl()
		{
		}
		
		public function startNewGame():void
		{
		}
		
		public function endCurrentGame():void
		{
		}
		
		public function makeMove(player:String, x:int, y:int):void
		{
		}
		
		public function moveHistoryForward():void
		{
		}
		
		public function moveHistoryBack():void
		{
		}
		
		public function get historyLength():int
		{
			return 0;
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return false;
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return false;
		}
		
		public function willTrigger(type:String):Boolean
		{
			return false;
		}
	}
}