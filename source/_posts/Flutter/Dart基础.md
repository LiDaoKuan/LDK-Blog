---
title: Dart语法基础
date: 2026-02-15
updated: 2026-02-17
tags: [Dart, Flutter]
categories: Flutter
description: Dart语法基础
---

本篇主要记录Dart语言的**基础语法**，如果我长时间不用Dart而导致遗忘可以看这篇文章快速回忆。**非教程！！！**。

#### 基础语法

```dart
import 'dart:io';

void main(List<String> args) {
  print("hello world");

  // 变量
  var num_1 = 100;
  print(num_1);

  print(num); // 此处的num是dart的内置类型，打印出类型名：num

  // 常量
  const PI = 3.14; // const常量：在编译时被确定。
  print(PI);

  // const time = DateTime.now(); // 报错
  final time = DateTime.now(); // final常量：在运行时被确定。
  sleep(Duration(seconds: 1));
  // time = DateTime.now(); // 报错，不可更改
  print(time);

  // 数据类型
  dateType();

  // 空安全机制
  nullSafe();

  // 运算符
  operator();

  // 流程控制
  control();

  dynamicReturnType();

  // 可选参数
  func1(100, 20);

  // 可选命名参数
  func2(10, c: 400);

  // 匿名函数
  Function func3 = () {
    return '!!! asd !!!';
  };
  print(func3());

  // 箭头函数 -- 适用于只有一行代码的函数，可以省略return语句
  int add(int a, int b) => a + b;
  print(add(10, 30));
  // 应用场景：
  // 1. 简化foreach
  List<String> fruits = ['苹果', '香蕉', '西瓜'];
  fruits.forEach((fruits) => print(fruits));
  // 2. 简化List.map操作
  List<int> numbers = [1, 2, 3, 4];
  List<int> doubled = numbers
      .map((num) => num * 2)
      .toList(); // 将numbers中的每个元素映射为2倍
  print(doubled);
  // 3. 条件表达式
  bool isEven(int number) => number % 2 == 0;
  print(isEven(4)); // 输出: true
}

// 常用数据类型
void dateType() {
  // String
  String str_1 = "双引号字符串";
  print(str_1);
  str_1 = '单引号字符串';
  print(str_1);
  // 模板String
  str_1 = "现在时间是${DateTime.now()}"; // ${}中放变量或者表达式
  print(str_1);
  str_1 = str_1 + str_1; // 字符串相加
  print(str_1);

  // int -- 整型
  int number_int = 100;

  // num -- 可整型 可小数
  num number_num = 10;
  number_num = 3.14;

  // double -- 小数
  double number_double = 3.14;

  // int num double 相互赋值
  number_int = number_double.toInt();
  number_double = number_int.toDouble();

  number_double = number_num.toDouble(); //  num转double，必须调用toDouble()
  number_num = number_double; // double转num，可以直接赋值

  number_num = number_int; // int转num，可以直接赋值
  number_int = number_num.toInt(); // num转int，必须调用toInt()

  // bool类型
  bool isEmpty = true;
  print(isEmpty);

  // List -- 列表
  List studentsList = ['张三', '李四', '王五'];
  print(studentsList);
  studentsList.add('赵六'); // 添加新元素
  studentsList.add(123); // 可以添加不同类型的元素
  studentsList.addAll(['xiaoming', 'lihong', 'xiaoli']); // 向尾部添加列表
  print(studentsList);
  studentsList.remove("xiaoming"); // 删除满足内容的第一个元素（如果存在）
  print(studentsList);
  studentsList.removeLast(); // 删除最后一个元素
  print(studentsList);
  studentsList.removeAt(0); // 根据索引删除元素
  print(studentsList);
  studentsList.removeRange(0, studentsList.length); // 删除范围内的元素
  print(studentsList);

  studentsList = ['张三', '李四', '王五'];

  // List foreach遍历
  studentsList.forEach((item) {
    // 遍历逻辑
    print(item);
  });

  // 判断是不是所有元素都满足条件
  if (studentsList.every((item) {
    return item.toString().length < 10;
  })) {
    print("all student name length < 10");
  }

  // 筛选出满足条件的元素，组成一个Iterable，再转换为List
  var tempList = studentsList.where((item) {
    return item.toString().length == 2;
  }).toList();
  print(tempList);

  print(tempList.length); // 列表长度
  print(tempList.last); // 最后一个元素
  print(tempList.first); // 第一个元素
  print(tempList.isEmpty); // List是否为空，注意是属性，不是函数！

  // Map -- 字典
  Map map = <String, String>{
    'lunch': '午饭',
    'morning': '早上',
    'hello': '你好',
  }; // 创建Map，规定key为String，value为String。之后将不能添加其他类型的value
  print(map);
  print(map['lunch']);
  map['lunch'] = '午餐';
  print(map['lunch']);

  // Map foreach 遍历
  map.forEach((key, value) {
    print('key: ' + key + '\tvalue: ' + value);
  });

  map.addAll(<String, String>{
    'test': '测试',
    'app': '应用',
  }); // 因为创建map时设置了<String, String>，所以添加时也需要指明<String, String>。

  // map.addAll({'int': 10, 'String': 'string', 'double': 3.14});  // 添加一组数据，报错。不能添加其他类型的value，因为创建map时设置过value为String

  map.addEntries(<String, String>{'123': '123'}.entries);
  print(map);

  if (map.containsKey('123')) {
    print('map contains key: 123');
  }
  if (map.containsValue('测试')) {
    print('map contains value: 测试');
  }
  map.remove('123'); // 删除key对应的键值对
  print(map);
  map.clear(); // 清空map
  print(map);

  // 动态类型: dynamic
  // 允许变量在运行时自由改变类型，同时绕过编译时的静态检查
  dynamic free = "字符串";
  free = 1;
  free = true;
  free = {"123": 123, '456': 456};
  free = [0, 1, 2, 3, 4, 5, 6];
  print(free);
  free = "123456";
  // free.toInt(); // 可以调用，但运行时报错：String没有toInt()方法
}

//空安全机制
void nullSafe() {
  // dart的空安全机制：通过编译静态检查将运行时空指针提前暴露
  // 常用空安全操作符
  // 可空类型
  String? name = "张三"; // 允许name为String或者null

  name = null; // name可以为null

  // 安全访问
  name?.startsWith("张"); // 如果name为null，则跳过后面的操作

  // 非空断言
  name = "王五";
  print(name!.length); // 保证name非null，否则在此处崩溃

  // 空合并
  name = null;
  print(name ?? "李四"); // 左侧为null时，返回右侧默认值
}

// 运算符
void operator() {
  int a = 10;
  int b = 3;
  int sum = a + b; // 加
  int sub = a - b; // 减
  int mul = a * b; // 乘
  double div = a / b; // 除法（结果为double）
  int divInt = a ~/ b; // 整除（结果为int）
  int mod = a % b; // 取模

  /**单目运算符
   * +=
   * -=
   * *=
   * /=   注意得到的是double！因此 /= 左边的变量一定要 能接收double
   * ~/=  a~/=b 等同于 a=a~/b
   * %=
   */

  /**比较运算符
   * ==   !=    >   >=    <   <=
   */

  /**逻辑运算符
   * &&   与
   * ||   或
   * !    非
   */
}

// 流程控制
void control() {
  // if语句：与C++完全相同

  // 三目运算符：与C++完全相同
  int a = 10;
  int b = 20;
  int max = (a > b ? a : b);

  // switch-case：与C++完全相同

  // while循环，continue语句：与C++完全相同

  // for循环：与C++完全相同
  for (int i = 0; i < 10; ++i) {
    stdout.write("i: ${i} ");
  }
  stdout.write('\n');
}

/**
 * @brief 该函数的返回值类型是dynamic
 */
dynamicReturnType() {
  int a = 100;
  int b = 200;
  if (a > b) {
    return a;
  }
  return "a<=b";
}

// 函数传参 -- 可选参数。使用中括号
void func1(int a, [int b = 10, int? c, int d = 200]) {
  print("a: ${a}, b: ${b}, c: ${c}, d: ${d}");
  return;
}

// 函数传参 -- 可选命名参数。传参时必须指明参数名，不必按照顺序传参。使用大括号。
void func2(int a, {int? b, int? c, int d = 200}) {
  print("a: ${a}, b: ${b}, c: ${c}, d: ${d}");
  return;
}
```

