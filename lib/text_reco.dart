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
  String nationality; //will store nationality of the person.
  // bool flagForNationality=true;
  // String flagStringForNationality = "";

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
            birthDate != null && userId != null && username!=null && nationality!=""
                ? Text(birthDate.toString() +
                    '\n' +
                    userId +
                    '\n' +
                    username +
                    '\n' +
                    nationality)
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
      s = ""; //will store every extracted word from image.
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

      print(birthDate); //for debug.


      if (birthDate == null && counter <= 3 && falgForStopingFindBirthDateFunction==true) {
        counter += 1; //for every rotation.
        if(angle==180){
          counter += 1; //for skipping one rotation if angle is 180, so increment counter by 1.
        }

        //four line for rotaion of image.
        List<int> imageBytes = await pickedImage.readAsBytes();
        var originalImage = img.decodeImage(imageBytes);
        originalImage = img.copyRotate(originalImage, angle);
        pickedImage =
            await pickedImage.writeAsBytes(img.encodeJpg(originalImage));

        setState(() {
          pickedImage = pickedImage; //replace original image with rotated image.
          isImageLoaded = true;
        });
      } else {
        print("upload photo once again");
        break;
      }
    }

    if (counter > 3) defaultText = "upload photo once again,image is not clear.";
    //for updating defaultText on UI.
    setState(() {});

    //BackTracking for new image.
    falgForStopingFindBirthDateFunction = true;
    print('Birth Date is :${birthDate.toString()}');
  }

  //ReadText from the image.
  Future<DateTime> readText(File pickedImage) async {
    //name => store username | getNameTag => will fetch NAME tag from image.
    //nationality => store nationality of person from document
    //getNationalityTag => will fetch Nationality tag from image.
    String name = "", getNameTag = "", nationality = "", getNationalityTag = "";
    DateTime bd; //will store birthdate temperorily.
    bool flagForFinishingBirthDate = false;// as name suggest.
    bool flagForFinishingUserName = true; //as name suggest.
    bool flagForFinishingNationality = true; //as name suggest.

    // List<DateTime> listOfDate = []; //will store list of date.

    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText rt = await recognizeText.processImage(ourImage); //will store
    // total ocr extracted text.
    
    if (rt.text == "") {
      angle = 90; //bcz, this time image might be verticale so rt="" and we
      // have to rotate it 90 degree in order to convert image into horizonatal.
      return null;
    } else {
      angle = 180; //here, image would be horizonatal, but we don't know its undhi or chitti
      // so angle would be 180.
      setState(() {
        s = "";
        for (TextBlock block in rt.blocks) {
          for (TextLine line in block.lines) {
            //for match "NAT.INDIA" like nationality (Line wise).
            if (nationality == "") {
              var nat = matchRegxForNationality1(line.elements);
              if (nat != "") {
                nationality = nat;
              }
            }

            // for finding birth date from extracted line of word.
            if (birthDate == null) {
              var tempDate = matchRegXForDOB1(line);
              if (tempDate != null){

                //if, for validating birthdate.
                if(tempDate.year >= 1950 &&
                  tempDate.year <= DateTime.now().year - 18){
                    bd=tempDate;
                    flagForFinishingBirthDate=false;
                  }
                else{
                  if(bd==null)
                    flagForFinishingBirthDate=true;
                }
                  // listOfDate.add(tempDate);
                  
                // else{
                //   if(listOfDate.isEmpty){
                //     //showToast
                //     print("you are not eligible");
                //     falgForStopingFindBirthDateFunction = false;
                //   }
                // }
              }
                  
              // else {
              //   //ocr not able to captured DOB then it will stop rotation of image.
              //   falgForStopingFindBirthDateFunction = false;
              //   defaultText = "upload photo once again";
              // }
            }

            // line.elements.forEach((element) {
            //   print(element.text);
            // });

            for (TextElement word in line.elements) {
              s += " " + word.text;
              // extractDate(word.text);

              //for extracting UserName.
              if (getNameTag == "") {
                getNameTag = matchRegXForUserName(word.text);
              } else {
                try{
                  if (word.text[0] == 'N' &&
                    word.text[1] == 'A' &&
                    word.text[2] == 'T') {
                    flagForFinishingUserName = false;
                  }
                  if (flagForFinishingUserName) {
                    name += (word.text) + " ";
                  }
                }
                catch(E){
                  print(E);
                }
              }

              //for extracting DOB
              // if (birthDate == null) {
              //   var tempDate = matchRegXForDOB(word.text);
              //   if (tempDate != null) {
              //     print("..............${tempDate}");
              //     if (tempDate.year >= 1950 &&
              //         tempDate.year <= DateTime.now().year - 20)
              //       listOfDate.add(tempDate);
              //     else {
              //       //ocr not able to captured DOB then it will stop rotation of image.
              //       falgForStopingFindBirthDateFunction = false;
              //       defaultText = "upload photo once again";
              //     }
              //   }
              // }

              //for extracting Id
              var id = matchRegXForId(word.text);
              if (id != null) {
                userId = id;
              }

              //for extracting Nationality
              // if(nationality==""){
              //   var nat = matchRegxForNationality1(word.text);
              //   if (nat != "") {
              //     nationality = nat;
              //   }
              // }

              //for match nationality like (NAT INDIA) word by word.
              if (nationality == "") {
                if (getNationalityTag == "") {
                  getNationalityTag = matchRegxForNationality2(word.text);
                } else {
                  if (word.text[0] == 'O' &&
                      word.text[1] == 'c' &&
                      word.text[2] == 'c' &&
                      word.text[3] == 'u' &&
                      word.text[4] == 'p' &&
                      word.text[5] == 'a' &&
                      word.text[6] == 't' &&
                      word.text[7] == 'i' &&
                      word.text[8] == 'o' &&
                      word.text[9] == 'n') {
                    flagForFinishingNationality = false;
                  }
                  if (flagForFinishingNationality) {
                    nationality += (word.text) + " ";
                    print(nationality);
                  }
                }
              }
            }
          }
        }
      });

      this.username = name; //transfer whole username to global variable.
      this.nationality = nationality; // transfer whole nationality to this.nationality.

      if(bd==null && flagForFinishingBirthDate==false){
        falgForStopingFindBirthDateFunction = true;
        return null;
      }
      else if(flagForFinishingBirthDate==true){
        //showToast on UI that user is not eligible bcz his age is less than 18.
        print("you are not eligible.");
        falgForStopingFindBirthDateFunction = false;
        return null;
      }
      else{
        return bd;
      }
      // if (listOfDate.isNotEmpty)
      //   return findOlderDate(listOfDate);
      // else {
      //   falgForStopingFindBirthDateFunction = true;
      //   defaultText="";
      //   return null;
      // }
    }
  }

  String matchRegxForNationality1(List<TextElement> nationalityStringLine) {
    String tempStringLine = "";
    for (var word in nationalityStringLine) {
      tempStringLine += (word.text);
    }
    tempStringLine = tempStringLine.trim();
    // nationality = nationalityStringLine.replaceAll(' ', '');

    //if for driving licence of quatar.
    if (tempStringLine.contains(new RegExp('''NAT[.a-zA-Z]'''))) {
      if (tempStringLine[3] != '.')
        return tempStringLine.substring(3);
      else
        return tempStringLine.substring(4);
    }

    return "";
  }

  String matchRegxForNationality2(String nationalityStringLine) {

    print(nationalityStringLine);

    //for residency permit of quatar.
    if (nationalityStringLine
        .contains(new RegExp('''[Nationality:]{11,12}'''))) {
      return nationalityStringLine;
      // // flagStringForNationality+=nationalityStringLine;
      // if(nationalityStringLine.length>11)
      //   return nationalityStringLine.substring(11);
      // flagForNationality = false;
      // return null;
      // return nationalityStringLine.substring(12);
      // return "getNextWord"; //bcz nextWord will be nationality of person.
    } else
      return "";
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

  DateTime matchRegXForDOB1(TextLine line) {
    String temp = "";
    line.elements.forEach((element) {
      temp += (element.text);
    });

    print(temp);

    RegExp regExp =
        RegExp('''[0-9]{2,4}[-|,./]{1}[0-9]{2}[-|,./]{1}[0-9]{2,4}''');
    Iterable<Match> matches = regExp.allMatches(temp);
    for (Match match in matches) {
      String tempString = temp.substring(match.start, match.end);
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
      } else
        return null;
    }
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
  // DateTime findOlderDate(List<DateTime> listOfDate) {
  //   DateTime birthDate;
  //   int diff = 0;
  //   DateTime currentDate = DateTime.now();
  //   listOfDate.forEach((element) {
  //     int currentDiff = currentDate.difference(element).inDays;
  //     if (currentDiff > 0) {
  //       if (currentDiff > diff) {
  //         birthDate = element;
  //         diff = currentDiff;
  //       }
  //     }
  //   });
  //   return birthDate;
  // }

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
