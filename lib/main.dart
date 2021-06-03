import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart' as lip;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _image;
  final picker = ImagePicker();
  List<Image> picImages = [];

  @override
  void initState() {
    super.initState();
  }

  Future<List<LocalImage>> getLocalImages() async {
    lip.LocalImageProvider imageProvider = lip.LocalImageProvider();
    bool hasPermission = await imageProvider.initialize();
    if (hasPermission) {
      // 최근 이미지 30개 가져오기
      List<LocalImage> images = await imageProvider.findLatest(30);
      if (images.isNotEmpty) {
        return images;
      } else {
        throw "이미지를 찾을 수 없습니다.";
      }
    } else {
      throw "이미지에 접근할 권한이 없습니다.";
    }
  }

  Future getPickImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        setState(() {
          print("이미지 추가됨");
          picImages = [...picImages, Image.file(_image!)];
          // 이 부분은 나중에도 가져오려면 SharedPreparence 에 저장해줘야 한다.
        });

        print("선택된 이미지 경로 : ${_image!.path}");
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<List<LocalImage>>(
          future: getLocalImages(),
          builder: (context, snapshot) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "사진 저장하기",
                      style: TextStyle(fontSize: 50.0),
                    ),
                  ),
                ),
                Text(
                  "로컬에 저장된 최근 사진들",
                  style: TextStyle(fontSize: 20),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    children: snapshot.hasData
                        ? snapshot.data!
                            .map((e) => Image(image: DeviceImage(e)))
                            .toList()
                        : [],
                  ),
                ),
                Text(
                  "선택한 사진들",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: picImages,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        _takePhoto();
                      },
                      icon: Icon(Icons.camera_alt_outlined),
                      iconSize: 50.0,
                    ),
                    IconButton(
                      onPressed: () {
                        getPickImage();
                      },
                      icon: Icon(Icons.picture_in_picture),
                      iconSize: 50.0,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _takePhoto() async {
    final dic = await getExternalStorageDirectory();

    ImagePicker().getImage(source: ImageSource.camera).then((value) {
      if (value != null && value.path != null) {
        print("저장경로 : $dic/${value.path}");
        print("도큐먼트 디렉토리 경로 : $dic");
        GallerySaver.saveImage("${value.path}").then((value) {
          print("사진이 저장되었습니다");
        });
      }
    });
  }
}
