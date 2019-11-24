// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _Element {
  background,
  text,
}

enum _CodeState {
  closed,
  open,
  closing,
  opening,
}

final Color _darkColor = Colors.deepPurpleAccent;
final Color _lightColor = Colors.white;

final _lightTheme = {
  _Element.background: _lightColor,
  _Element.text: _darkColor,
};

final _darkTheme = {
  _Element.background: _darkColor,
  _Element.text: _lightColor,
};

final List<bool> _one = [false, true, true, true, true];
final List<bool> _two = [false, false, true, true, true];
final List<bool> _three = [false, false, false, true, true];
final List<bool> _four = [false, false, false, false, true];
final List<bool> _five = [false, false, false, false, false];
final List<bool> _six = [true, false, false, false, false];
final List<bool> _seven = [true, true, false, false, false];
final List<bool> _eight = [true, true, true, false, false];
final List<bool> _nine = [true, true, true, true, false];
final List<bool> _zero = [true, true, true, true, true];
final _morseMap = {
  1: _one,
  2: _two,
  3: _three,
  4: _four,
  5: _five,
  6: _six,
  7: _seven,
  8: _eight,
  9: _nine,
  0: _zero,
};

class MorsePainter extends CustomPainter {
  final List<_CodeState> codeStates;
  final double progress;
  final Map theme;
  var morsePaint;

  MorsePainter(this.codeStates, this.progress, this.theme) {
    morsePaint = Paint()
      ..color = theme[_Element.text]
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
  }

  Rect _createRect(
      double centerX, double centerY, double codeWidth, double height) {
    return new Rect.fromLTRB(centerX - (codeWidth / 2), centerY - (height / 2),
        centerX + (codeWidth / 2), centerY + (height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    double screenCenterX = size.width / 2.0;
    double screenCenterY = size.height / 2.0;
    double columnWidth = size.width / 5.0;
    double rowHeight = size.height / 4.0;
    double buffer = columnWidth / 4.0;
    double openWidth = columnWidth - buffer;
    double closedWidth = openWidth / 4.0;
    Radius radius = Radius.circular(closedWidth / 2.0);
    double progressWidth = (openWidth - closedWidth) * (progress / 100.0);
    double openingWidth = closedWidth + progressWidth;
    double closingWidth = openWidth - progressWidth;

    List<Rect> rects = new List();
    for (int i = 0; i < codeStates.length; i++) {
      double offsetY = 0.0;
      double offsetX = 0.0;
      double width = 0.0;
      _CodeState state = codeStates[i];

      if (i < 5) {
        offsetY = -(rowHeight * 2.0) + (rowHeight / 2.0);
      } else if (i < 10) {
        offsetY = -rowHeight + (rowHeight / 2.0);
      } else if (i < 15) {
        offsetY = rowHeight - (rowHeight / 2.0);
      } else {
        offsetY = (rowHeight * 2.0) - (rowHeight / 2.0);
      }

      if (i % 5 == 0) {
        offsetX = -(columnWidth * 2.0);
      } else if (i % 5 == 1) {
        offsetX = -columnWidth;
      } else if (i % 5 == 3) {
        offsetX = columnWidth;
      } else if (i % 5 == 4) {
        offsetX = (columnWidth * 2.0);
      }

      if (state == _CodeState.open) {
        width = openWidth;
      } else if (state == _CodeState.opening) {
        width = openingWidth;
      } else if (state == _CodeState.closed) {
        width = closedWidth;
      } else if (state == _CodeState.closing) {
        width = closingWidth;
      }

      rects.add(_createRect(screenCenterX + offsetX, screenCenterY + offsetY,
          width, closedWidth));
    }

    rects.forEach((rect) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), morsePaint);
    });
  }

  @override
  bool shouldRepaint(MorsePainter oldDelegate) {
    return oldDelegate.codeStates != codeStates ||
        oldDelegate.progress != progress;
  }
}

class MorseClock extends StatefulWidget {
  const MorseClock(this.model);

  final ClockModel model;

  @override
  _MorseClockState createState() => _MorseClockState();
}

class _MorseClockState extends State<MorseClock> with SingleTickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  int _hour = -1;
  int _nextHour;
  int _minute = -1;
  int _nextMinute;
  Timer _timer;
  List<_CodeState> _codeStates = new List();
  double _progress = 100.0;
  Animation<double> _animation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _controller =
        AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hour = _nextHour;
        _minute = _nextMinute;
        _controller.reset();
      }
    });
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(MorseClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      int newHour = int.parse(
          DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh')
              .format(_dateTime));
      int newMinute = int.parse(DateFormat('mm').format(_dateTime));
      if (_hour == -1 || _minute == -1) {
        _hour = newHour;
        _minute = newMinute;
        _nextHour = newHour;
        _nextMinute = newMinute;
        _calculateStates(_progress);
      } else {
        bool update = newMinute != _minute;
        _nextHour = newHour;
        _nextMinute = newMinute;

        if (update) {
          _controller.forward();
        }
      }

      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  void _addStates(oldVal, newVal, states) {
    List<bool> codes = _morseMap[oldVal];
    if (oldVal == newVal) {
      codes.forEach((code) {
        states.add(code ? _CodeState.open : _CodeState.closed);
      });
    } else {
      List<bool> newCodes = _morseMap[newVal];
      for (int i = 0; i < newCodes.length; i++) {
        bool oldCode = codes[i];
        bool newCode = newCodes[i];
        if (oldCode == newCode) {
          states.add(oldCode ? _CodeState.open : _CodeState.closed);
        } else {
          states.add(oldCode ? _CodeState.closing : _CodeState.opening);
        }
      }
    }
  }

  void _calculateStates(double progress) {
    int hour0 = _hour ~/ 10;
    int hour1 = _hour % 10;
    int minute0 = _minute ~/ 10;
    int minute1 = _minute % 10;

    int nextHour0 = _nextHour ~/ 10;
    int nextHour1 = _nextHour % 10;
    int nextMinute0 = _nextMinute ~/ 10;
    int nextMinute1 = _nextMinute % 10;

    List<_CodeState> newStates = new List();
    _addStates(hour0, nextHour0, newStates);
    _addStates(hour1, nextHour1, newStates);
    _addStates(minute0, nextMinute0, newStates);
    _addStates(minute1, nextMinute1, newStates);
    _codeStates = newStates;
    _progress = progress;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;

    _animation = Tween(begin: 0.0, end: 100.0).animate(_controller)
      ..addListener(() {
        setState(() {
          _calculateStates(_animation.value);
        });
      });

    return Scaffold(
      backgroundColor: colors[_Element.background],
      body: CustomPaint(
        size: Size(double.infinity, double.infinity),
        painter: MorsePainter(_codeStates, _progress, colors),
      ),
    );
  }
}