#### 面向对象（封装和继承）

```dart
class Person {
  String? name = ''; // 加 ? 是为了方便构造函数中用可选命名参数赋值
  int? age = 0;

  // 构造函数（可选命名参数）
  /*
  Person({String? name, int? age}) {
    this.name = name;
    this.age = age;
  }*/

  // 语法糖
  Person({this.name, this.age}); // 后面也可以加 {} 添加其他逻辑

  // 命名构造函数
  /*
  Person.create({String? name, int? age}) {
    this.name = name;
    this.age = age;
  }*/

  // 语法糖
  Person.create({this.name, this.age});

  void study() {
    print('${name}在学习');
  }

  void eat() {
    print("person eat");
  }
}

/**继承 extends关键字
 * 和Java一样，一个类只能拥有一个父类。
 * 可以通过 @override 注解重写父类方法。
 * 子类不会继承父类构造方法，必须在子类的构造函数中使用super关键字调用父类构造函数确保父类正确初始化。同时super使用必须是类似于C++的初始化列表的形式
 */

class Student extends Person {
  int? _id; // 下划线开头。私有属性。目前无法通过语法糖进行私有属性初始化
  // String? name; // 下划线开头。私有属性

  /**报错：
   * This requires the experimental 'private-named-parameters' language feature to be enabled.
   * Try passing the '--enable-experiment=private-named-parameters' command line option.
   */
  // Student({this._id = 0, this._name = ""});

  // 必须通过此种形式调用super
  Student({String? name, int? age, int? id}) : super(name: name, age: age) {
    print("Student constructor");
  }

  // 重写eat函数
  @override
  void eat() {
    super.eat();
    print("student eat");
  }

  // 下面不算重写，因为父类中是study，没有被隐藏，函数签名不一样。
  @override
  void _study() {
    print("private study.");
  }
}

void main(List<String> args) {
  Person p = Person(name: '张三', age: 20);
  p.study();
  p = Person.create(name: '李四', age: 22);
  p.study();
  Student stu = Student(name: "王五", age: 30);
  stu.eat();
  return;
}
```

