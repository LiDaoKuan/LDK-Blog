---
title: Flutter基础
date: 2026-02-15
updated: 2026-02-19
tags: [Dart, Flutter]
categories: Flutter
description: Flutter基础
---

#### Flutter无状态组件

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

// 无状态组件
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  // 重写build方法
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter 无状态组件",
      theme: ThemeData(scaffoldBackgroundColor: Colors.green),
      home: Scaffold(
        appBar: AppBar(title: Text('头部标题栏')),
        body: Container(child: Center(child: Text('中部区域'))),
        bottomNavigationBar: Container(
          height: 100,
          child: Center(child: Text('底部栏')),
        ),
      ),
    );
  }
}
```

#### Flutter有状态组件

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

// 有状态组件
// Widget类 对外
class MainPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

// state类 对内，负责管理数据，处理业务逻辑，渲染视图。
class _MainPageState extends State<MainPage>{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Base",
      theme: ThemeData(scaffoldBackgroundColor: Colors.green),
      home: Scaffold(
        appBar: AppBar(title: Text('头部标题栏')),
        body: Container(
          child: Center(child: Text('中部区域')),
        ),
        bottomNavigationBar: Container(
          height: 100,
          child: Center(child: Text('底部栏')),
        ),
      ),
    );
  }
}
```

#### Container组件

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          transform: Matrix4.rotationZ(0.2), // 以左上角为支点，绕三维Z轴旋转（垂直于屏幕的轴），单位是弧度
          margin: EdgeInsets.all(10), // 设置外边距（all: 前后左右都有）
          alignment: Alignment.center, // 前后左右居中
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(15), // 圆角
            border: Border.all(width: 3, color: Colors.yellow), // 边框宽度和颜色
          ),
          child: Text(
            "Hello, Container!",
            style: TextStyle(color: Colors.white), // 设置文本颜色
          ),
        ),
      ),
    );
  }
}
```

#### Center组件

center组件不能设置宽和高，会尽可能多的向父组件申请空间。

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Center 代码实例'), centerTitle: true),
        body: Center(
          child: Container(
            alignment: Alignment.center, // 设置child的居中方式
            width: 100,
            height: 100,
            color: Colors.red,
            child: Text('居中内容', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
```

#### Align组件

精确控制子组件在其父组件中的对其位置。

- `alignment`: 对其方式。子组件在父组件中的对其方式
- `widthFactor`: 宽度因子。Align的宽度将是其子组件的宽度乘以该因子。
- `heightFactor`: 高度因子。Align的高度将是其子组件的高度乘以该因子。

`widthFactor`和`heightFactor`在动态布局中很有用。

