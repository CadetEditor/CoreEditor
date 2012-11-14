// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package flox.app.managers
{
	import flash.events.EventDispatcher;
	import flash.utils.*;
	
	import flox.app.core.commandHandlers.ICommandHandler;
	import flox.app.core.validators.IMetricValidator;
	import flox.app.core.validators.IValidator;
	import flox.app.resources.CommandHandlerFactory;
	import flox.app.resources.IResource;
	import flox.app.events.CommandManagerEvent;
	import flox.app.events.ResourceManagerEvent;
	import flox.app.events.ValidatorEvent;
	import flox.app.util.VectorUtil;
	import flox.app.validators.CompoundValidator;
	
	[Event(type="flox.app.events.CommandManagerEvent", name="commandAvailabilityChange")]
	
	public class CommandManager extends EventDispatcher
	{
		private var resourceManager						:ResourceManager;
		private var validatorCommandHandlerDictionary	:Dictionary;
		private var commandHandlerValidatorDictionary	:Dictionary;
		
		private var commandHandlerFactories			:Vector.<IResource>;
		
		public function CommandManager( resourceManager:ResourceManager )
		{
			this.resourceManager = resourceManager;
			
			validatorCommandHandlerDictionary = new Dictionary();
			commandHandlerValidatorDictionary = new Dictionary();
			
			commandHandlerFactories = resourceManager.getResourcesOfType(CommandHandlerFactory);
			resourceManager.addEventListener( ResourceManagerEvent.RESOURCE_ADDED, resourceAddedHandler );
		}
		
		private function resourceAddedHandler( event:ResourceManagerEvent ):void
		{
			if ( event.resource is CommandHandlerFactory == false ) return;
			var commandHandlerFactory:CommandHandlerFactory = CommandHandlerFactory(event.resource);
			addCommandHandlerFactory( commandHandlerFactory );
		}
		
		private function addCommandHandlerFactory( commandHandlerFactory:CommandHandlerFactory ):void
		{
			commandHandlerFactories.push(commandHandlerFactory);
			
			var validator:IValidator
			if ( commandHandlerFactory.validators.length == 1 )
			{
				validator = commandHandlerFactory.validators[0]
			}
			else if ( commandHandlerFactory.validators.length > 1 )
			{
				validator = new CompoundValidator();
				for each ( var childValidator:IValidator in commandHandlerFactory.validators )
				{
					CompoundValidator(validator).addValidator( childValidator );
				}
			}
			
			if ( validator ) 
			{
				validatorCommandHandlerDictionary[ validator ] = commandHandlerFactory;
				commandHandlerValidatorDictionary[ commandHandlerFactory ] = validator;
				validator.addEventListener(ValidatorEvent.STATE_CHANGED, validatorStateChangedHandler);
			}
			
			updateListeners( commandHandlerFactory.command );
		}
		
		public function isCommandHandled( commandID:String ):Boolean
		{
			var commandHandlerFactories:Array = getCommandHandlerFactoriesForCommandID( commandID );
			for each ( var commandHandlerFactory:CommandHandlerFactory in commandHandlerFactories )
			{
				var validator:IValidator = commandHandlerValidatorDictionary[commandHandlerFactory];
				if (!validator) return true
				if (validator.state) return true
			}
			return false;
		}
		
		public function executeCommand( commandID:String, parameters:Object = null ):void
		{
			if ( parameters == null ) parameters = {};
			
			var commandHandlerFactory:CommandHandlerFactory;
			var commandHandler:ICommandHandler;
			var commandHandlerFactories:Array = getAvailableCommandHandlerFactoriesForCommandID( commandID );
			
			// No command handlers avialable for this commandID, return.
			if ( commandHandlerFactories.length == 0 ) return;
			
			// Only one available, easy. Execute it.
			if ( commandHandlerFactories.length == 1 )
			{
				commandHandlerFactory = commandHandlerFactories[0];
				commandHandler = ICommandHandler( commandHandlerFactory.getInstance() );
				commandHandler.execute( parameters  )
				return;
			}
			// More than one available. Loop through the factory's validators and calculate a metric
			// to determine the 'best fit' factory.
			else
			{
				var bestCommandHandlerFactory:CommandHandlerFactory
				var bestMetric:Number = Number.NEGATIVE_INFINITY;
				for each ( commandHandlerFactory in commandHandlerFactories )
				{
					var metric:Number = 0;
					for each ( var validator:IValidator in commandHandlerFactory.validators )
					{
						if ( validator is IMetricValidator )
						{
							metric += IMetricValidator( validator ).metric;
						}
						else
						{
							metric += validator.state ? 1 : 0;
						}
					}
					
					if ( metric > bestMetric )
					{
						bestMetric = metric;
						bestCommandHandlerFactory = commandHandlerFactory;
					}
				}
				
				commandHandlerFactory = bestCommandHandlerFactory;
				
				// Execute the best commandHandler
				commandHandler = ICommandHandler( commandHandlerFactory.getInstance() );
				commandHandler.execute( parameters );
				return;
			}
		}
		
		// Handlers
		private function validatorStateChangedHandler(event:ValidatorEvent):void
		{
			var commandHandlerFactory:CommandHandlerFactory = validatorCommandHandlerDictionary[event.target];
			updateListeners( commandHandlerFactory.command );
		}
		
		// Util functions
		private function updateListeners( commandID:String ):void
		{
			var availableCommandHandlerFactories:Array = getAvailableCommandHandlerFactoriesForCommandID( commandID );
			dispatchEvent( new CommandManagerEvent( CommandManagerEvent.COMMAND_AVAILABILITY_CHANGE, commandID, availableCommandHandlerFactories.length > 0) );
		}
		
		private function getCommandHandlerFactoriesForCommandID( commandID:String ):Array
		{
			var filteredResults:Vector.<IResource> = commandHandlerFactories.filter( function( item:CommandHandlerFactory, index:int, vec:Vector.<IResource> ):Boolean { return item.command == commandID; }, this );
			return VectorUtil.toArray(filteredResults);
		}
		
		private function getAvailableCommandHandlerFactoriesForCommandID( commandID:String ):Array
		{
			var commandHandlerFactories:Array = getCommandHandlerFactoriesForCommandID( commandID );
			
			var array:Array = [];
			for each ( var commandHandlerFactory:CommandHandlerFactory in commandHandlerFactories ) 
			{
				var validator:IValidator = commandHandlerValidatorDictionary[commandHandlerFactory];
				if ( !validator || validator.state ) 
				{
					array.push( commandHandlerFactory );
				}
			}
			return array;
		}
	}
}