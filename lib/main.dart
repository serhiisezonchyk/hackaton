import 'dart:convert';
//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:hackathon/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Constants.prefs = await SharedPreferences.getInstance();
  runApp(MyApp());
}


class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

TextStyle ts = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
);


Widget formField(String whatFor, TextEditingController controller, bool isObsecure) {
    return  Row(
      children: <Widget>[
        Text(whatFor,style: ts,),
        const SizedBox(width: 18),
        Flexible(
          child: TextFormField(
            controller: controller,
            obscureText: isObsecure,
            keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter "$whatFor" here'
              ),
          // The validator receives the text that the user has entered.
          validator: (value) {
            if (value.isEmpty) {
              return 'Please enter correct value';
            }
            return null;
          },
          ),
        ),]
    );
}

class _LoginPageState extends State<LoginPage> {

  final _formKey = GlobalKey<FormState>();

  TextEditingController phone = new TextEditingController(text: "+380978954632");
  TextEditingController password = new TextEditingController(text: "password");

  @override
  Widget build(BuildContext context) {
    return Container(
         child: Form(
           key:  _formKey,
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
             formField("phone", phone, false),
             formField("password", password, true),
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: ElevatedButton(
            onPressed: () async {
                // Validate returns true if the form is valid, otherwise false.
                if (_formKey.currentState.validate()) {

                  Constants.prefs.setBool('loggedIn', true);
                  
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BasePage(NewsPage())),
                    );
                    
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.

                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(SnackBar(content: Text('Processing Data')));
                }
            },
            child: Text('Submit'),
          ),
             ),
           ],),)
      );
  }
}


class BasePage extends StatefulWidget {
  @override
  _BasePageState createState() => _BasePageState();

  Widget center;
  bool showBottomTab;

  BasePage(this.center, {this.showBottomTab = true});
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static List<Widget> _widgetOptions = <Widget>[
    
    NewsPage(),
    PartnersPage(),
    ExcursionsPage(),
    GoodsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chernihiv.online'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: !widget.showBottomTab ? null : 
        BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Новини',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Партнери',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Екскурсії',
          ),
            BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Товари',
          )
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.grey[600],
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CheOnline',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: (Constants.prefs.getBool("loggedIn") == null || !Constants.prefs.getBool("loggedIn"))  ? BasePage(LoginPage(), showBottomTab: true, ) : BasePage(NewsPage()),
    );
  }
}


class Article{
  String title;
  String url;
  String description;

  Article(String title, String url, String desc){
    this.title = title; this.url = url; this.description = desc;
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    print(json);
    return Article(
      json['contents'],
      json['news_pic_url'],
      json['news_text'],
    );
  }
}


Future<Article> fetchNews() async {
   Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

  final response = await http.get(Uri.http('127.0.0.1:5000', '/news/list/'), headers: headers);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      print(response.body);
      final jsonresp = json.decode(response.body);
      return Article.fromJson(jsonresp [0]);
    } else {
      print(response.body);
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
}

class NewsPage extends StatelessWidget {

  List<Article> items = new List(10);
  

  @override
  Widget build(BuildContext context) {
    Article article = new Article("Lorem ipsum", "news.png", "Lorem ipsumLorem ipsumLorem ipsumLorem ipsum");
    for (int i = 0; i < items.length; i++){
      items[i] = article;
    }
    Future<Article> futureArticle;

    futureArticle = fetchNews();

    return FutureBuilder<Article>(
      future: futureArticle,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index){
              return NewsCard(items[index].title, items[index].url, items[index].description, "Перейти до новини");
            });
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        // By default, show a loading spinner.
        return CircularProgressIndicator();
      },
    );
  }
}


class NewsCard extends StatelessWidget {

  NewsCard(this.title, this.url, this.description, this.buttonText);

  String url;
  String title;
  String description;
  String buttonText;

  @override
  Widget build(BuildContext context) {
    return Container(
        child : Card(
          child: Column(children: <Widget>[
            SizedBox(height: 250, child: Image(image: AssetImage(url))),
            ListTile(
              title: Text(title),
              subtitle: Text(description),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  child: Text(buttonText),
                  onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConcreteNews()),
                      );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
      ),
        ),
    );
  }
}


class Partner{
  String title;
  String image;
  String description;

  Partner(String title, String image, String desc){
    this.title = title; this.image = image; this.description = desc;
  }
  
  factory Partner.fromJson(Map<String, dynamic> json) {
    print(json);
    return Partner(
      json['name'],
      json['link'],
      json['description'],
    );
  }
}


Future<Partner> fetchPartners() async {
   Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

  final response = await http.get(Uri.http('127.0.0.1:5000', '/partners/list/'), headers: headers);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      print(response.body);
            final jsonresp = json.decode(response.body);
      return Partner.fromJson(jsonresp [0]);
      
    } else {
      print(response.body);
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
}
class PartnersPage extends StatelessWidget {
 List<Partner> items = new List(10);
  
  @override 
  Widget build(BuildContext context){
  Partner partner = new Partner("Lorem ipsum", "news.png", "Lorem ipsumLorem ipsumLorem ipsumLorem ipsum");
    for (int i = 0; i < items.length; i++){
      items[i] = partner;
    }
    Future<Partner> futurePartner;
    futurePartner = fetchPartners();
    return FutureBuilder<Partner>(
      future: futurePartner,
      builder: (context,snapshot){
        if(snapshot.hasData){
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context,index){
              return PartnerCard(items[index].title,items[index].image, items[index].description);
            });
        }else if(snapshot.hasError){
          return Text("${snapshot.error}");
        }
         return CircularProgressIndicator();
      }
    );
  }
}




