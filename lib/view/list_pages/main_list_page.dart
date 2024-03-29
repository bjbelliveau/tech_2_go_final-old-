import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tech_2_go_final/data/product.dart';
import 'package:tech_2_go_final/repo/json_product_repo.dart';
import 'package:tech_2_go_final/utilities/loading_dialog.dart';
import 'package:tech_2_go_final/view/detail_page/detail_page.dart';
import 'package:tech_2_go_final/view/pdf_view/pdf_page.dart';

class ListPage extends StatefulWidget {
  final String title;
  final String image;

  const ListPage({Key key, this.title, this.image}) : super(key: key);

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height / 4;
    double width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    print('Search');
                  },
                ),
              ],
              expandedHeight: height,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                centerTitle: true,
                title: Text(widget.title),
                background: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(widget.image),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5), BlendMode.srcATop),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Colors.white,
                  Color.fromRGBO(1, 137, 185, 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
                tileMode: TileMode.mirror),
          ),
          child: Center(
            child: FutureBuilder(
                future: JsonProductList().fetchProductData(),
                builder: (context, snapshot) {
                  print(snapshot.hasError ? snapshot.error : "Parsed Json");

                  return snapshot.hasData
                      ? ProductsList(
                          allProducts: snapshot.data,
                          title: widget.title,
                        )
                      : CircularProgressIndicator();
                }),
          ),
        ),
      ),
    );
  }
}

class ProductsList extends StatelessWidget {
  final List<Product> allProducts;
  final String title;

  const ProductsList({Key key, this.allProducts, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(allProducts.length);
    List<Product> currentProducts = _getCurrentProduct(title);
    String productType = currentProducts[0].type.toLowerCase();

    return productType == 'kit' || productType == 'fuser'
        ? _testListView(currentProducts)
        : _pdfListView(currentProducts);
  }

  _testListView(List<Product> products) {
    return ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          String imageString =
              products[index].group.toLowerCase().replaceAll('-', '_');

          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailPage(
                            heroTag: imageString,
                            product: products[index],
                          )));
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: <Widget>[
                  Container(
                    color: Theme.of(context).primaryColor,
                    padding: EdgeInsets.all(15.0),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            products[index].modelName,
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Montsserat',
                                fontSize: 18.0,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            products[index].group,
                            style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Montsserat',
                                fontSize: 15.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Material(
                      color: Colors.white,
//                            elevation: 2.0,
                      /*borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25.0),
                          bottomRight: Radius.circular(25.0)),*/
                      child: Hero(
                        tag: imageString,
                        child: Image.asset(
                          'assets/images/product_images/$imageString.jpg',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  List<Product> _getCurrentProduct(String title) {
    List<Product> newList = List<Product>();
    String currentType;

    switch (title.toLowerCase()) {
      case 'fusers':
        currentType = 'fuser';
        break;
      case 'kits':
        currentType = 'kit';
        break;
      case 'tips':
        currentType = 'tip';
        break;
      case 'instructions':
        currentType = 'instruction';
        break;
    }

    for (var product in allProducts) {
      if (product.type.toLowerCase() == currentType) newList.add(product);
    }

    newList.sort((a, b) =>
        a.modelName.toLowerCase().compareTo(b.modelName.toLowerCase()));

    return newList;
  }

  _pdfListView(List<Product> products) {
    String tipUrl = "https://www.laserpros.com/img/TechTips";
    String instUrl = "https://www.laserpros.com/img/Instructions";

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: products[index].list.length > 1
              ? Card(
                  child: ExpansionTile(
                    leading: Icon(
                      Icons.print,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      products[index].modelName,
                      style: TextStyle(fontSize: 20.0),
                    ),
                    children: products[index]
                        .list
                        .map<Widget>((pdf) =>
                            _getTechTipsPdfs(context, pdf, 35.0, tipUrl))
                        .toList(),
                  ),
                )
              : Card(
                  child: _getTechTipsPdfs(
                      context, products[index].list[0], 15.0, instUrl),
                ),
        );
      },
    );
  }

  _getTechTipsPdfs(
      BuildContext context, String pdf, double leftPadding, String baseUrl) {
    String pdfTitle = pdf.toUpperCase().replaceAll('-', ' ');
    String pdfUrl = "$baseUrl/$pdf.pdf";
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: leftPadding,
        right: 15.0,
      ),
      leading: Icon(
        Icons.picture_as_pdf,
        color: Colors.red[900],
      ),
      title: Text(
        pdfTitle,
        style: TextStyle(
            fontFamily: 'Montsserat',
            fontSize: 15.0,
            fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => LoadingDialog(),
        );
        File pdfFile = await _createFileOfPdfUrl(pdfUrl);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfView(
                  title: pdfTitle,
                  path: pdfFile.path,
                ),
          ),
        );
      },
    );
  }

  Future<File> _createFileOfPdfUrl(String url) async {
    final filename = "temp.pdf";
    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File('$dir/$filename');
    await file.writeAsBytesSync(bytes);
    return file;
  }

  Future<String> downloadPdf(String pdfUrl, String tempPath) async {
    var dio = Dio();
    dio.onHttpClientCreate = (HttpClient client) {
      client.idleTimeout = Duration(seconds: 0);
    };

    try {
      Response response =
          await dio.download(pdfUrl, tempPath, onProgress: (received, total) {
        String percent = (received / total * 100).toStringAsFixed(0) + "%";
        print(percent);
        return percent;
      });
      print(response.statusCode);
    } catch (exception) {
      print(exception);
    }

    return null;
  }
}
