package com.christiancantrell.ai
{
	import com.christiancantrell.data.ReversiGameModel;

	public class ReversiAI
	{
		public function ReversiAI( model:ReversiGameModel )
		{
			this.gameModel = model;
		}
		
		////  Simple triage-based AI. Opt for the best moves first, and the worst moves last. ////
		
		private const TOP_LEFT_CORNER:Array     = [0,0];
		private const TOP_RIGHT_CORNER:Array    = [7,0];
		private const BOTTOM_RIGHT_CORNER:Array = [7,7];
		private const BOTTOM_LEFT_CORNER:Array  = [0,7];
		
		private const TOP_LEFT_X:Array     = [1,1];
		private const TOP_RIGHT_X:Array    = [6,1];
		private const BOTTOM_RIGHT_X:Array = [6,6];
		private const BOTTOM_LEFT_X:Array  = [1,6];
		
		private const TOP_TOP_LEFT:Array        = [1,0];
		private const TOP_BOTTOM_LEFT:Array     = [0,1];
		private const TOP_TOP_RIGHT:Array       = [6,0];
		private const TOP_BOTTOM_RIGHT:Array    = [7,1];
		private const BOTTOM_TOP_RIGHT:Array    = [7,6];
		private const BOTTOM_BOTTOM_RIGHT:Array = [6,7];
		private const BOTTOM_TOP_LEFT:Array     = [0,6];
		private const BOTTOM_BOTTOM_LEFT:Array  = [1,7];
		
		public var computerColor:Boolean;
		
		private var gameModel:ReversiGameModel;
		
		public function calculateMove():void
		{
			// Try to capture a corner...
			if (this.gameModel.findCaptures(this.computerColor, TOP_LEFT_CORNER[0],     TOP_LEFT_CORNER[1],     false) > 0) {this.onFinishComputerMove(TOP_LEFT_CORNER[0],     TOP_LEFT_CORNER[1]);     return;}
			if (this.gameModel.findCaptures(this.computerColor, TOP_RIGHT_CORNER[0],    TOP_RIGHT_CORNER[1],    false) > 0) {this.onFinishComputerMove(TOP_RIGHT_CORNER[0],    TOP_RIGHT_CORNER[1]);    return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1], false) > 0) {this.onFinishComputerMove(BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_LEFT_CORNER[0],  BOTTOM_LEFT_CORNER[1],  false) > 0) {this.onFinishComputerMove(BOTTOM_LEFT_CORNER[0],  BOTTOM_LEFT_CORNER[1]);  return;}
			
			// If you already own a corner, try to build off it...
			if (this.gameModel.stones[TOP_LEFT_CORNER[0]][TOP_LEFT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(TOP_LEFT_CORNER[0], TOP_LEFT_CORNER[1], 1, 0, 6)) return;
				if (this.findAdjacentMove(TOP_LEFT_CORNER[0], TOP_LEFT_CORNER[1], 0, 1, 6)) return;
			}
			if (this.gameModel.stones[TOP_RIGHT_CORNER[0]][TOP_RIGHT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(TOP_RIGHT_CORNER[0], TOP_RIGHT_CORNER[1], -1, 0, 6)) return;
				if (this.findAdjacentMove(TOP_RIGHT_CORNER[0], TOP_RIGHT_CORNER[1], 0, 1, 6)) return;
			}
			if (this.gameModel.stones[BOTTOM_RIGHT_CORNER[0]][BOTTOM_RIGHT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1], -1, 0, 6)) return;
				if (this.findAdjacentMove(BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1], 0, -1, 6)) return;
			}
			if (this.gameModel.stones[BOTTOM_LEFT_CORNER[0]][BOTTOM_LEFT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(BOTTOM_LEFT_CORNER[0], BOTTOM_LEFT_CORNER[1], 1, 0, 6)) return;
				if (this.findAdjacentMove(BOTTOM_LEFT_CORNER[0], BOTTOM_LEFT_CORNER[1], 0, -1, 6)) return;
			}
			
			// Try to capture a side piece, but nothing adjacent to a corner
			if (this.findAdjacentMove(TOP_TOP_LEFT[0],        TOP_TOP_LEFT[1],         1,  0, 4)) return;
			if (this.findAdjacentMove(TOP_BOTTOM_RIGHT[0],    TOP_BOTTOM_RIGHT[1],     0,  1, 4)) return;
			if (this.findAdjacentMove(BOTTOM_BOTTOM_RIGHT[0], BOTTOM_BOTTOM_RIGHT[1], -1,  0, 4)) return;
			if (this.findAdjacentMove(BOTTOM_TOP_LEFT[0],     BOTTOM_TOP_LEFT[1],      0, -1, 4)) return;
			
			// Find the move that captures the most stones (excluding X-squares and squares close to corners)...
			var captureCounts:Array = new Array();
			for (var x:uint = 0; x < 7; ++x)
			{
				for (var y:uint = 0; y < 7; ++y)
				{
					if (this.gameModel.stones[x][y] != null) continue;
					if ((x == TOP_LEFT_X[0]          && y == TOP_LEFT_X[1]) ||
						(x == TOP_RIGHT_X[0]         && y == TOP_RIGHT_X[1]) ||
						(x == BOTTOM_LEFT_X[0]       && y == BOTTOM_LEFT_X[1]) ||
						(x == BOTTOM_RIGHT_X[0]      && y == BOTTOM_RIGHT_X[1]) ||
						(x == TOP_TOP_LEFT[0]        && y == TOP_TOP_LEFT[1]) ||
						(x == TOP_BOTTOM_LEFT[0]     && y == TOP_BOTTOM_LEFT[1]) ||
						(x == TOP_TOP_RIGHT[0]       && y == TOP_TOP_RIGHT[1]) ||
						(x == TOP_BOTTOM_RIGHT[0]    && y == TOP_BOTTOM_RIGHT[1]) ||
						(x == BOTTOM_TOP_RIGHT[0]    && y == BOTTOM_TOP_RIGHT[1]) ||
						(x == BOTTOM_BOTTOM_RIGHT[0] && y == BOTTOM_BOTTOM_RIGHT[1]) ||
						(x == BOTTOM_TOP_LEFT[0]     && y == BOTTOM_TOP_LEFT[1]) ||
						(x == BOTTOM_BOTTOM_LEFT[0]  && y == BOTTOM_BOTTOM_LEFT[1]))
					{
						continue;
					}
					var captureCount:uint = this.gameModel.findCaptures(this.computerColor, x, y, false);
					if (captureCount == 0) continue;
					var captureData:Object = new Object();
					captureData.stones = captureCount;
					captureData.x = x;
					captureData.y = y;
					captureCounts.push(captureData);
				}
			}
			
			if (captureCounts.length > 0)
			{
				captureCounts.sortOn("stones", Array.NUMERIC, Array.DESCENDING);
				var bestMove:Object = captureCounts.pop();
				if (bestMove.stones > 0)
				{
					this.onFinishComputerMove(bestMove.x, bestMove.y);
					return;
				}
			}
			
			// No choice but to move adjacent to a corner.
			if (this.gameModel.findCaptures(this.computerColor, TOP_TOP_LEFT[0],        TOP_TOP_LEFT[1],        false)) {this.onFinishComputerMove(TOP_TOP_LEFT[0],        TOP_TOP_LEFT[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, TOP_BOTTOM_LEFT[0],     TOP_BOTTOM_LEFT[1],     false)) {this.onFinishComputerMove(TOP_BOTTOM_LEFT[0],     TOP_BOTTOM_LEFT[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, TOP_TOP_RIGHT[0],       TOP_TOP_RIGHT[1],       false)) {this.onFinishComputerMove(TOP_TOP_RIGHT[0],       TOP_TOP_RIGHT[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, TOP_BOTTOM_RIGHT[0],    TOP_BOTTOM_RIGHT[1],    false)) {this.onFinishComputerMove(TOP_BOTTOM_RIGHT[0],    TOP_BOTTOM_RIGHT[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_TOP_RIGHT[0],    BOTTOM_TOP_RIGHT[1],    false)) {this.onFinishComputerMove(BOTTOM_TOP_RIGHT[0],    BOTTOM_TOP_RIGHT[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_BOTTOM_RIGHT[0], BOTTOM_BOTTOM_RIGHT[1], false)) {this.onFinishComputerMove(BOTTOM_BOTTOM_RIGHT[0], BOTTOM_BOTTOM_RIGHT[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_TOP_LEFT[0],     BOTTOM_TOP_LEFT[1],     false)) {this.onFinishComputerMove(BOTTOM_TOP_LEFT[0],     BOTTOM_TOP_LEFT[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_BOTTOM_LEFT[0],  BOTTOM_BOTTOM_LEFT[1],  false)) {this.onFinishComputerMove(BOTTOM_BOTTOM_LEFT[0],  BOTTOM_BOTTOM_LEFT[1]); return;}
			
			// No choice but to move in one of the x-squares. Worst possible move.
			if (this.gameModel.findCaptures(this.computerColor, TOP_LEFT_X[0],     TOP_LEFT_X[1],     false)) {this.onFinishComputerMove(TOP_LEFT_X[0],     TOP_LEFT_X[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, TOP_RIGHT_X[0],    TOP_RIGHT_X[1],    false)) {this.onFinishComputerMove(TOP_RIGHT_X[0],    TOP_RIGHT_X[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_LEFT_X[0],  BOTTOM_LEFT_X[1],  false)) {this.onFinishComputerMove(BOTTOM_LEFT_X[0],  BOTTOM_LEFT_X[1]); return;}
			if (this.gameModel.findCaptures(this.computerColor, BOTTOM_RIGHT_X[0], BOTTOM_RIGHT_X[1], false)) {this.onFinishComputerMove(BOTTOM_RIGHT_X[0], BOTTOM_RIGHT_X[1]); return;}
		}
		
		private function findAdjacentMove(x:uint, y:uint, xFactor:int, yFactor:int, depth:uint):Boolean
		{
			var testX:uint = x, testY:uint = y;
			for (var i:uint = 0; i < depth; ++i)
			{
				testX += xFactor;
				testY += yFactor;
				if (this.gameModel.stones[testX][testY] == null)
				{
					if (this.gameModel.findCaptures(this.computerColor, testX, testY, false) > 0)
					{
						this.onFinishComputerMove(testX, testY);
						return true;
					}
				}
			}
			return false;
		}
		
		private function onFinishComputerMove(x:uint, y:uint):void
		{
			gameModel.makeMove( x, y );
//FIX			this.makeMove(x, y);
		}		
	}
}