#### 多态

```dart
/* 多态 */

class PayBase {
  void pay() {
    print('basic pay');
  }
}

class WxPay extends PayBase {
  @override
  void pay() {
    // super.pay();
    print('wexin pay');
  }
}

class AliPay extends PayBase {
  @override
  void pay() {
    // super.pay();
    print('ali pay');
  }
}

// 抽象类，与Java相同
abstract class PayInterface {
  void pay();
}

// 实现接口中的功能
class TaobaoPay implements PayInterface {
  @override
  void pay() {
    print('Taobao Pay');
  }
}

void main(List<String> args) {
  PayBase pay = WxPay();
  pay.pay();
  pay = AliPay();
  pay.pay();

  PayInterface payInterface = TaobaoPay();
  payInterface.pay();
}
```

#### 类的混入

```dart
/**类的混入 步骤：
 * 1. 使用 mixin 关键字定义一个对象
 * 2. 使用 with 关键字将定义的对象混入到当前对象
 * 
 * 注意：
 * 一个类支持多个minix，调用优先级遵循"后来居上"原则，即："后混入"的会覆盖"先混入"的同名方法。
 * 通过mixin可以实现类似多继承的效果，同时避免多继承的复杂性
 */

// minix后面的class可以省略
mixin class Song {
  void song(String name) {
    print('${name} is singing');
  }
}

class Student with Song {
  String? name;
  int? age;

  Student({this.name, this.age});
}

class Teacher with Song {
  String? name;
  int? age;

  Teacher({this.name, this.age});
}

void main(List<String> args) {
  Student stu = Student(name: 'zhangsan', age: 10);
  stu.song(stu.name!);
  Teacher tea = Teacher(name: 'lisi', age: 18);
  tea.song(tea.name!);
}
```

