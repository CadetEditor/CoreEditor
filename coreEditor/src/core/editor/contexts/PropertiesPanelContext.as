// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package core.editor.contexts
{
	import flash.display.DisplayObject;
	
	import core.app.CoreApp;
	import core.appEx.core.contexts.IContext;
	import core.appEx.core.contexts.IInspectableContext;
	import core.appEx.core.contexts.IOperationManagerContext;
	import core.appEx.core.contexts.IVisualContext;
	import core.appEx.events.ContextSelectionValidatorEvent;
	import core.app.events.ResourceManagerEvent;
	import core.appEx.managers.OperationManager;
	import core.app.operations.ChangePropertyOperation;
	import core.app.operations.UndoableCompoundOperation;
	import core.app.resources.IResource;
	import core.appEx.resources.PropertyInspectorItemEditorFactory;
	import core.appEx.validators.ContextSelectionValidator;
	import core.data.ArrayCollection;
	import core.editor.CoreEditor;
	import core.ui.components.PropertyInspector;
	import core.ui.events.PropertyInspectorEvent;
	

	public class PropertiesPanelContext implements IVisualContext
	{
		protected var _view					:PropertyInspector;
		protected var selectionValidator	:ContextSelectionValidator;
		
		public function PropertiesPanelContext()
		{
			_view = new PropertyInspector();
			_view.showBorder = false;
			_view.padding = 0;
			
			_view.addEventListener(PropertyInspectorEvent.COMMIT_VALUE, commitValueHandler);
			selectionValidator = new ContextSelectionValidator( CoreEditor.contextManager, IInspectableContext, false );
			selectionValidator.addEventListener( ContextSelectionValidatorEvent.VALID_SELECTION_CHANGED, refresh );
			refresh();
			
			var factories:Vector.<IResource> = CoreApp.resourceManager.getResourcesOfType( PropertyInspectorItemEditorFactory );
			for each ( var factory:PropertyInspectorItemEditorFactory in factories )
			{
				_view.registerEditor( factory.getID(), factory.getInstanceType(), factory.valueField, factory.itemsField, factory.itemsPropertyField, factory.autoCommitValue );
			}
			
			CoreApp.resourceManager.addEventListener(ResourceManagerEvent.RESOURCE_ADDED, resourceAddedHandler);
		}
		
		public function dispose():void
		{
			CoreApp.resourceManager.removeEventListener(ResourceManagerEvent.RESOURCE_ADDED, resourceAddedHandler);
			selectionValidator.removeEventListener( ContextSelectionValidatorEvent.VALID_SELECTION_CHANGED, refresh );
			selectionValidator.dispose();
			selectionValidator = null;
		}
		
		public function get view():DisplayObject { return _view; }
		
		private function resourceAddedHandler( event:ResourceManagerEvent ):void
		{
			var factory:PropertyInspectorItemEditorFactory = event.resource as PropertyInspectorItemEditorFactory;
			if ( factory == null ) return;
			_view.registerEditor( factory.getID(), factory.getInstanceType(), factory.valueField, factory.itemsField, factory.itemsPropertyField, factory.autoCommitValue );
		}
		
		private function commitValueHandler( event:PropertyInspectorEvent ):void
		{
			var context:IContext = selectionValidator.getContext();
			if ( context is IOperationManagerContext )
			{
				event.preventDefault();
				var operationManager:OperationManager = IOperationManagerContext(context).operationManager;
				var operation:UndoableCompoundOperation = new UndoableCompoundOperation();
				operation.label = "Change property(s)";
				for ( var i:int = 0; i < event.hosts.length; i++ )
				{
					if ( event.value != event.oldValues[i] ) {
						var changePropertyOperation:ChangePropertyOperation = new ChangePropertyOperation( event.hosts[i], event.property, event.value, event.oldValues[i] );
						operation.addOperation(changePropertyOperation);
					}
				}
				if (operation.operations.length > 0) {
					operationManager.addOperation(operation);
				}
			}
		}
				
		protected function refresh( event:ContextSelectionValidatorEvent = null ):void
		{
			_view.dataProvider = null;
			
			if ( selectionValidator.state == false ) return;
			
			var selection:Array = selectionValidator.getValidSelection();
			//if ( selection.length > 1 || selection.length == 0 ) return;
			
			//var item:* = selection[0];
			//if ( item == null ) return;
			
			_view.dataProvider = new ArrayCollection(selection);
		}
	}
}