Center组件其实是Align组件的一个特例，Center继承自Align。

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Align 代码实例'), centerTitle: true),
        body: Container(
          // Container的大小默认和子组件相同？？
          color: Colors.red,
          child: Align(
            alignment: Alignment.center,
            widthFactor: 2, // Align的宽度是子组件Icon的两倍
            heightFactor: 2,
            child: Icon(
              Icons.star, // 五角星
              color: Colors.yellow,
              size: 150, // 宽和高
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Padding组件

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Padding 代码实例'), centerTitle: true),
        body: Container(
          padding: EdgeInsets.all(30), // Container组件本身有padding属性
          // padding: EdgeInsets.only(top: 30, left: 30), // 仅仅设置上部和左部
          // padding: EdgeInsets.symmetric(horizontal: 200, vertical: 20), // 设置对称方向的内边距
          decoration: BoxDecoration(color: Colors.amber),
          child: Padding(
            // padding: EdgeInsets.all(30), // Padding组件的padding属性，效果与Container组件的padding属性一样
            // padding: EdgeInsets.only(top: 30, left: 30), // 仅仅设置上部和左部
            padding: EdgeInsets.symmetric(
              horizontal: 200,
              vertical: 20,
            ), // 设置对称方向的内边距
            child: Container(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
```

#### Column组件

父组件的大小会直接影响Column组件的大小。

> Column组件不支持滚动！

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Column 代码实例'), centerTitle: true),
        body: Container(
          decoration: BoxDecoration(color: Colors.amber),
          width: double.infinity, // 宽度尽可能占满空间
          child: Column(
            // 主轴(垂直方向)对齐方式：
            // mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两头对齐，中间居中
            // mainAxisAlignment: MainAxisAlignment.spaceAround, // 环绕模式
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 均分模式
            // mainAxisAlignment: MainAxisAlignment.start, // 从头开始（默认对齐方式）
            // mainAxisAlignment: MainAxisAlignment.end, // 从尾部开始
            mainAxisAlignment: MainAxisAlignment.center, // 全部居中
            // 交叉轴（水平方向）对齐方式：
            // crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            // crossAxisAlignment: CrossAxisAlignment.end, // 右对齐
            crossAxisAlignment: CrossAxisAlignment.center, // 居中
            children: [
              Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: Text("111"),
              ),
              SizedBox(
                height: 10, // SizedBox: 用于为子组件提供固定的宽度和高度约束，或者在布局中创建空白空间
              ),
              Container(
                width: 100,
                height: 100,
                color: Colors.pink,
                child: Text("222"),
              ),
              SizedBox(height: 10),
              Container(
                width: 100,
                height: 100,
                color: Colors.red,
                child: Text("333"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Row组件

原理与Column组件相同。Row组件也不支持滚动。

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Row 代码实例'), centerTitle: true),
        body: Container(
          decoration: BoxDecoration(color: Colors.amber),
          height: double.infinity, // 高度尽可能占满空间
          child: Row(
            // 主轴(水平方向)对齐方式：
            // mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两头对齐，中间居中
            // mainAxisAlignment: MainAxisAlignment.spaceAround, // 环绕模式
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 均分模式
            // mainAxisAlignment: MainAxisAlignment.start, // 从头开始（默认对齐方式）
            // mainAxisAlignment: MainAxisAlignment.end, // 从尾部开始
            mainAxisAlignment: MainAxisAlignment.center, // 全部居中
            // 交叉轴(垂直方向)对齐方式：
            // crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            // crossAxisAlignment: CrossAxisAlignment.end, // 右对齐
            crossAxisAlignment: CrossAxisAlignment.center, // 居中
            children: [
              Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: Text("111"),
              ),
              SizedBox(
                width: 10, // SizedBox: 用于为子组件提供固定的宽度和高度约束，或者在布局中创建空白空间
              ),
              Container(
                width: 100,
                height: 100,
                color: Colors.pink,
                child: Text("222"),
              ),
              SizedBox(width: 10),
              Container(
                width: 100,
                height: 100,
                color: Colors.red,
                child: Text("333"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 弹性布局：Flex/Expanded/Flexible

用`Expanded`/`Flexible`作为`Flex`的子组件，通过`flex`属性来分配`Flex`组件空间。

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Flex 代码实例'), centerTitle: true),
        body: Container(
          decoration: BoxDecoration(color: Colors.amber),
          width: double.infinity,
          height: double.infinity, // 高度尽可能占满空间
          child: Flex(
            direction: Axis.horizontal, // 水平方向为主轴。默认主轴和交叉轴都是居中对齐
            children: [
              Expanded(
                flex: 1, // 主轴方向占总份的1份。子组件的宽度width设置会失效
                child: Container(
                  alignment: Alignment.center,
                  width: 100, // 已经失效
                  height: 100,
                  color: Colors.blue,
                  child: Text("111"),
                ),
              ),
              Expanded(
                flex: 4, // 主轴方向占总份的4份
                child: Container(
                  alignment: Alignment.center,
                  width: 100,
                  height: 100,
                  color: Colors.pink,
                  child: Text("222"),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.center,
                  width: 100,
                  height: 100,
                  color: Colors.red,
                  child: Text("333"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Wrap 流式布局

流式布局组件，当子组件在主轴方向上排列不下时，它会在自动换行（或换列）。`Wrap`组件更像是"`Flex`组件加了还行特性". 但是`Wrap`组件的默认主轴居中方式和`Flex`组件不同。

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Wrap 代码实例'), centerTitle: true),
        body: Container(
          decoration: BoxDecoration(color: Colors.amber),
          width: double.infinity,
          height: double.infinity, // 高度尽可能占满空间
          child: Wrap(
            spacing: 10, // 主轴间距
            runSpacing: 10, // 交叉轴间距
            direction: Axis.vertical, // 垂直为主轴。
            alignment: WrapAlignment.center, // 主轴对齐方式
            children: getList(100),
          ),
        ),
      ),
    );
  }

  List<Widget> getList(int len){
    var list = List.generate(len, (index){
      return Container(
        alignment: Alignment.center,
        width: 100,
        height: 100,
        color: Colors.blue,
        child: Text(index.toString()),
      );
    });
    return list;
  }
}
```

#### Stack/Positioned 层叠布局

层叠布局组件允许将多个子组件按照Z轴方向（垂直于电脑屏幕）进行叠加排列。

Positioned组件只能作为Stack组件的直接子组件。

```dart

```

#### Text组件

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Text 代码实例'), centerTitle: true),
        body: Container(
          decoration: BoxDecoration(color: Colors.amber),
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity, // 高度尽可能占满空间
          child: Text(
            "Hello Flutter! 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567"
            "89, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890,"
            "1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890,"
            "1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890, 1234567890,",
            style: TextStyle(
              fontSize: 30,
              color: Colors.lightBlue,
              fontStyle: FontStyle.italic, // 斜体
              fontWeight: FontWeight(900), // 字体粗细
              decoration: TextDecoration.underline, // 下划线
              decorationColor: Colors.red,
            ),
            maxLines: 2, // 设置最多显示两行
            overflow: TextOverflow.ellipsis, // 多出部分显示省略号
          ),
        ),
      ),
    );
  }
}
```

#### Text.rich/TextSpan

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Text.rich/TextSpan 代码实例'),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.amber),
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity, // 高度尽可能占满空间
          child: Text.rich(
            TextSpan(
              text: "Hello ",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 50,
                fontStyle: FontStyle.italic,
              ),
              children: [
                TextSpan(
                  text: 'Flutter',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 30,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.pink,
                  ),
                ),
                TextSpan(
                  text: '!',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Image组件

本地图片需要在pubspec.lock中配置路径
```yaml
flutter:
  assets:
    - /lib/images  # 引入整个文件夹
```

另外，`Android，HarmonyOS，IOS`使用`Image.network`时需要配置网络权限。

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Image 代码实例'),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.amber),
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity, // 高度尽可能占满空间
          child: Column(
            children: [
              // 本地图片
              Image.asset(
                "lib/image/001.png",
                width: 1000,
                height: 200,
                fit: BoxFit.contain, // 默认。尽可能大，保持图片分辨率（满足长或者宽, 但是不截断）。
                // fit: BoxFit.fill, // 充满父容器（拉伸）
                // fit: BoxFit.cover, // 充满父容器（裁减）
                // fit: BoxFit.none, // 图片按照原分辨率居中显示，但是可能被截断（width和height太小）
                // fit: BoxFit.fitWidth, // 图片填满宽度，高度可能会被截断
                // fit: BoxFit.fitHeight, // 图片填满高度，宽度可能会被截断
                // fit: BoxFit.scaleDown // 尽可能大，但是最大不超过图片原大小。同时保证不发生截断。
              ),

              // 网路图片
              Image.network(
                "https://4kwallpapers.com/images/walls/thumbs_3t/25479.jpg",
                width: 1000,
                height: 200,
                fit: BoxFit.contain
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### TextField 文本输入

要使用`TextField`，前提必须是在**有状态组件**内。

```dart
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(
    MaterialApp(
      home: MainPage(), // 正确包裹 MainPage
      title: 'Login Demo',
    ),
  );
}

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  TextEditingController _accountController = TextEditingController(); // 账号的控制器
  TextEditingController _passwordController = TextEditingController(); // 密码的控制器

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("登录"), centerTitle: true),
        body: Container(
          padding: EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: '请输入账号',
                  fillColor: Colors.yellow, // 填充颜色
                  filled: true, // 允许填充
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none, // 不显示边框
                    borderRadius: BorderRadius.circular(20), // 圆角
                  ),
                  contentPadding: EdgeInsets.only(left: 20), // 内容内边距
                ),
                controller: _accountController, // 绑定控制器
                // 输入框变化时执行函数：
                onChanged: (value) {
                  print(value);
                },
                // 提交时执行的函数（在web端由回车操触发, 登录按钮不会触发此函数！！！）
                onSubmitted: (value) {
                  print(value);
                },
              ),
              SizedBox(height: 10),
              TextField(
                obscureText: true, // 密码隐藏
                decoration: InputDecoration(
                  hintText: '请输入密码',
                  fillColor: Colors.yellow, // 填充颜色
                  filled: true, // 允许填充
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none, // 不显示边框
                    borderRadius: BorderRadius.circular(20), // 圆角
                  ),
                  contentPadding: EdgeInsets.only(left: 20), // 内容内边距
                ),
                controller: _passwordController,
              ),
              SizedBox(height: 10),
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                ),
                child: TextButton(
                  onPressed: () {
                    // 获取输入的账号和密码
                    String account = _accountController.text;
                    String password = _passwordController.text;

                    // 显示弹窗
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("登录信息"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("账号: $account"),
                              SizedBox(height: 10),
                              Text("密码: $password"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("确定"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text("登录", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 滚动组件

##### SingleChildScrollView

让单个子组件可以滚动，所有内容一次性渲染。

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('SingleChildScrollView')),
        body: Stack(
          children: [
            // 只能包含一个组件，如果滚动多个组件，通常它们嵌套在Column或者Row中
            // 通过scrollDirection属性控制滚动方向，默认为垂直方向（Axis.vertical）
            // 特点：一次性构建所有组件，如果嵌套的Column或者Row包含大量子组件，可能导致性能问题。
            // 控制滚动：绑定一个ScrollController对象，通过animateTo/jumpTo方法控制滚动。
            SingleChildScrollView(
              padding: EdgeInsets.all(20),
              controller: _scrollController,
              child: Column(
                children: List.generate(100, (index) {
                  return Container(
                    margin: EdgeInsets.only(top: 10),
                    width: double.infinity,
                    height: 100,
                    color: Colors.blue,
                    alignment: Alignment.center,
                    child: Text(
                      '我是第${index + 1}个',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              right: 10, // 右边距为10
              top: 10, // 上边距为10
              child: GestureDetector(
                onTap: () {
                  // print('去顶部');
                  // _scrollController.jumpTo(0); // 不带动画跳转
                  // 带动画的跳转
                  _scrollController.animateTo(
                    0,
                    duration: Duration(seconds: 1),
                    curve: Curves.easeIn,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.red,
                  ),
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  child: Text('去顶部', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              right: 10, // 右边距为10
              bottom: 10, // 上边距为10
              child: GestureDetector(
                onTap: () {
                  // print("去底部");
                  // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  // 带动画的跳转
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(seconds: 1),
                    curve: Curves.bounceIn,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.red,
                  ),
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  child: Text('去底部', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

##### ListView

线性列表，通过build可以实现懒加载，性能优异。


##### `ListView.builder()`

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('ListView builder')),
        body: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Container(
              margin: EdgeInsets.only(top: 10),
              width: double.infinity,
              height: 100,
              color: Colors.blue,
              alignment: Alignment.center,
              child: Text(
                '我是第${index + 1}个',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            );
          },
          itemCount: 100, // 列表长度
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
```

###### `ListView.seperate()`

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('ListView separate')),
        body: ListView.separated(
          itemCount: 100, // 列表长度
          itemBuilder: (BuildContext context, int index) {
            return Container(
              width: double.infinity,
              height: 100,
              color: Colors.blue,
              alignment: Alignment.center,
              child: Text(
                '我是第${index + 1}个',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            );
          },
          // 列表项间隔
          separatorBuilder: (context, index) {
            return Container(
              height: 10,
              width: double.infinity,
              color: Colors.yellow,
            );
          },
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
```

##### GridView

网格布局列表，支持懒加载，可以固定列数。

##### CustomScrollView

复杂布局方案，通过组合多个Sliver组件实现滚动。

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('CustomScrollView')),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.blue,
                alignment: Alignment.center,
                height: 260,
                child: Text(
                  '轮播图',
                  style: TextStyle(color: Colors.red, fontSize: 30),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverPersistentHeader(
              delegate: _StickCategory(),
              pinned: true, // 固定吸顶
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverList.separated(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 100,
                  color: Colors.blue,
                  alignment: Alignment.center,
                  child: Text(
                    '列表项${index + 1}',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 10);
              },
            ),
          ], // 切片列表
        ),
      ),
    );
  }
}

class _StickCategory extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemCount: 30,
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            color: Colors.blue,
            alignment: Alignment.center,
            width: 100,
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '分类${index + 1}',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  @override
  // 最大展开高度（不吸顶时最大高度）
  double get maxExtent => 80;

  @override
  // 最小折叠高度。（吸顶时最小高度）
  double get minExtent => 40;

  @override
  // 是否需要重建
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
```

##### PageView

整页滚动效果，支持横向和纵向。

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('ListView separate')),
        body: ListView.separated(
          itemCount: 100, // 列表长度
          itemBuilder: (BuildContext context, int index) {
            return Container(
              width: double.infinity,
              height: 100,
              color: Colors.blue,
              alignment: Alignment.center,
              child: Text(
                '我是第${index + 1}个',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            );
          },
          // 列表项间隔
          separatorBuilder: (context, index) {
            return Container(
              height: 10,
              width: double.infinity,
              color: Colors.yellow,
            );
          },
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
```

#### 网络

##### `Dio`

```dart
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void main() {
  Dio()
      .get("https://geek.itheima.net/v1_0/channels")
      .then((value) {
        print("value: ${value}");
      })
      .catchError((error) {
        print("error: " + error);
      });
}

class DioUtils {
  final Dio _dio = Dio();

  DioUtils() {
    _dio.options.baseUrl = "https://geek.itheima.net/v1_0/";
    _dio.options.connectTimeout = Duration(seconds: 10); // 连接超时
    _dio.options.sendTimeout = Duration(seconds: 5);
    _dio.options.receiveTimeout = Duration(seconds: 10);

    // 拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        // 请求拦截器
        onRequest: (options, handler) {
          // handler.next(requestOptions) // 放过请求
          // handler.reject(error) // 拦截请求
          handler.next(options);
        },
        // 响应拦截器
        onResponse: (response, handler) {
          if (response.statusCode! >= 200 && response.statusCode! < 300) {
            handler.next(response);
            return;
          }
          handler.reject(DioException(requestOptions: response.requestOptions));
        },
        // 错误拦截器
        onError: (error, handler) {
          handler.reject(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(String url, {Map<String, dynamic>? params}) {
    return _dio.get(url, queryParameters: params);
  }
}
```
