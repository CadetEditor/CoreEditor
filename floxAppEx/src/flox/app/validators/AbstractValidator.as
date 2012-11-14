// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package flox.app.validators
{
	import flash.events.EventDispatcher;
	
	import flox.app.core.validators.IValidator;
	import flox.app.events.ValidatorEvent;

	[Event(name="stateChanged", type="flox.app.events.ValidatorEvent")]
	
	public class AbstractValidator extends EventDispatcher implements IValidator
	{
		protected var _state		:Boolean = false;
		
		private var firstSet		:Boolean = false;
		
		public function AbstractValidator()
		{
			
		}

		public function dispose():void {}
		
		public function get state():Boolean { return _state; }
		protected function setState( value:Boolean ):void
		{
			if ( value == _state && !firstSet ) return;
			firstSet = true;
			_state = value;
			dispatchEvent( new ValidatorEvent( ValidatorEvent.STATE_CHANGED, _state ) );
		}
	}
}