import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class Text_Reco extends StatefulWidget {
  @override
  _Text_RecoState createState() => _Text_RecoState();
}

class _Text_RecoState extends State<Text_Reco> {
  File pickedImage; //will take image file from gallary or camera.
  bool isImageLoaded = false; //to show image on screen.
  String s = ""; //will store all the ocr text from the image.
  String defaultText = "BirthDate will be printed here..."; //default text.
  // String uploadOnceAgain = "upload photo once again";
  int angle = 90; //rotation of image, every time.
  DateTime birthDate; //will store birth-date.
  String userId, username; //will store userId and userName.
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.blue[200], Colors.red[200]])),
      child: ListView(children: <Widget>[
        Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.03,
            ),
            isImageLoaded
                ? Center(
                    child: Container(
                        height: 300.0,
                        width: 300.0,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: FileImage(pickedImage),
                                fit: BoxFit.cover))),
                  )
                : Container(
                    height: 200.0,
                    width: 200.0,
                  ),
            SizedBox(height: 15.0),
            Text(s),
            SizedBox(
              height: 100.0,
            ),
            birthDate != null && userId != null && username != null
                ? Text(birthDate.toString() + '\n' + userId + '\n' + username)
                : Text(defaultText),
            Padding(
              padding: const EdgeInsets.only(top: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: FloatingActionButton(
                      heroTag: "btn1",
                      child: Icon(Icons.photo),
                      onPressed: pickImage,
                      backgroundColor: Colors.pink,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      heroTag: "btn2",
                      child: Icon(Icons.arrow_forward_ios),
                      onPressed: findBirthDate,
                      backgroundColor: Colors.pink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ]),
    ));
  }

  //pickImage function will get image from the gallary,and store in
  //pickedImage variable.
  Future pickImage() async {
    var tempStore = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (tempStore == null) {
      Navigator.pop(context);
    }
    setState(() {
      pickedImage = tempStore;
      isImageLoaded = true;
      s = "";
      defaultText = "BirthDate will be printed here..."; //set defaultText.
      birthDate = null;
    });
    // findBirthDate();
  }
  
  //flag to stop rotation of image if ocr not able to get DOB.
  bool falgForStopingFindBirthDateFunction = true;

  //will findBirthDate by any how.
  void findBirthDate() async {

    //Number of rotaion for image.
    int counter = 0;
    // int currentTimeStamp = DateTime.now().second;
    while (falgForStopingFindBirthDateFunction == true) {

      //Logic to stop rotation after 14 seconds..NOT GOOD WAY.
      // if(DateTime.now().second-currentTimeStamp>14){
      //   birthDate=null;
      //   userId=null;
      //   username=null;
      //   setState(() {
      //   });
      //   break;
      // }

      birthDate = await readText(pickedImage);

      //for updating birthdate on UI.
      setState(() {});

      print(birthDate);

      if (birthDate == null && counter <= 3) {
        counter += 1;

        //four line for rotaion of image.
        List<int> imageBytes = await pickedImage.readAsBytes();
        var originalImage = img.decodeImage(imageBytes);
        originalImage = img.copyRotate(originalImage, angle);
        pickedImage =
            await pickedImage.writeAsBytes(img.encodeJpg(originalImage));

        setState(() {
          pickedImage = pickedImage;
          isImageLoaded = true;
        });
      } else {
        print("upload photo once again");
        break;
      }
    }

    if(counter>3)
      defaultText = "upload photo once again..";
    //for updating defaultText on UI.
    setState(() {});

    //BackTracking.
    falgForStopingFindBirthDateFunction = true;
    print('Birth Date is :${birthDate.toString()}');
  }

  //ReadText from the image.
  Future<DateTime> readText(File pickedImage) async {

    //name => store username | getNameTag => will fetch NAME tag from image.
    String name = "", getNameTag = "";

    bool flagForFinishingUserName = true; //as name suggest.
    List<DateTime> listOfDate = []; //will store list of date.

    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    // print("Start Time ${DateTime.now()}");
    VisionText rt = await recognizeText.processImage(ourImage);
    // print("End Time ${DateTime.now()}");
    if (rt.text == "") {
      angle = 90;
      return null;
    } else {
      angle = 180;
      setState(() {
        s = "";
        for (TextBlock block in rt.blocks) {
          for (TextLine line in block.lines) {
            for (TextElement word in line.elements) {
              s += " " + word.text;
              // extractDate(word.text);
              if (getNameTag == "") {
                getNameTag = matchRegXForUserName(word.text);
              } else {
                if (word.text[0] == 'N' &&
                    word.text[1] == 'A' &&
                    word.text[2] == 'T') {
                  flagForFinishingUserName = false;
                }
                if (flagForFinishingUserName) {
                  name += (word.text) + " ";
                }
              }

              var tempDate = matchRegXForDOB(word.text);
              if (tempDate != null) {
                print("..............${tempDate}");
                if (tempDate.year >= 1950 && tempDate.year <= DateTime.now().year - 20)
                  listOfDate.add(tempDate);
                else {
                  //ocr not able to captured DOB then it will stop rotation of image.
                  falgForStopingFindBirthDateFunction = false;
                  defaultText = "upload photo once again";
                }
              }

              var id = matchRegXForId(word.text);
              if (id != null) {
                userId = id;
              }
            }
          }
        }
      });

      username = name; //transfer whole username to global variable.

      if (listOfDate.isNotEmpty)
        return findOlderDate(listOfDate);
      else
        return null;
    }
  }

  String matchRegXForUserName(String name) {
    if (name.contains(new RegExp('''[NameAME]{4,5}''')) == true) {
      return name;
    } else
      return "";
  }   

  String matchRegXForId(String id) {
    RegExp regExp = RegExp('''[0-9]{11}''');
    Iterable<Match> matches = regExp.allMatches(id);
    for (Match match in matches) {
      String tempId = id.substring(match.start, match.end);
      return tempId;
    }
    return null;
  }

  DateTime matchRegXForDOB(String s) {
    RegExp regExp =
        RegExp('''[0-9]{2,4}[-|,./]{1}[0-9]{2}[-|,./]{1}[0-9]{2,4}''');
    Iterable<Match> matches = regExp.allMatches(s);
    for (Match match in matches) {
      String tempString = s.substring(match.start, match.end);
      if (tempString.contains('/')) {
        var dateTime1 = DateFormat('d/M/yyyy').parse(tempString);
        return dateTime1;
      } else if (tempString.contains('-')) {
        print("TempString is: ${tempString}");

        // why try catch?? => bcz if format of date is not yyyy-mm-dd,
        // then DateTime will throw exception so.
        try {
          var dateTime1 = DateTime.parse(tempString);
          return dateTime1;
        } catch (E) {
          return null;
        }
      } else if (tempString.contains(',')) {
        var dateTime1 = DateFormat('d,M,yyyy').parse(tempString);
        return dateTime1;
      } else if (tempString.contains('|')) {
        var dateTime1 = DateFormat('d|M|yyyy').parse(tempString);
        return dateTime1;
      } else if (tempString.contains('.')) {
        var dateTime1 = DateFormat('d.M.yyyy').parse(tempString);
        return dateTime1;
      } else if (tempString.length == 10) {
        var dateTime1 = DateFormat('yyyy-M-d').parse(tempString);
        return dateTime1;
      } else
        return null;
    }
  }

  //will find older date(Birth Date) from the list of date.
  DateTime findOlderDate(List<DateTime> listOfDate) {
    DateTime birthDate;
    int diff = 0;
    DateTime currentDate = DateTime.now();
    listOfDate.forEach((element) {
      int currentDiff = currentDate.difference(element).inDays;
      if (currentDiff > 0) {
        if (currentDiff > diff) {
          birthDate = element;
          diff = currentDiff;
        }
      }
    });
    return birthDate;
  }

  //Second logic to find date from the ocr text.
  // void extractDate(String text) {
  //   if (text.length == 10) {
  //     int countDigits = 0;
  //     int countSeperator = 0;
  //     for (int i = 0; i < text.length; i++) {
  //       try {
  //         int digit = int.parse(text[i]);
  //         countDigits += 1;
  //       } catch (e) {
  //         countSeperator += 1;
  //         continue;
  //       }
  //     }
  //     if (countDigits == 8 && countSeperator == 2) {
  //       print(text);
  //     }
  //   }
  // }
}