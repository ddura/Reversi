package com.christiancantrell.controls
{
	import com.christiancantrell.data.ReversiGameModel;
	
	import flash.events.Event;
	
	public class AbstractReversiGameControl implements IReversiGameControl
	{
		protected static const SO_KEY:String = "com.christiancantrell.reversi";
		protected static const HISTORY_KEY:String = "history";
		protected static const PLAYER_MODE_KEY:String = "playerMode";
		protected static const COMPUTER_COLOR_KEY:String = "computerColor";		
		
		protected var gameModel:ReversiGameModel;
		protected var history:Array;
		
		public function AbstractReversiGameControl( gameModel:ReversiGameModel )
		{
		}
		
		public function startNewGame():void
		{
			gameModel.resetGame();
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