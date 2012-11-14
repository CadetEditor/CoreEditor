// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package flox.app.managers.fileSystemProviders.sharedObject
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flox.app.events.FileSystemErrorEvent;
	
	import flox.app.core.managers.fileSystemProviders.IFileSystemProvider;
	import flox.app.core.managers.fileSystemProviders.operations.IReadFileOperation;
	import flox.app.entities.URI;
	import flox.app.events.FileSystemErrorCodes;
	import flox.app.util.AsynchronousUtil;

	internal class ReadFileOperation extends SharedObjectFileSystemProviderOperation implements IReadFileOperation
	{
		private var _bytes		:ByteArray;
		
		public function ReadFileOperation(uri:URI, sharedObject:SharedObject, fileSystemProvider:IFileSystemProvider)
		{
			super(uri, sharedObject, fileSystemProvider);
		}
		
		override public function execute():void
		{
			_bytes =  sharedObject.data[_uri.path];
			_bytes.position = 0;
			if ( bytes == null )
			{
				AsynchronousUtil.dispatchLater(this, new FileSystemErrorEvent( FileSystemErrorEvent.ERROR, _uri, FileSystemErrorCodes.READ_FILE_ERROR));
				return;
			}
			
			AsynchronousUtil.dispatchLater(this, new Event( Event.COMPLETE ));
		}
		
		public function get bytes():ByteArray { return _bytes; }
	}
}