// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package flox.app.managers.fileSystemProviders.azureAIR
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.net.URLLoader;
	
	import flox.app.core.managers.fileSystemProviders.operations.IDoesFileExistOperation;
	import flox.app.core.managers.fileSystemProviders.operations.IGetDirectoryContentsOperation;
	import flox.app.entities.URI;
	import flox.app.events.FileSystemErrorCodes;

	internal class DoesFileExistOperation extends AzureFileSystemProviderOperation implements IDoesFileExistOperation
	{
		private var loader		:URLLoader;
		private var _fileExists	:Boolean;
		
		public function DoesFileExistOperation( uri:URI, endPoint:String, sas:String, fileSystemProvider:AzureFileSystemProviderAIR )
		{
			super(uri, endPoint, sas, fileSystemProvider);
		}
		
		override public function execute():void
		{
			var folder:URI = _uri.getParentURI();
			
			var getDirectoryContentsOperation:IGetDirectoryContentsOperation = _fileSystemProvider.getDirectoryContents(folder);
			getDirectoryContentsOperation.addEventListener(Event.COMPLETE, doesFileExistCompleteHandler);
			getDirectoryContentsOperation.addEventListener(ErrorEvent.ERROR, doesFileExistErrorHandler);
			getDirectoryContentsOperation.execute();
		}
		
		private function doesFileExistErrorHandler( event:ErrorEvent ):void
		{
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, event.text, FileSystemErrorCodes.DOES_FILE_EXIST_ERROR ) );
		}
		
		private function doesFileExistCompleteHandler( event:Event ):void
		{
			var contents:Vector.<URI> = IGetDirectoryContentsOperation(event.target).contents;
			
			_fileExists = false;
			for each ( var childURI:URI in contents )
			{
				if ( childURI.path == _uri.path )
				{
					_fileExists = true;
					break;
				}
			}
			
			dispatchEvent( new Event( Event.COMPLETE ) );
		}
		
		public function get fileExists():Boolean { return _fileExists; }
		
		override public function get label():String
		{
			return "Does File Exist : " + _uri.path;
		}
	}
}