class PartnerCard extends StatefulWidget {
  PartnerCard(this.title, this.url, this.description);

  String url;
  String title;
  String description;

  @override
  _PartnerCardState createState() => _PartnerCardState();
}

class _PartnerCardState extends State<PartnerCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child : Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: <Widget>[
              ClipOval(
                child: Image.network(
                  widget.url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Flexible(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(widget.title),
                      subtitle: Text(widget.description),
                    )
                  ],
                ),
              ),
              ]
            ),
        ),
      ),
    );
  }
}


class ConcreteNews extends StatefulWidget {
  @override
  _ConcreteNewsState createState() => _ConcreteNewsState();
}

class _ConcreteNewsState extends State<ConcreteNews> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chernihiv.online'),
      ),
      body: Center(
        
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Новини',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Партнери',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Екскурсії',
          ),
            BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Товари',
          )
        ],
      ),
    );
  }
}


class Excursion{
  String title;
  String image;
  String description;

  Excursion(String title, String image, String desc){
    this.title = title; this.image = image; this.description = desc;
  }
    factory Excursion.fromJson(Map<String, dynamic> json) {
    print(json);
    return Excursion(
      json['name'],
      json['link'],
      json['description']
    );
  }
}


class ExcursionsPage extends StatefulWidget {
  @override
  _ExcursionsPageState createState() => _ExcursionsPageState();
}


Future<Excursion> fetchExcursion() async{
     Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    final response = await http.get(Uri.http('127.0.0.1:5000', '/excursions/list/'), headers: headers);
     if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      print(response.body);
            final jsonresp = json.decode(response.body);
      return Excursion.fromJson(jsonresp [0]);
    } else {
      print(response.body);
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
}


class _ExcursionsPageState extends State<ExcursionsPage> {
  List<Excursion> items = new List(10);
  

  @override
  Widget build(BuildContext context) {
    Excursion excursion = new Excursion("Lorem ipsum", "news.png", "Lorem ipsumLorem ipsumLorem ipsumLorem ipsum");
    for (int i = 0; i < items.length; i++){
      items[i] = excursion;
    }
    Future<Excursion> futureExcursion;

    futureExcursion = fetchExcursion();

        return FutureBuilder<Excursion>(
      future: futureExcursion,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index){
              return ExcursionCard(items[index].title, items[index].image, items[index].description);
            });
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        // By default, show a loading spinner.
        return CircularProgressIndicator();
      },
    );
  }
  }
  class ExcursionCard extends StatefulWidget {
  ExcursionCard(this.title, this.url, this.description);

  String url;
  String title;
  String description;

  @override
  _ExcursionCardState createState() => _ExcursionCardState();
}

class _ExcursionCardState extends State<ExcursionCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child : Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: <Widget>[
              ClipOval(
                child: Image.network(
                  widget.url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Flexible(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(widget.title),
                      subtitle: Text(widget.description),
                    )
                  ],
                ),
              ),
              ]
            ),
        ),
      ),
    );
  }
}
  class Goods{
  String title;
  String image;
  String description;
  String price;

    Goods(String title, String url, String desc, String price){
    this.title = title; this.image = url; this.description = desc; this.price = price;
  }
    factory Goods.fromJson(Map<String, dynamic> json) {
    print(json);
    return Goods(
      json['name'],
      json['link'],
      json['description'],
      json['price']
    );
  }
}

class GoodsPage extends StatefulWidget {
  @override
  _GoodsPageState createState() => _GoodsPageState();
}


Future<Goods> fetchGoods() async{
     Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    final response = await http.get(Uri.http('127.0.0.1:5000', '/goods/list/'), headers: headers);
     if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      print(response.body);
            final jsonresp = json.decode(response.body);
      return Goods.fromJson(jsonresp [0]);
    } else {
      print(response.body);
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
}


class _GoodsPageState extends State<GoodsPage> {
  List<Goods> items = new List(10);
  

  @override
  Widget build(BuildContext context) {
    Goods goods = new Goods("Lorem ipsum", "news.png", "Lorem ipsumLorem ipsumLorem ipsumLorem ipsum","xxxx");
    for (int i = 0; i < items.length; i++){
      items[i] = goods;
    }
    Future<Goods> futureGoods;

    futureGoods = fetchGoods();

      return FutureBuilder<Goods>(
      future: futureGoods,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index){
              return GoodsCard(items[index].title, items[index].image, items[index].description, items[index].price);
            });
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        // By default, show a loading spinner.
        return CircularProgressIndicator();
      },
    );
  }
  }
  class GoodsCard extends StatefulWidget {
  GoodsCard(this.title, this.url, this.description, this.price);

  String url;
  String title;
  String description;
  String price;

  @override
  _GoodsCardState createState() => _GoodsCardState();
}

class _GoodsCardState extends State<GoodsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child : Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: <Widget>[
              ClipOval(
                child: Image.network(
                  widget.url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Flexible(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(widget.title),
                      subtitle: Text(widget.description),
                      leading: Text(widget.url),
                    )
                  ],
                ),
              ),
              ]
            ),
        ),
      ),
    );
  }
}


