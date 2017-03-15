package
{
  import flash.events.Event;
  import flash.display.BitmapData;
  import flash.display.Sprite;
  import flash.display.MovieClip;
  import flash.display.PNGEncoderOptions;
  import flash.display.JPEGEncoderOptions;
  import flash.display.StageQuality;
  import flash.geom.Rectangle;
  import flash.geom.Point;
  import flash.geom.Matrix;

  import flash.utils.ByteArray;
  import flash.utils.getQualifiedClassName;
  import flash.utils.getDefinitionByName;

  import nochump.util.zip.*;
  import utils.*;

  /**
   * Export MovieClip in scene as a SpriteSheet
   */
  public dynamic class ExportScenes extends MovieClip
  {
    // Texture padding
    private static const PADDING:int = 1;

    // Waiting frames
    private var waiting:int = 0;

    // Map of all sprite for this scene
    private var definitions:Object = null;
    private var definition:Object = null;

    // Texture
    private var texture:BitmapData = null;

    // Current scene
    private var scene:MovieClip = null;

    // ZIP
    private var zip:ZipOutput = null;

    // Bin-Packing
    private var packer:MaxRectPacker = null;

    // Constructor
    public function ExportScenes()
    {
      super();

      trace("Exporting Scene");

      stop();
      addEventListener( Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true );
    }

    // AddedToStage Handler
    private function addedToStageHandler(e:Event):void
    {
      removeEventListener( Event.ADDED_TO_STAGE, addedToStageHandler );

      addEventListener( Event.ENTER_FRAME, enterFrameHandler, false, 0, true );
    }

    // EnterFrameHandler
    private function enterFrameHandler(e:Event):void
    {
      removeEventListener( Event.ENTER_FRAME, enterFrameHandler );

      // Parse this scene
      parseScene( this, function( bytes:ByteArray ):void
      {
        // Save
        FileUtil.save( bytes, scene.currentScene.name + ".spr" );
      } );
    }

    // Parse this scene
    private function parseScene( scene:MovieClip, handler:Function ):void
    {
      // Init
      definitions = {};
      this.scene = scene;

      definition = {};
      definition.definitions = [];

      // Add info values
      if ( scene.info != null )
      {
        for ( var name:String in scene.info )
        {
          definition[name] = scene.info[name];
        }
      }

      // Basic properties
      var width:int, height:int;

      if ( definition.width != null ) width = definition.width;
      if ( definition.height != null ) height = definition.height;

      definition.width = width;
      definition.height = height;

      var sceneName:String = scene.currentScene.name;
      definition.name = sceneName;

      // Create default texture
      trace( this.info );
      trace( "Scene Texture", width, height );
      texture = new BitmapData( width, height, true, 0x00000000 );

      // Bin-packing
      packer = new MaxRectPacker( width, height );

      // Parse
      parseChildren( this, function():void
      {
        // Texture
        texture.setPixel32(0, 0, 0xFF000000);
        var trimmed = trimAlpha(texture);
        texture.dispose();

        texture = trimmed.bmpd;
        texture.setPixel32(0, 0, 0x00000000);

        var bytes:ByteArray = new ByteArray();
        texture.encode( texture.rect, new PNGEncoderOptions(), bytes );

        // Texture only position
        var textureJSON:Object = {};
        textureJSON.definitions = [];

        textureJSON.name = sceneName;

        textureJSON.width = texture.width;
        textureJSON.height = texture.height;

        definition.width = texture.width;
        definition.height = texture.height;

        for each ( var obj:Object in definition.definitions )
        {
          if ( (obj.frames != null) && (obj.frames.length > 0) )
          {
            var def:Object = {
              name: obj.name,
              frames: obj.frames
            };

            if ( obj.tiled )
            {
              def.tiled = true;
            }

            if ( obj.noScale )
            {
              def.noScale = true;
            }

            textureJSON.definitions.push( def );
          }
        }

        // ZIP
        zip = new ZipOutput();
        zip.addFile( "texture.png", bytes );

        // Clean
        bytes.clear();
        texture.dispose();

        // Get background
        var background:MovieClip = scene.getChildByName("background") as MovieClip;
        if ( background != null )
        {
          var bmpd:BitmapData = screenshot( background, 0 ).bmpd;
          var old:BitmapData = bmpd;

          bmpd = new BitmapData(background.width, background.height, false, 0x000000);
          bmpd.copyPixels(old, old.rect, new Point(0,0));
          old.dispose();

          bytes = new ByteArray();
          bmpd.encode( bmpd.rect, new JPEGEncoderOptions(80), bytes );
          zip.addFile( "background.jpg", bytes );

          definition.background = {
            width: bmpd.width,
            height: bmpd.height
          };

          bmpd.dispose();
          bytes.clear();
        }

        // Add JSON
        zip.addFileFromString( "definitions.json", JSON.stringify(definition), 8 );
        zip.addFileFromString( "texture.json", JSON.stringify(textureJSON), 8 );

        // Finalize
        zip.finish();

        // Handler
        handler( zip.byteArray );
      } );
    }

    // Parse all movieclip
    private function parseChildren( mc:MovieClip, handler:Function = null ):void
    {
      for ( var i:int = 0; i < mc.numChildren; i++ )
      {
        var child:MovieClip = mc.getChildAt(i) as MovieClip;

        if ( (child != null) && (child.name != "background") )
        {
          parseChild( child );
        }
      }

      if ( handler != null )
      {
        if ( waiting <= 0 )
        {
          handler();
        }
        else
        {
          var fn:Function = function():void
          {
            if ( waiting <= 0 )
            {
              handler();
              removeEventListener( Event.ENTER_FRAME, fn );
            }
          };

          addEventListener( Event.ENTER_FRAME, fn, false, 0, true );
        }
      }
    }

    // Parse child
    private function parseChild( mc:MovieClip ):void
    {
      // Create Definition
      var i:int;
      var name:String = getName(mc);
      if ( name == "" ) return; // Skip MC with no name

      if ( definitions[name] == null )
      {
        var definition:Object = {};
        definitions[name] = definition;
        this.definition.definitions.push( definition );

        definition.name = name;

        // Add info values
        if ( mc.info != null )
        {
          for ( var p:String in mc.info )
          {
            definition[p] = mc.info[p];
          }
        }

        // Parse children
        if ( (mc.info != null) && mc.info.hasChilds )
        {
          // Add children
          definition.children = [];

          for ( i = 0; i < mc.numChildren; i++ )
          {
            var child:MovieClip = mc.getChildAt(i) as MovieClip;

            if ( child != null )
            {
              var childName:String = getName(child);
              if ( childName != "" )
              {
                definition.children.push(
                {
                  definition: childName,
                  name: child.name,
                  x: child.x,
                  y: child.y,
                  scaleX: child.scaleX,
                  scaleY: child.scaleY,
                  rotation: child.rotation
                });
              }
            }
          }

          parseChildren( mc );
        }
        else
        {
          // Create a screenshot and add it to the spritesheet
          definition.frames = [];

          if ( mc.totalFrames > 1 )
          {
            waiting += mc.totalFrames;

            //addDefinition( mc, definition );

            for ( i = 0; i < mc.totalFrames; i++ )
            {
              var frame:int = i;
              mc.addFrameScript( i, function():void
              {
                addDefinition( mc, definition );
                waiting--;

                trace("New frame", mc.currentFrame, waiting);
                mc.addFrameScript( mc.currentFrame - 1, null );

                if ( mc.currentFrame == mc.totalFrames )
                {
                  mc.stop();
                }
              } );
            }

            mc.gotoAndPlay(1);
          }
          else
          {
            addDefinition( mc, definition );
          }
        }
      }
    }

    // Add definition
    private function addDefinition( mc:MovieClip, definition:Object )
    {
      // Take screenshot
      var sshot:Object = screenshot( mc );
      if ( sshot == null )
      {
        trace("Invalid Sprite", name)
        return;
      }

      var bmpd:BitmapData = sshot.bmpd;
      var rect:Rectangle = packer.quickInsert( bmpd.width + PADDING * 2, bmpd.height + PADDING * 2 );

      if ( rect == null )
      {
        trace("!!! Cannot fit !!!");
        return;
      }

      // Add to Texture
      texture.copyPixels( bmpd, bmpd.rect, new Point(rect.x + PADDING, rect.y + PADDING) );
      bmpd.dispose();

      // Add to definition
      definition.frames.push(
      {
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height,
        originX: sshot.rect.x,
        originY: sshot.rect.y,
        originWidth: sshot.rect.width,
        originHeight: sshot.rect.height
      });
    }

    // Get qualified class name
    private function getName( mc:MovieClip ):String
    {
      var name:String = getQualifiedClassName(mc);

      if ( name.indexOf("::") != -1 )
      {
        return "";
      }

      return name;
    }

    // http://stackoverflow.com/a/17723163
    private function trimAlpha(source:BitmapData):Object {
      var notAlphaBounds:Rectangle = source.getColorBoundsRect(0xFF000000, 0x00000000, false);
      var trimed:BitmapData = new BitmapData(notAlphaBounds.width, notAlphaBounds.height, true, 0x00000000);
      trimed.copyPixels(source, notAlphaBounds, new Point());
      return {bmpd: trimed, rect: notAlphaBounds};
    }

    // Take a screenshot
    private function screenshot( mc:MovieClip, padding:int = 1 ):Object
    {
      var bounds:Rectangle = mc.getBounds( mc );

      if ( (bounds.width == 0) || (bounds.height == 0) )
      {
        return null;
      }

      // Add padding
      bounds.x -= padding;
      bounds.y -= padding;
      bounds.width += padding * 2;
      bounds.height += padding * 2;

      // Round to pixel
      bounds.x = Math.floor(bounds.x);
      bounds.y = Math.floor(bounds.y);
      bounds.width = Math.ceil(bounds.width);
      bounds.height = Math.ceil(bounds.height);

      // Fix offset
      var matrix:Matrix = new Matrix(); //mc.transform.matrix;

      if ( mc.transform.matrix.a == -1 )
      {
        matrix.scale( -1, 1 );
        //matrix.rotate( rotation / 180 * Math.PI );
        matrix.translate( Math.floor(bounds.right), -Math.floor(bounds.top) );
        matrix.scale( 1, 1 );
      }
      else
      {
        //matrix.rotate( rotation / 180 * Math.PI );
        matrix.translate( -Math.floor(bounds.left), -Math.floor(bounds.top) );
        matrix.scale( 1, 1 );
      }

      // Draw
      var bmpd:BitmapData = new BitmapData( bounds.width, bounds.height, true, 0x00000000 );
      bmpd.drawWithQuality( mc, matrix, null, null, null, true, StageQuality.HIGH_16X16 );

      // Trim
      var trim:Object = trimAlpha(bmpd);
      bmpd.dispose();

      bmpd = trim.bmpd;

      bounds.x -= trim.rect.x;
      bounds.y -= trim.rect.y;

      return {bmpd: bmpd, rect: bounds};
    }
  }
}