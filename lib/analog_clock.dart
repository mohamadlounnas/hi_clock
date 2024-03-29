// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;
import 'dart:ui';

import 'container_hand.dart';
import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
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
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF4285F4),
            // Minute hand.
            highlightColor: Color(0xFF8AB4F8),
            // Second hand.
            accentColor: Color(0xFF669DF6),
            backgroundColor: Color(0xFFD2E3FC),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Color(0xFF3C4043),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: <Widget>[
              Text(
                DateFormat('HH').format(_now) + ":",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color:Colors.white.withOpacity(0.7)
                ),
              ),
              Text(
                DateFormat('MM').format(_now),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(_temperatureRange,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,color:Colors.white)),
          Text(_condition,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,color:Colors.white)),
          Text(_location,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100,color:Colors.white)),
        ],
      ),
    );

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: new BorderRadius.all(new Radius.circular(14.0)),
          color: Colors.white,
          image: DecorationImage(
            image: ExactAssetImage("assets/bg.jpg"),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: -1,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Example of a hand drawn with [CustomPainter].
            Positioned(
              top: 20,
              right: 20,
              bottom: 20,
              child: Center(
                child: ClipRRect(
                  borderRadius:
                      new BorderRadius.all(new Radius.circular(200.0)),
                  child: Container(
                    color: Colors.lightBlue.withOpacity(0.1),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: (_now.second.roundToDouble()*15/60), sigmaY: (_now.second.roundToDouble()*15/60)),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        width: 160,
                        height: 160,
                        child: Stack(
                          children: <Widget>[
                            DrawnHand(
                              color: customTheme.accentColor,
                              thickness: 2,
                              size: 1,
                              angleRadians: _now.second * radiansPerTick,
                            ),
                            DrawnHand(
                              color: customTheme.highlightColor,
                              thickness: _now.second.roundToDouble()*4/60,
                              size: 0.7,
                              angleRadians: _now.minute * radiansPerTick,
                            ),
                            DrawnHand(
                              color: Colors.red,
                              thickness: _now.minute.roundToDouble()*6/60,
                              size: 0.5,
                              angleRadians: _now.hour * radiansPerTick,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black26
                    ], // whitish to gray
                    tileMode: TileMode
                        .repeated, // repeats the gradient over the canvas
                  ),
                ),
                padding: EdgeInsets.all(12.0),
                child: weatherInfo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
