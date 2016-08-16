/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// SoundPrimitives.as
// John Maloney, June 2010
//
// Sound primitives.

package primitives {
	import blocks.Block;
	import flash.utils.Dictionary;
	import interpreter.*;
	import scratch.*;
	import flash.utils.ByteArray;

public class CfunPrims {

	private var app:Scratch;
	private var interp:Interpreter;

	public function CfunPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		primTable["readcksound"]			= primReadSound;
		primTable["readckslide"]	        = primReadSlide;
		primTable["readcklight"]		    = primReadLight;
		
	}

	private function primReadSound(b:Block):void {
		
	}
	
	private function primReadSlide(b:Block):void {
		
	
	}
	
	private function primReadLight(b:Block):Number {
		var numba:ByteArray = new ByteArray();//4字节流转浮点型（注意大端顺序）_wh
//		numba.writeByte(app.comDataArray[6]);
//		numba.writeByte(app.comDataArray[7]);
		numba.position = 0;
		var num:Number = numba.readShort();
//		app.comDataArray.length = 0;//数组清零_wh
//		app.comDataArrayOld.length = 0;//数组清零_wh
		return num;			

	}

}}
