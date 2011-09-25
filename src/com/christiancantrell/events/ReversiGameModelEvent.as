package com.christiancantrell.events
{
	import flash.events.Event;
	
	public class ReversiGameModelEvent extends Event
	{
		public static const STONES_TURNED:String = "stonesTurned";
		public static const TURN_CHANGE:String = "turnChange";
		public static const SCORE_CHANGE:String = "scoreChange";
		public static const GAME_END:String = "gameEnd";
		
		public var turnedStones:Array;
		public var turnX:uint;
		public var turnY:uint;
		
		public function ReversiGameModelEvent( type:String, turnedStones:Array = null, turnX:uint = 0, turnY:uint = 0 )
		{
			super( type, false, false );

			this.turnedStones = turnedStones;
			this.turnX = turnX;
			this.turnY = turnY;
		}
		
		override public function clone():Event
		{
			return new ReversiGameModelEvent( type, turnedStones, turnX, turnY );
		}
			
	}
}