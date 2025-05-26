import 'package:flutter/material.dart'; 
 
void main() => runApp(MyApp()); 
 
// ignore: must_be_immutable 
class MyApp extends StatelessWidget { 
  var subject = 'English'; 
 
  MyApp({Key? key}) : super(key: key); 
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      home: Scaffold( 
        appBar: AppBar( 
          title: const Text('Stateful Widget'), 
        ), 
        body: Column( 
          children: [ 
            const Text('What is your favorite subject?'), 
            ElevatedButton( 
              style: ElevatedButton.styleFrom( 
                backgroundColor: Colors.teal, 
                foregroundColor: Colors.white, 
              ), 
              onPressed: () => subject = 'English', 
              child: const Text('English'), 
            ), 
            ElevatedButton( 
              style: ElevatedButton.styleFrom( 
                backgroundColor: Colors.teal, 
                foregroundColor: Colors.white, 
              ), 
              onPressed: () => subject = 'Mathematics', 
              child: const Text('Mathematics'), 
            ), 
            ElevatedButton( 
              style: ElevatedButton.styleFrom( 
                backgroundColor: Colors.teal, 
                foregroundColor: Colors.white, 
              ), 
              onPressed: () => subject = 'Science', 
              child: const Text('Science'), 
            ), 
            Text('chnaginggg ' + subject), 
          ], 
        ), 
      ), 
    ); 
  } 
}  
 
