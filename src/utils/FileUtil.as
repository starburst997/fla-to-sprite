package utils
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.utils.ByteArray;

	/**
	 *  FileReference util, used to load / save byteArray
	 */
	public final class FileUtil
	{
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  FileReference
		 */
		public static var file:FileReference;
		
		/**
		 *  FileReferenceList
		 */
		private static var files:FileReferenceList;
		
		/**
		 *  Save Func
		 */
		private static var saveFunc:Function;
		
		/**
		 *  Load Func
		 */
		private static var loadFunc:Function;
		
		/**
		 *  Params
		 */
		private static var params:Array;
		
		/**
		 *  Progress
		 */
		public static var progress:Number = 1;
		
		/**
		 *  Canceled
		 */
		public static var canceled:Boolean = false;
		
		/**
		 *  Error
		 */
		public static var error:Boolean = false;
		
		/**
		 *  Bytes / Names for loading multiple bytes
		 */
		public static var names:Array, bytes:Array, nFiles:int;
		
		/**
		 *  Last used saved name
		 */
		public static var lastSavedName:String = "";
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  Save the file
		 */
		public static function save( data:ByteArray, name:String, saveFunc:Function = null ):void
		{
			// Save
			file = 	new FileReference();
			file.addEventListener( Event.COMPLETE, save_completeHandler, false, 0, true );
			file.addEventListener( Event.CANCEL, save_completeHandler, false, 0, true );
			file.addEventListener( IOErrorEvent.IO_ERROR, save_ioErrorHandler, false, 0, true );
			file.addEventListener( ProgressEvent.PROGRESS, progressHandler, false, 0, true );
			
			canceled = false;
			error = false;
			progress = 0;
			
			FileUtil.saveFunc = saveFunc;
			
			file.save( data, name );
		}
		
		/**
		 *  Start the load of a file (Get ByteArray)
		 */
		public static function loadByte( loadFunc:Function, filters:Array = null, ... rest ):void
		{
			FileUtil.loadFunc = loadFunc;
			FileUtil.params = rest;
			
			canceled = false;
			error = false;
			progress = 0;
			
			file = 	new FileReference();
			file.addEventListener( Event.SELECT, load_selectByteHandler, false, 0, true );
			file.addEventListener( Event.CANCEL, load_cancelHandler, false, 0, true );
			file.addEventListener( ProgressEvent.PROGRESS, progressHandler, false, 0, true );
			
			file.browse( filters );
		}
		
		/**
		 *  Start the load of a file (Get ByteArray)
		 */
		public static function loadByteName( loadFunc:Function, filters:Array = null, ... rest ):void
		{
			FileUtil.loadFunc = loadFunc;
			FileUtil.params = rest;
			
			canceled = false;
			error = false;
			progress = 0;
			
			file = 	new FileReference();
			file.addEventListener( Event.SELECT, load_selectByteNameHandler, false, 0, true );
			file.addEventListener( Event.CANCEL, load_cancelHandler, false, 0, true );
			file.addEventListener( ProgressEvent.PROGRESS, progressHandler, false, 0, true );
			
			file.browse( filters );
		}
		
		/**
		 *  Start the load of a file (Get ByteArray)
		 */
		public static function loadByteNames( loadFunc:Function, filters:Array = null, ... rest ):void
		{
			FileUtil.loadFunc = loadFunc;
			FileUtil.params = rest;
			
			canceled = false;
			error = false;
			progress = 0;
			
			files = new FileReferenceList();
			files.addEventListener( Event.SELECT, load_selectByteNamesHandler, false, 0, true );
			files.addEventListener( Event.CANCEL, load_cancelHandler, false, 0, true );
			files.addEventListener( ProgressEvent.PROGRESS, progressHandler, false, 0, true );
			
			files.browse( filters );
		}
		
		/**
		 *  Start the load of a file (Get Name)
		 */
		public static function loadName( loadFunc:Function, filters:Array = null, ... rest ):void
		{
			FileUtil.loadFunc = loadFunc;
			FileUtil.params = rest;
			
			canceled = false;
			error = false;
			progress = 0;
			
			file = new FileReference();
			file.addEventListener( Event.SELECT, load_selectNameHandler, false, 0, true );
			file.addEventListener( Event.CANCEL, load_cancelHandler, false, 0, true );
			file.addEventListener( ProgressEvent.PROGRESS, progressHandler, false, 0, true );
			
			file.browse( filters );
		}
		
		/**
		 *  Start the load of a file (Get Names)
		 */
		public static function loadNames( loadFunc:Function, filters:Array = null, ... rest ):void
		{
			FileUtil.loadFunc = loadFunc;
			FileUtil.params = rest;
			
			canceled = false;
			error = false;
			progress = 0;
			
			files = new FileReferenceList();
			files.addEventListener( Event.SELECT, load_selectNamesHandler, false, 0, true );
			files.addEventListener( Event.CANCEL, load_cancelHandler, false, 0, true );
			files.addEventListener( ProgressEvent.PROGRESS, progressHandler, false, 0, true );
			
			files.browse( filters );
		}
		
		//--------------------------------------------------------------------------
    	//
    	//  Events
    	//
    	//--------------------------------------------------------------------------
    	
		/**
		 *  Progress Handler
		 */
		private static function progressHandler( event:ProgressEvent ):void
		{
			if ( event.bytesTotal == 0 )
			{
				progress = 0;
			}
			else
			{
				progress = event.bytesLoaded / event.bytesTotal;
			}
			
			if ( progress >= 1 )
			{
				progress = 0.99;
			}
		}
		
		/**
		 *  When the user cancel the loading of a file
		 */
		private static function load_cancelHandler( event:Event ):void
		{
			if ( file != null )
			{
				file.removeEventListener( Event.SELECT, load_selectByteHandler );
				file.removeEventListener( Event.SELECT, load_selectNameHandler );
				file.removeEventListener( Event.SELECT, load_selectNamesHandler );
				file.removeEventListener( Event.CANCEL, load_cancelHandler );
				file.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			}
			
			if ( files != null )
			{
				files.removeEventListener( Event.SELECT, load_selectByteHandler );
				files.removeEventListener( Event.SELECT, load_selectNameHandler );
				files.removeEventListener( Event.SELECT, load_selectNamesHandler );
				files.removeEventListener( Event.CANCEL, load_cancelHandler );
				files.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			}
			
			progress = 1;
			canceled = true;
			
			file = null;
			files = null;
		}
		
		/**
		 *  When a file is opened
		 */
		private static function load_selectByteHandler( event:Event ):void
		{
			file.removeEventListener( Event.SELECT, load_selectByteHandler );
			file.removeEventListener( Event.CANCEL, load_cancelHandler );
			
			file.addEventListener( Event.COMPLETE, load_completeHandler, false, 0, true );
			file.addEventListener( IOErrorEvent.IO_ERROR, load_ioErrorHandler, false, 0, true );
			
			file.load();
		}
		
		/**
		 *  When a file is opened
		 */
		private static function load_selectByteNameHandler( event:Event ):void
		{
			file.removeEventListener( Event.SELECT, load_selectByteHandler );
			file.removeEventListener( Event.CANCEL, load_cancelHandler );
			
			file.addEventListener( Event.COMPLETE, load_completeNameHandler, false, 0, true );
			file.addEventListener( IOErrorEvent.IO_ERROR, load_ioErrorHandler, false, 0, true );
			
			file.load();
		}
		
		/**
		 *  When a file is opened
		 */
		private static function load_selectNameHandler( event:Event ):void
		{
			file.removeEventListener( Event.SELECT, load_selectNameHandler );
			file.removeEventListener( Event.CANCEL, load_cancelHandler );
			file.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			progress = 1;

			params.unshift( file.name );
			loadFunc.apply( null, params );
			
			// Kill reference
			file = null;
			loadFunc = null;
			params = null;
		}
		
		/**
		 *  When a file is opened
		 */
		private static function load_selectByteNamesHandler( event:Event ):void
		{
			/* Delcarations */
			
			var file:FileReference;
			
			/* Execute */
			
			files.removeEventListener( Event.SELECT, load_selectNamesHandler );
			files.removeEventListener( Event.CANCEL, load_cancelHandler );
			files.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			names = [];
			bytes = [];
			nFiles = files.fileList.length;
			for each ( file in files.fileList )
			{
				file.addEventListener( Event.COMPLETE, load_completeHandler2, false, 0, true );
				file.addEventListener( IOErrorEvent.IO_ERROR, load_ioErrorHandler, false, 0, true );
				
				file.load();
			}
		}
		
		private static function load_completeHandler2( event:Event ):void
		{
			/* Delcarations */
			
			var file:FileReference;
			
			/* Execute */
			
			file = event.currentTarget as FileReference;
			
			file.removeEventListener( Event.COMPLETE, load_completeHandler2 );
			file.removeEventListener( IOErrorEvent.IO_ERROR, load_ioErrorHandler );
			
			names.push( file.name );
			bytes.push( file.data );
			
			if ( --nFiles == 0 )
			{
				progress = 1;
				
				params.unshift( names );
				params.unshift( bytes );
				loadFunc.apply( null, params );
				
				// Kill reference
				files = null;
				loadFunc = null;
				params = null;
			}
		}
		
		/**
		 *  When a file is opened
		 */
		private static function load_selectNamesHandler( event:Event ):void
		{
			/* Delcarations */
			
			var file:FileReference, names:Array;
			
			/* Execute */
			
			files.removeEventListener( Event.SELECT, load_selectNamesHandler );
			files.removeEventListener( Event.CANCEL, load_cancelHandler );
			files.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			progress = 1;
			
			names = [];
			for each ( file in files.fileList )
			{
				names.push( file.name );
			}
			
			params.unshift( names );
			loadFunc.apply( null, params );
			
			// Kill reference
			files = null;
			loadFunc = null;
			params = null;
		}
		
		/**
		 *  IOError from the loading
		 */
		private static function load_ioErrorHandler( event:IOErrorEvent ):void
		{
			file.removeEventListener( Event.COMPLETE, load_completeHandler );
			file.removeEventListener( IOErrorEvent.IO_ERROR, load_ioErrorHandler );
			file.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			progress = 1;
			canceled = true;
			error = true;
			
			file = null;
			
			trace( "" );
			trace( "*** ERROR ***" );
			trace( "	- Failed to load file..." );
			trace( "*************" );
			trace( "" );
		}
		
		/**
		 *  When a file is completely loaded
		 */
		private static function load_completeHandler( event:Event ):void
		{
			file.removeEventListener( IOErrorEvent.IO_ERROR, load_ioErrorHandler );
			file.removeEventListener( Event.COMPLETE, load_completeHandler );
			file.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			progress = 1;
			
			params.unshift( file.data );
			
			// Kill reference
			var oldFunc:Function = loadFunc;
			var oldParams:Array = params;
			
			file = null;
			loadFunc = null;
			params = null;
			
			oldFunc.apply( null, oldParams );
		}
		
		/**
		 *  When a file is completely loaded
		 */
		private static function load_completeNameHandler( event:Event ):void
		{
			file.removeEventListener( IOErrorEvent.IO_ERROR, load_ioErrorHandler );
			file.removeEventListener( Event.COMPLETE, load_completeHandler );
			file.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			progress = 1;
			
			params.unshift( file.name );
			params.unshift( file.data );
			loadFunc.apply( null, params );
			
			// Kill reference
			file = null;
			loadFunc = null;
			params = null;
		}
		
		/**
		 *  When the user cancel / complete the saving of a file
		 */
		private static function save_completeHandler( event:Event ):void
		{
			if ( file == null )
			{
				return;
			}
			
			file.removeEventListener( Event.COMPLETE, save_completeHandler );
			file.removeEventListener( Event.CANCEL, save_completeHandler );
			file.removeEventListener( IOErrorEvent.IO_ERROR, save_ioErrorHandler );
			file.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			progress = 1;
			
			if ( event.type != Event.CANCEL )
			{
				lastSavedName = file.name;
				
				if ( saveFunc != null )
				{
					saveFunc();
				}
			}
			
			file = null;
			
			saveFunc = null;
		}
		
		/**
		 *  IOError from the saving
		 */
		private static function save_ioErrorHandler( event:IOErrorEvent ):void
		{
			file.removeEventListener( Event.COMPLETE, save_completeHandler );
			file.removeEventListener( Event.CANCEL, save_completeHandler );
			file.removeEventListener( IOErrorEvent.IO_ERROR, save_ioErrorHandler );
			file.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
			
			canceled = true;
			error = true;
			progress = 1;
			
			file = null;
			
			trace( "" );
			trace( "*** ERROR ***" );
			trace( "	- Failed to save file..." );
			trace( "*************" );
			trace( "" );
		}
	}
}