// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package flox.app.validators
{
	import flox.app.core.contexts.IOperationManagerContext;
	import flox.app.events.ContextManagerEvent;
	import flox.app.events.OperationManagerEvent;
	import flox.app.managers.ContextManager;
	import flox.app.managers.OperationManager;
	
	public class UndoAvailableValidator extends AbstractValidator
	{
		private var contextManager			:ContextManager;
		private var _operationManager		:OperationManager;
		
		public function UndoAvailableValidator( contextManager:ContextManager )
		{
			this.contextManager = contextManager;
			contextManager.addEventListener( ContextManagerEvent.CURRENT_CONTEXT_CHANGED, contextChangedHandler );
			contextChanged();
		}
		
		protected function contextChangedHandler( event:ContextManagerEvent ):void
		{
			contextChanged();
		}
		
		override public function dispose():void
		{
			contextManager.removeEventListener( ContextManagerEvent.CURRENT_CONTEXT_CHANGED, contextChangedHandler );
			operationManager = null;
			contextManager = null;
		}
		
		private function contextChanged():void
		{
			var context:IOperationManagerContext = contextManager.getLatestContextOfType( IOperationManagerContext ) as IOperationManagerContext;
			if ( !context ) 
			{
				operationManager = null;
				setState(false);
				return;
			}
			operationManager = context.operationManager;
		}
	
		
		private function set operationManager( value:OperationManager ):void
		{
			if ( _operationManager == value ) return;
			
			if ( _operationManager ) 
			{
				_operationManager.removeEventListener( OperationManagerEvent.CHANGE, historyManagerChangedHandler );
			}
			
			_operationManager = value;
			
			if ( _operationManager ) 
			{
				_operationManager.addEventListener( OperationManagerEvent.CHANGE, historyManagerChangedHandler );
				changed();
			}
		}
		private function get operationManager():OperationManager { return _operationManager; }
				
		private function historyManagerChangedHandler( event:OperationManagerEvent ):void
		{
			changed();
		}
		
		private function changed():void
		{
			setState(_operationManager.isUndoAvailable());
		}
	}
}