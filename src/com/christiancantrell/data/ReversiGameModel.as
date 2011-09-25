package com.christiancantrell.data
{
	import com.christiancantrell.ai.ReversiAI;
	import com.christiancantrell.events.ReversiGameModelEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.SharedObject;
	import flash.net.registerClassAlias;
	import flash.utils.Timer;
	
	[Event(name="stoneChanged", type="com.christiancantrell.events.ReversiGameModelEvent")]
	[Event(name="turnChange", type="com.christiancantrell.events.ReversiGameModelEvent")]
	[Event(name="scoreChange", type="com.christiancantrell.events.ReversiGameModelEvent")]
	[Event(name="historyIndexChange", type="com.christiancantrell.events.ReversiGameModelEvent")]
	[Event(name="statusChange", type="com.christiancantrell.events.ReversiGameModelEvent")]
	[Event(name="endGame", type="com.christiancantrell.events.ReversiGameModelEvent")]
	
	public class ReversiGameModel extends EventDispatcher
	{
		public static const WHITE:Boolean = true;
		public static const BLACK:Boolean = false;		
		public static const SINGLE_PLAYER_MODE:String = "singlePlayerMode";
		public static const TWO_PLAYER_MODE:String = "twoPlayerMode";
		
		public static const STATUS_PLAYING:String = "playing";
		public static const STATUS_BLACK_WIN:String = "blackWin";
		public static const STATUS_WHITE_WIN:String = "whiteWin";
		public static const STATUS_DRAW:String = "draw";
		
		private static const SO_KEY:String = "com.christiancantrell.reversi";
		private static const HISTORY_KEY:String = "history";
		private static const PLAYER_MODE_KEY:String = "playerMode";
		private static const COMPUTER_COLOR_KEY:String = "computerColor";
		
		public var blackScore:uint;
		public var whiteScore:uint;
		public var history:Array;
		public var historyIndex:int;
		public var stones:Array;
		public var currentTurn:Boolean;
		public var gameStatus:String;
		public var playerMode:String;
		
		public var reversiAI:ReversiAI;
		public var networkMode:Boolean;
		public var netConnection:NetConnection;
		public var netGroup:NetGroup;
		
		private var so:SharedObject;

		public function ReversiGameModel()
		{
			super();
			
			registerClassAlias("com.christiancantrell.data.HistoryEntry", HistoryEntry);
			
			this.reversiAI = new ReversiAI( this );
			this.reversiAI.computerColor = WHITE;

			this.so = SharedObject.getLocal(SO_KEY);
			this.playerMode = SINGLE_PLAYER_MODE;
			
			if (!this.retrievePersistedGame()) this.resetGame();
 		}
		
		private function retrievePersistedGame():Boolean
		{
			var oldGame:Array = this.so.data[HISTORY_KEY] as Array;
			if (oldGame == null) return false;
			this.history = oldGame;
			var lastEntry:HistoryEntry;
			for (var i:uint = this.history.length; i >= 0; --i)
			{
				if (this.history[i] != null)
				{
					lastEntry = this.history[i] as HistoryEntry;
					this.historyIndex = i;
					break;
				}
			}
			this.currentTurn = lastEntry.turn;
			this.stones = this.deepCopyStoneArray(lastEntry.board);
			this.playerMode = this.so.data[PLAYER_MODE_KEY];
			if (this.playerMode == SINGLE_PLAYER_MODE)
			{
				this.reversiAI.computerColor = this.so.data[COMPUTER_COLOR_KEY];
			}
			this.calculateScore();
			return true;
		}		

		public function calculateScore():void
		{
			var black:uint = 0;
			var white:uint = 0;
			for (var x:uint = 0; x < this.stones.length; ++x)
			{
				for (var y:uint = 0; y < this.stones[x].length; ++y)
				{
					if (this.stones[x][y] == null)
					{
						continue;
					}
					else if (this.stones[x][y] == ReversiGameModel.WHITE)
					{
						++white;
					}
					else
					{
						++black;
					}
				}
			}
			this.blackScore = black;
			this.whiteScore = white;
		}		
		
		public function isNextMovePossible(player:Boolean):Boolean
		{
			for (var x:uint = 0; x < 8; ++x)
			{
				for (var y:uint = 0; y < 8; ++y)
				{
					if (this.stones[x][y] != null) continue;
					if (this.findCaptures(player, x, y, false) > 0) return true;
				}
			}
			return false;
		}		
		
		public function saveHistory():void
		{
			++this.historyIndex;
			var historyEntry:HistoryEntry = new HistoryEntry();
			historyEntry.board = this.deepCopyStoneArray(this.stones);
			historyEntry.turn = this.currentTurn;
			this.history[this.historyIndex] = historyEntry;
			for (var i:uint = this.historyIndex + 1; i < 64; ++i)
			{
				this.history[i] = null;
			}
			
			persistData();
		}
		
		private function persistData():void
		{
			this.so.data[HISTORY_KEY] = this.history;
			this.so.data[PLAYER_MODE_KEY] = this.playerMode;
			this.so.data[COMPUTER_COLOR_KEY] = this.reversiAI.computerColor;
			this.so.flush();
		}
		
		public function deletePersistentData():void
		{
			this.so.data[HISTORY_KEY] = null;
			this.so.data[PLAYER_MODE_KEY] = null;
			this.so.data[COMPUTER_COLOR_KEY] = null;
			this.so.flush();
		}		
		
		public function resetGame():void
		{
			this.history = new Array(60);
			this.historyIndex = -1;
			this.currentTurn = BLACK;  // Black always starts
			this.initStones();
			this.blackScore = 2;
			this.whiteScore = 2;
			
			persistData();
		}		
		
		public function makeMove(x:uint, y:uint):void
		{
			if (stones[x][y] != null || // There is already a stone here.
				findCaptures(currentTurn, x, y, true) == 0 ) // Not a valid move.
			{
				return;	
			}
			
			stones[x][y] = currentTurn;
			if ( networkMode )
			{
				var message:Object = new Object();
				message.type = "move";
				message.x = x;
				message.y = y;
				message.sender = this.netGroup.convertPeerIDToGroupAddress(this.netConnection.nearID);
				this.sendNetworkMessage(message);
			}

			dispatchEvent( new ReversiGameModelEvent( ReversiGameModelEvent.TURN_CHANGE, null, x, y ) )
		}		
		
		private var computerWaitTimer:Timer;
		private const COMPUTER_WAIT_TIME:uint = 1000; // milliseconds
		public function makeComputerMove():void
		{
			
			var computerGo:Function = function():void
			{
//				if (!stoneEffectTimer.running)
//				{
					computerWaitTimer.stop();
					computerWaitTimer.removeEventListener(TimerEvent.TIMER, computerGo);
					reversiAI.calculateMove();
//				}
			};
			if( !computerWaitTimer )
				computerWaitTimer = new Timer( COMPUTER_WAIT_TIME );
			this.computerWaitTimer.addEventListener(TimerEvent.TIMER, computerGo);
			this.computerWaitTimer.start();
		}		
		
		private function initStones():void
		{
			this.stones = new Array(8);
			for (var i:uint = 0; i < 8; ++i)
			{
				this.stones[i] = new Array(8);
			}
			this.stones[3][3] = WHITE;
			this.stones[4][4] = WHITE;
			this.stones[4][3] = BLACK;
			this.stones[3][4] = BLACK;
			this.saveHistory();
		}		
		
		public function findCaptures(turn:Boolean, x:uint, y:uint, turnStones:Boolean, stones:Array = null):uint
		{
			stones = (stones == null) ? this.stones : stones;
			if (stones[x][y] != null) return 0;
			var topLeft:uint     = this.walkPath(turn, x, y, -1, -1, turnStones, stones); // top left
			var top:uint         = this.walkPath(turn, x, y,  0, -1, turnStones, stones); // top
			var topRight:uint    = this.walkPath(turn, x, y,  1, -1, turnStones, stones); // top right
			var right:uint       = this.walkPath(turn, x, y,  1,  0, turnStones, stones); // right
			var bottomRight:uint = this.walkPath(turn, x, y,  1,  1, turnStones, stones); // bottom right
			var bottom:uint      = this.walkPath(turn, x, y,  0,  1, turnStones, stones); // bottom
			var bottomLeft:uint  = this.walkPath(turn, x, y, -1, +1, turnStones, stones); // bottom left
			var left:uint        = this.walkPath(turn, x, y, -1,  0, turnStones, stones); // left
			return (topLeft + top + topRight + right + bottomRight + bottom + bottomLeft + left);
		}				
		
		private function walkPath(turn:Boolean, x:uint, y:uint, xFactor:int, yFactor:int, turnStones:Boolean, stones:Array):uint
		{
			// Are we in bounds?
			if (x + xFactor > 7 || x + xFactor < 0 || y + yFactor > 7 || y + yFactor < 0)
			{
				return 0;
			}
			
			// Is the next squre empty?
			if (stones[x + xFactor][y + yFactor] == null)
			{
				return 0;
			}
			
			var nextStone:Boolean = stones[x + xFactor][y + yFactor];
			
			// Is the next stone the wrong color?
			if (nextStone != !turn)
			{
				return 0;
			}
			
			// Find the next piece of the same color
			var tmpX:int = x, tmpY:int = y;
			var stoneCount:uint = 0;
			while (true)
			{
				++stoneCount;
				tmpX = tmpX + xFactor;
				tmpY = tmpY + yFactor;
				if (tmpX < 0 || tmpY < 0 || tmpX > 7 || tmpY > 7 || stones[tmpX][tmpY] == null) // Not enclosed
				{
					return 0;
				}
				nextStone = this.stones[tmpX][tmpY];
				if (nextStone == turn) // Capture!
				{
					if (turnStones) this.turnStones(turn, x, y, tmpX, tmpY, xFactor, yFactor, stones);
					return stoneCount - 1;
				}
			}
			return 0;
		}			
		
		private function turnStones(turn:Boolean, fromX:uint, fromY:uint, toX:uint, toY:uint, xFactor:uint, yFactor:uint, stones:Array):void
		{
			var nextX:uint = fromX, nextY:uint = fromY;
			var stonesToTurn:Array = new Array();
			while (true)
			{
				nextX = nextX + xFactor;
				nextY = nextY + yFactor;
				stones[nextX][nextY] = turn;
				if (stones == this.stones)
				{
					if (toX != nextX || toY != nextY)
					{
						stonesToTurn.push({turn:turn, x:nextX, y:nextY});
					}
				}
				if (nextX == toX && nextY == toY)
				{
//FIX					this.playStoneEffects(stonesToTurn);
					dispatchEvent( new ReversiGameModelEvent( ReversiGameModelEvent.STONES_TURNED, stonesToTurn ) );
					break;
				}
			}
		}		
		
		public function deepCopyStoneArray(stoneArray:Array):Array
		{
			var newStones:Array = new Array(8);
			for (var x:uint = 0; x < 8; ++x)
			{
				newStones[x] = new Array(8);
				for (var y:uint = 0; y < 8; ++y)
				{
					if (stoneArray[x][y] != null) newStones[x][y] = stoneArray[x][y];
				}
			}
			return newStones;
		}		
		
		public function cancelNetworkPlay():void
		{
			if (this.netGroup != null)
			{
				this.netGroup.close();
				this.netGroup = null;
			}
			if (this.netConnection != null && this.netConnection.connected)
			{
				this.netConnection.close();
				this.netConnection = null;
			}
			this.networkMode = false;
		}		
		
		public function startNetworkPlay():void
		{
			this.networkMode = true;
			this.netConnection = new NetConnection();
			this.netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			this.netConnection.connect("rtmfp:");			
		}
		
		private function onNetStatus(e:NetStatusEvent):void
		{
			switch(e.info.code)
			{
				case "NetConnection.Connect.Success":
					this.setUpGroup();
					break;
				case "NetGroup.Connect.Success":
					// NetGroup successfully set up.
					break;
				case "NetGroup.Neighbor.Connect":
/*					var networkAlert:Alert = this.getCurrentAlert();
					if (networkAlert != null) networkAlert.close();
					var newAlert:Alert = new Alert(this.stage, this.ppi);
					newAlert.addEventListener(AlertEvent.ALERT_CLICKED, onNetworkColorChosen);
					newAlert.show("Choose a Color",
						"Choose your color. Remember, " + BLACK_COLOR_NAME + " always goes first.",
						[WHITE_COLOR_NAME, BLACK_COLOR_NAME, CANCEL_STRING]);*/
					break;
				case "NetGroup.Posting.Notify":
					var message:Object = e.info.message;
					if (message.type == "move")
					{
						this.makeMove(message.x, message.y);
					}
					else if (message.type == "setup")
					{
/*						var alert:Alert = this.getCurrentAlert();
						if (alert != null) alert.close();*/
						this.setupNetworkGame(message.opponentColor);
					}
					else if (message.type == "history")
					{
						if (message.direction == "back")
						{
							moveHistoryBack( false );
						}
						else if (message.direction == "next")
						{
							moveHistoryForward( false );
						}
					}
					break;
			}
		}
		
		public function sendNetworkMessage(message:Object):void
		{
			if (!this.networkMode) return;
			if (this.netConnection != null && this.netConnection.connected && this.netGroup != null && this.netGroup.neighborCount > 0)
			{
				message.time = new Date().time;
				this.netGroup.post(message);
			}
		}
		
		public function setupNetworkGame(computerColorString:String):void
		{
			playerMode = ReversiGameModel.SINGLE_PLAYER_MODE;
			reversiAI.computerColor = (computerColorString == Reversi.BLACK_COLOR_NAME) ? ReversiGameModel.BLACK : ReversiGameModel.WHITE;
			resetGame();
		}		
		
		// TBD: IP address???
		// TBD: Alert if peer is lost
		private function setUpGroup():void
		{
			var groupspec:GroupSpecifier = new GroupSpecifier("iReverse");
			groupspec.postingEnabled = true;
			groupspec.ipMulticastMemberUpdatesEnabled = true;
			groupspec.addIPMulticastAddress("225.225.0.1:30000");
			this.netGroup = new NetGroup(this.netConnection, groupspec.groupspecWithAuthorizations());
			this.netGroup.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}		
		
		public function moveHistoryForward( propogateOnNetwork:Boolean = true ):void
		{
			if (history[historyIndex+1] == null) return;
			++historyIndex;
			var historyEntry:HistoryEntry = history[historyIndex] as HistoryEntry;
			stones = deepCopyStoneArray(historyEntry.board);
			currentTurn = historyEntry.turn;
			
			if( propogateOnNetwork )
			{
				var message:Object = new Object();
				message.type = "history";
				message.direction = "next";
				this.sendNetworkMessage(message);
			}
		}
		
		public function moveHistoryBack( propogateOnNetwork:Boolean = true ):void
		{
			if (historyIndex == 0) return;
			--historyIndex;
			var historyEntry:HistoryEntry = history[historyIndex] as HistoryEntry;
			stones = deepCopyStoneArray(historyEntry.board);
			currentTurn = historyEntry.turn;
						
			if (propogateOnNetwork)
			{
				var message:Object = new Object();
				message.type = "history";
				message.direction = "back";
				this.sendNetworkMessage(message);
			}
		}		
		
	}
}