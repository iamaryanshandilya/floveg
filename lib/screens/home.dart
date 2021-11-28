// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String imagePath = '';
  late File? _image;
  late ImagePicker picker = ImagePicker();
  XFile? pickedFile;
  List<dynamic>? output;
  String? _retrieveDataError;
  dynamic _pickedImageError;

  bool loadingValue = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      loadingValue = true;
    });
    loadModel();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  bool chooseImageFromGallery = true;

  Future loadModel() async {
    await Tflite.loadModel(
        model: 'assets/model.tflite', labels: 'assets/labels.txt');
  }

  classifyImage(File image) async {
    output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 5,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);

    setState(() {
      loadingValue = false;
    });
  }

  set _imageFile(XFile? value) {
    pickedFile = (value == null) ? null : value;
  }

  Future pickImage() async {
    try {
      if (chooseImageFromGallery) {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else {
        pickedFile = await picker.pickImage(source: ImageSource.camera);
      }
      setState(() {
        _imageFile = pickedFile;
        _image = File(pickedFile!.path);
      });
      classifyImage(_image!);
    } catch (e) {
      setState(() {
        _pickedImageError = e;
      });
    }
  }

  Future<void> getLostData() async {
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        if (response.type == RetrieveType.image) {
          // _handleImage(response.file);
          _imageFile = response.file;
          _image = File(pickedFile!.path);
        }
      });
    } else {
      _retrieveDataError = response.exception!.code;
      // ErrorHandler()
      //     .errorDialog(context, 'Something went wrong try again later');
    }
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget onErrorDisplay(BuildContext context, String e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Text(
          // 'Something went wrong try again later',
          e,
          style: TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xff28293D),
      ),
    );
    return Image.asset(
      'assets/flower.png',
      fit: BoxFit.fill,
    );
  }

  Widget displayImage() {
    Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (pickedFile != null) {
      // return Image.network(pickedFile!.path, fit: BoxFit.cover, width: 160, height: 160,);
      return Material(
        color: Colors.transparent,
        child: Ink.image(
          image: FileImage(File(pickedFile!.path)),
          // fit: BoxFit.fill,
          // child: InkWell(onTap: onClicked),
        ),
      );
    } else if (_pickedImageError != null) {
      return onErrorDisplay(context, _pickedImageError);
    } else {
      return Image.asset(
        'assets/flower.png',
        // fit: BoxFit.fill,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width * 0.17,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.004, 1],
                        colors: [
                          Color(0xFFa8e063),
                          Color(0xFF56ab2f),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    width: MediaQuery.of(context).size.width * 0.83,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    SizedBox(
                      height: 100,
                    ),
                    Text(
                      'Teachable Machine CNN',
                      style: TextStyle(
                        color: const Color(0xFFEEDA28),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Detect Flowers',
                      style: TextStyle(
                        color: Color(0xFFE99600),
                        fontWeight: FontWeight.w500,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            color: Colors.transparent,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height - 400,
                            child: FutureBuilder<void>(
                              future: getLostData(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<void> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                  case ConnectionState.waiting:
                                    return Image.asset(
                                      'assets/flower.png',
                                      fit: BoxFit.fill,
                                    );
                                  case ConnectionState.done:
                                    return displayImage();
                                  default:
                                    if (snapshot.hasError) {
                                      return onErrorDisplay(
                                          context, snapshot.error.toString());
                                    } else {
                                      return Image.asset(
                                        'assets/flower.png',
                                        fit: BoxFit.fill,
                                      );
                                    }
                                }
                              },
                            ),
                          ),
                          (output != null)
                              ? Divider(
                                  height: 10,
                                  color: Colors.transparent,
                                )
                              : SizedBox(),
                          (output != null)
                              ? Text(
                                  '${output![0]['label']}',
                                  // style: TextStyle(color: Colors.white),
                                )
                              : SizedBox(),
                          // (output == null) ? Divider(height: 10, color: Colors.transparent,) : null,
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.transparent,
                      height: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                chooseImageFromGallery = false;
                              });
                              pickImage();
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width - 20,
                              alignment: Alignment.center,
                              // ignore: prefer_const_constructors
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 17,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  stops: const [0.004, 1],
                                  colors: [
                                    Color(0xFFa8e063),
                                    Color(0xFF56ab2f),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Take a picture'),
                            ),
                          ),
                          Divider(
                            color: Colors.transparent,
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                chooseImageFromGallery = true;
                              });
                              pickImage();
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width - 20,
                              alignment: Alignment.center,
                              // ignore: prefer_const_constructors
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 17,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  stops: const [0.004, 1],
                                  colors: [
                                    Color(0xFFa8e063),
                                    Color(0xFF56ab2f),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Choose a picture from gallery'),
                            ),
                          ),
                          Divider(
                            color: Colors.transparent,
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                imagePath = '';
                                _image = null;
                                pickedFile = null;
                                _retrieveDataError = null;
                                output = null;
                              });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width - 20,
                              alignment: Alignment.center,
                              // ignore: prefer_const_constructors
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 17,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  stops: const [0.004, 1],
                                  colors: [
                                    Color(0xFFa8e063),
                                    Color(0xFF56ab2f),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Reset to defaults'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.transparent,
                      height: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