#### 模板/泛型

```dart
/* 模板/泛型 */

// 模板类
class myList<T> {
  T? ele;
}

// 模板函数
T add<T>(T? a) {
  return a!;
}

void main(List<String> args) {
    return;
}
```

#### 异步编程：Future

```dart
/* 异步编程 */

/**异步编程
 * dart是单线程语言，即：不支持多线程，dart的异步编程实际上还是同步执行的，只不过更换了执行顺序。
 * dart采用 单线程+事件循环 的机制处理耗时任务，每个循环都执行下面操作：
 * 执行同步代码 -> 执行微任务队列任务 -> 执行事件队列任务 -> 结束，开始下一个循环
 * 
 * 微任务队列：Future.microtask()
 * 
 * 事件队列：Future、Future.delayed()、I/O操作（文件、网络）等
 */

import 'dart:ffi';
import 'dart:isolate';

/**Future代表一个异步操作的结果。
 * 创建Future：Future((){}); 将要执行的异步操作传入
 * Future有三个状态：
 *  - Uncompleted（等待）
 *  - Completed with a value（成功）
 *  - Completed with a error（成功）
 * 
 * 执行成功：
 *  不抛出异常。
 *  通过 then((){}); 接收结果。
 *  同时，当在then()中的回调函数返回另一个Future对象时，可以链式调用：
 *  future.then().then().then()。
 *  其中，除了最后一个then，每个then都会返回一个新的Future，作为按顺序执行的下一个操作。
 *  同时，每个then都处理上一个then返回的Future的执行结果。
 *  以此保证链式调用中的操作顺序执行。
 * 执行失败：
 *  需要在Future的执行函数中抛出异常。throw Exception()
 *  通过 catchError((){}); 处理异常
 */

void main(List<String> args) {
  Future fu = Future(() {
    // throw Exception(); // 执行失败抛出异常
    return 'hello world';
  });
  // 链式调用（不正经用法）
  fu
      .then((value) {
        print('received value: ${value}');
        return 10; // 直接返回值，作为下一个then()的value
      })
      .then((value) {
        print('received value: ${value}');
        return 3.14;
      })
      .then((value) {
        print('received value: ${value}');
        return true;
      });
  // 处理失败状态
  fu.catchError((error) {
    print('error: ' + error);
  });

  Future future = Future(() {
    return 'hello world';
  });
  // 链式调用（正经用法）
  future
      .then((value) {
        print('received value: ${value}');
        // throw Exception(); // 如果抛出异常，则后面所有then都不会执行
        return Future(() => 10); // 返回Future，Dart会等待Future中的函数执行完毕，将
      })
      .then((value) {
        print('received value: ${value}');
        return Future(() => 3.14);
      })
      .then((value) {
        print('received value: ${value}');
        return Future(() => true);
      })
      .catchError((error) {
        print('error: ${error}');
      });

  fu.catchError((error) {
    print('error: ' + error);
  });
}
```

#### 异步编程：async和await

```dart
// await必须配合async使用
void func() async {
  // 其他操作

  try {
    // 执行Future，并且获取结果
    String result = await Future(() {
      print('文件IO begin');
      print('文件IO ing');
      print('文件IO finish');

      return "IO成功";
    });

    // Future执行成功后才执行的逻辑
    print(result);
  } catch (error) {
    // try执行失败的逻辑
    print('error: ${error}');
  }

  // 其他操作
}

void main(List<String> args) {
  func();
}
```
