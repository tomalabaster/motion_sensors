import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

final MotionSensors motionSensors = MotionSensors();

const EventChannel _accelerometerEventChannel = EventChannel('final.dev/plugins/motion_sensors/accelerometer');

const EventChannel _userAccelerometerEventChannel = EventChannel('final.dev/plugins/motion_sensors/gyroscope');

const EventChannel _gyroscopeEventChannel = EventChannel('final.dev/plugins/motion_sensors/user_accel');

const EventChannel _magnetometerEventChannel = EventChannel('final.dev/plugins/motion_sensors/magnetometer');

const EventChannel _orientationChannel = EventChannel('final.dev/plugins/motion_sensors/orientation');

// from https://github.com/flutter/plugins/tree/master/packages/sensors
/// Discrete reading from an accelerometer. Accelerometers measure the velocity
/// of the device. Note that these readings include the effects of gravity. Put
/// simply, you can use accelerometer readings to tell if the device is moving in
/// a particular direction.
class AccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  AccelerometerEvent(this.x, this.y, this.z);
  AccelerometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  /// Acceleration force along the x axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (including gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  @override
  String toString() => '[AccelerometerEvent (x: $x, y: $y, z: $z)]';
}

/// Discrete reading from a gyroscope. Gyroscopes measure the rate or rotation of
/// the device in 3D space.
class GyroscopeEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  GyroscopeEvent(this.x, this.y, this.z);
  GyroscopeEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  /// Rate of rotation around the x axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "pitch". The top of the device will tilt towards or away from the
  /// user as this value changes.
  final double x;

  /// Rate of rotation around the y axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "yaw". The lengthwise edge of the device will rotate towards or away from
  /// the user as this value changes.
  final double y;

  /// Rate of rotation around the z axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "roll". When this changes the face of the device should remain facing
  /// forward, but the orientation will change from portrait to landscape and so
  /// on.
  final double z;

  @override
  String toString() => '[GyroscopeEvent (x: $x, y: $y, z: $z)]';
}

/// Like [AccelerometerEvent], this is a discrete reading from an accelerometer
/// and measures the velocity of the device. However, unlike
/// [AccelerometerEvent], this event does not include the effects of gravity.
class UserAccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  UserAccelerometerEvent(this.x, this.y, this.z);
  UserAccelerometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  /// Acceleration force along the x axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (excluding gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  @override
  String toString() => '[UserAccelerometerEvent (x: $x, y: $y, z: $z)]';
}

class MagnetometerEvent {
  MagnetometerEvent(this.x, this.y, this.z);
  MagnetometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  final double x;
  final double y;
  final double z;
  @override
  String toString() => '[Magnetometer (x: $x, y: $y, z: $z)]';
}

class OrientationEvent {
  OrientationEvent(this.yaw, this.pitch, this.roll);
  OrientationEvent.fromList(List<double> list)
      : yaw = list[0],
        pitch = list[1],
        roll = list[2];

  /// The yaw of the device in radians.
  final double yaw;

  /// The pitch of the device in radians.
  final double pitch;

  /// The roll of the device in radians.
  final double roll;
  @override
  String toString() => '[Orientation (yaw: $yaw, pitch: $pitch, roll: $roll)]';
}

class MotionSensors {
  Stream<AccelerometerEvent> _accelerometerEvents;
  Stream<GyroscopeEvent> _gyroscopeEvents;
  Stream<UserAccelerometerEvent> _userAccelerometerEvents;
  Stream<MagnetometerEvent> _magnetometerEvents;
  Stream<OrientationEvent> _orientationEvents;

  /// A broadcast stream of events from the device accelerometer.
  Stream<AccelerometerEvent> get accelerometer {
    if (_accelerometerEvents == null) {
      _accelerometerEvents = _accelerometerEventChannel.receiveBroadcastStream().map((dynamic event) => AccelerometerEvent.fromList(event.cast<double>()));
    }
    return _accelerometerEvents;
  }

  /// A broadcast stream of events from the device gyroscope.
  Stream<GyroscopeEvent> get gyroscope {
    if (_gyroscopeEvents == null) {
      _gyroscopeEvents = _gyroscopeEventChannel.receiveBroadcastStream().map((dynamic event) => GyroscopeEvent.fromList(event.cast<double>()));
    }
    return _gyroscopeEvents;
  }

  /// Events from the device accelerometer with gravity removed.
  Stream<UserAccelerometerEvent> get userAccelerometer {
    if (_userAccelerometerEvents == null) {
      _userAccelerometerEvents = _userAccelerometerEventChannel.receiveBroadcastStream().map((dynamic event) => UserAccelerometerEvent.fromList(event.cast<double>()));
    }
    return _userAccelerometerEvents;
  }

  /// A broadcast stream of events from the device magnetometer.
  Stream<MagnetometerEvent> get magnetometer {
    if (_magnetometerEvents == null) {
      _magnetometerEvents = _magnetometerEventChannel.receiveBroadcastStream().map((dynamic event) => MagnetometerEvent.fromList(event.cast<double>()));
    }
    return _magnetometerEvents;
  }

  Stream<OrientationEvent> get orientation {
    if (_orientationEvents == null) {
      _orientationEvents = _orientationChannel.receiveBroadcastStream().map((dynamic event) => OrientationEvent.fromList(event.cast<double>()));
    }
    return _orientationEvents;
  }

  Matrix4 getRotationMatrix(Vector3 gravity, Vector3 geomagnetic) {
    Vector3 a = gravity.normalized();
    Vector3 e = geomagnetic.normalized();
    Vector3 h = e.cross(a).normalized();
    Vector3 m = a.cross(h).normalized();
    return Matrix4(
      h.x, h.y, h.z, 0, //
      m.x, m.y, m.z, 0,
      a.x, a.y, a.z, 0,
      0, 0, 0, 1,
    );
  }

  Vector3 getOrientation(Matrix4 m) {
    final r = m.storage;
    return Vector3(
      math.atan2(r[1], r[5]),
      math.asin(-r[9]),
      math.atan2(-r[8], r[10]),
    );
  }
}
