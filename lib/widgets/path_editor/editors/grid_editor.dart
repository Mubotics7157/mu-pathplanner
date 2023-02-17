

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pathplanner/robot_path/robot_path.dart';
import 'package:pathplanner/robot_path/waypoint.dart';
import 'package:pathplanner/widgets/field_image.dart';
import 'package:pathplanner/widgets/path_editor/path_painter_util.dart';
import 'package:pathplanner/widgets/path_editor/cards/simple_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:touchable/touchable.dart';


class GridEditor extends StatefulWidget {
  final RobotPath path;
  final FieldImage fieldImage;
  final Size robotSize;
  final bool holonomicMode;
  final SharedPreferences prefs;

  const GridEditor(
      {required this.path,
      required this.fieldImage,
      required this.robotSize,
      required this.holonomicMode,
      required this.prefs,
      super.key});

  @override
  State<GridEditor> createState() => _GridEditorState();
}

class _GridEditorState extends State<GridEditor> {

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {

    return Stack(
      key: _key,
      
      children: [
        Center(
          child: InteractiveViewer(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Stack(
                  children: [
                    widget.fieldImage.getWidget(),
                    Positioned.fill(
                      child: CanvasTouchDetector(
                        builder: (context) => 
                      CustomPaint(
                          painter: _GridPainter(  
                          context,
                          widget.path,
                          widget.fieldImage,
                          widget.robotSize,
                          widget.holonomicMode,)
                        )
                      )
                    ),
                  ],
                ),
            ),
          ),
        ),
        _buildPathLengthCard(),
      ],
    );
  }




  Widget _buildPathLengthCard() {
    return SimpleCard(
      stackKey: _key,
      prefs: widget.prefs,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            ),
            onPressed: () 
            async {
              build(context);
                 final Directory directory = await getApplicationDocumentsDirectory();
              final File file = File('${directory.path}/csv.csv');
              await file.writeAsString(getCsv());
              },
            child: const Text('Output'),
          )
        ],
      ),
    );
  }

  String getCsv(){
    String output = '';
    for(int y = 0; y < 11; y++)
    {
      for(int x = 0; x < 23; x++)
      {
        if(_GridPainter.twoDList[x][y]==1){
          output += '1, ';
        }
        else{
          output += '0, ';
        }
      }
      output += '\n';
    }

    return output;

  }
  

}

class _GridPainter extends CustomPainter {
  final BuildContext context;
  final RobotPath path;
  final FieldImage fieldImage;
  final Size robotSize;
  final bool holonomicMode;


  List<int> coords = [];
  static var twoDList = List.generate(23, (i) => List.filled(11, 0, growable: false), growable: false);


  static double scale = 1;

  _GridPainter(this.context, this.path, this.fieldImage, this.robotSize,
      this.holonomicMode );


  @override
  void paint(Canvas canvas, Size size) {
    scale = size.width / fieldImage.defaultSize.width;

    if (holonomicMode) {
      PathPainterUtil.paintCenterPath(
          path, canvas, scale, Colors.grey[700]!, fieldImage);
    } else {
      PathPainterUtil.paintDualPaths(
          path, robotSize, canvas, scale, Colors.grey[700]!, fieldImage);
    }

    for (EventMarker marker in path.markers) {
      PathPainterUtil.paintMarker(
          canvas,
          PathPainterUtil.getMarkerLocation(marker, path, fieldImage, scale),
          Colors.grey[700]!);
    }
    

    _paintWaypoints(canvas);
    _paintGrid(canvas);
    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _paintWaypoints(Canvas canvas) {
    for (Waypoint waypoint in path.waypoints) {
      Color color =
          waypoint.isStopPoint ? Colors.deepPurple : Colors.grey[400]!;
      PathPainterUtil.paintRobotOutline(
          waypoint, robotSize, holonomicMode, canvas, scale, color, fieldImage);

      var paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.grey[500]!;

      canvas.drawCircle(
          PathPainterUtil.pointToPixelOffset(
              waypoint.anchorPoint, scale, fieldImage),
          PathPainterUtil.uiPointSizeToPixels(20, scale, fieldImage),
          paint);
    }
  }

   void _paintGrid(Canvas canvas){
     var myCanvas = TouchyCanvas(context,canvas); 

       var paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    for(int y = 0; y < 11; y++)
    {
     for(int x = 0; x < 23; x++)
      {
        if(twoDList[x][y] == 1)
        {
          myCanvas.drawRect(Offset(x * 50 + 4, y*50 + 5) & const Size(50, 50), paint..color =const Color.fromARGB(255, 138, 10, 10).withOpacity(0.5), onTapDown: (tapdetail) {
         twoDList[x][y] = 0;});
        }
        else{
          myCanvas.drawRect(Offset(x * 50 + 4, y*50 + 5) & const Size(50, 50), paint..color =const Color.fromARGB(255, 42, 214, 65).withOpacity(0.5), onTapDown: (tapdetail) {
         twoDList[x][y] = 1;});
        }
 myCanvas.drawLine(Offset(x* 50 +4, 0),Offset(x* 50 + 4, 555),paint..color = const Color.fromARGB(111, 255, 255, 255) );
  myCanvas.drawLine( Offset(4, y * 50 + 4), Offset(1154, y * 50 + 5),paint..color = const Color.fromARGB(111, 255, 255, 255) );
        }
      }
    
      

    /*for(int x = 0; x < 11; x++)
    {
      for(int y = 0; y < 23; y++)
      {
        if(twoDList[y][x] == 1)
        {
myCanvas.drawRect(Offset(y * 50, x*50) & const Size(50, 50), paint..color = Color.fromARGB(255, 129, 24, 24).withOpacity(0.5), onTapDown: (tapdetail) {
         twoDList[y][x] = 0;
       }
        );
        }
        else{
    myCanvas.drawRect(Offset(y * 50, x*50) & const Size(50, 50), paint..color = Color.fromARGB(255, 73, 99, 64).withOpacity(0.5), onTapDown: (tapdetail) {
            twoDList[y][x] = 1;
       },);
        }
      }
    }
*/

  }
}
