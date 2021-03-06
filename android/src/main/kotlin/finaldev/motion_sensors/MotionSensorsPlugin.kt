package finaldev.motion_sensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry.Registrar

// translate from https://github.com/flutter/plugins/tree/master/packages/sensors
/** MotionSensorsPlugin */
public class MotionSensorsPlugin : FlutterPlugin {
  private val ACCELEROMETER_CHANNEL_NAME = "final.dev/plugins/motion_sensors/accelerometer"
  private val GYROSCOPE_CHANNEL_NAME = "final.dev/plugins/motion_sensors/gyroscope"
  private val USER_ACCELEROMETER_CHANNEL_NAME = "final.dev/plugins/motion_sensors/user_accel"
  private val MAGNETOMETER_CHANNEL_NAME = "final.dev/plugins/motion_sensors/magnetometer"
  private val ORIENTATION_CHANNEL_NAME = "final.dev/plugins/motion_sensors/orientation"

  private var accelerometerChannel: EventChannel? = null
  private var userAccelChannel: EventChannel? = null
  private var gyroscopeChannel: EventChannel? = null
  private var magnetometerChannel: EventChannel? = null
  private var orientationChannel: EventChannel? = null

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val plugin = MotionSensorsPlugin()
      plugin.setupEventChannels(registrar.context(), registrar.messenger())
    }
  }

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    val context = binding.applicationContext
    setupEventChannels(context, binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    teardownEventChannels()
  }

  private fun setupEventChannels(context: Context, messenger: BinaryMessenger) {
    accelerometerChannel = EventChannel(messenger, ACCELEROMETER_CHANNEL_NAME)
    val accelerationStreamHandler = StreamHandlerImpl(
            (context.getSystemService(Context.SENSOR_SERVICE) as SensorManager),
            Sensor.TYPE_ACCELEROMETER)
    accelerometerChannel!!.setStreamHandler(accelerationStreamHandler)

    userAccelChannel = EventChannel(messenger, USER_ACCELEROMETER_CHANNEL_NAME)
    val linearAccelerationStreamHandler = StreamHandlerImpl(
            (context.getSystemService(Context.SENSOR_SERVICE) as SensorManager),
            Sensor.TYPE_LINEAR_ACCELERATION)
    userAccelChannel!!.setStreamHandler(linearAccelerationStreamHandler)

    gyroscopeChannel = EventChannel(messenger, GYROSCOPE_CHANNEL_NAME)
    val gyroScopeStreamHandler = StreamHandlerImpl(
            (context.getSystemService(Context.SENSOR_SERVICE) as SensorManager),
            Sensor.TYPE_GYROSCOPE)
    gyroscopeChannel!!.setStreamHandler(gyroScopeStreamHandler)

    magnetometerChannel = EventChannel(messenger, MAGNETOMETER_CHANNEL_NAME)
    val magnetometerStreamHandler = StreamHandlerImpl(
            (context.getSystemService(Context.SENSOR_SERVICE) as SensorManager),
            Sensor.TYPE_MAGNETIC_FIELD)
    magnetometerChannel!!.setStreamHandler(magnetometerStreamHandler)

    orientationChannel = EventChannel(messenger, ORIENTATION_CHANNEL_NAME)
    val rotationVectorStreamHandler = RotationVectorStreamHandler(
            (context.getSystemService(Context.SENSOR_SERVICE) as SensorManager))
    orientationChannel!!.setStreamHandler(rotationVectorStreamHandler)
  }

  private fun teardownEventChannels() {
    accelerometerChannel!!.setStreamHandler(null)
    userAccelChannel!!.setStreamHandler(null)
    gyroscopeChannel!!.setStreamHandler(null)
    magnetometerChannel!!.setStreamHandler(null)
    orientationChannel!!.setStreamHandler(null)
  }
}


class StreamHandlerImpl(private val sensorManager: SensorManager, private val sensorType: Int) :
        EventChannel.StreamHandler, SensorEventListener {
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    val sensor = sensorManager.getDefaultSensor(sensorType)
    sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
  }

  override fun onCancel(arguments: Any?) {
    sensorManager.unregisterListener(this)
    eventSink = null
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {

  }

  override fun onSensorChanged(event: SensorEvent?) {
    val sensorValues = listOf(event!!.values[0], event.values[1], event.values[2])
    eventSink?.success(sensorValues)
  }
}

class RotationVectorStreamHandler(private val sensorManager: SensorManager) :
        EventChannel.StreamHandler, SensorEventListener {
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
  }

  override fun onCancel(arguments: Any?) {
    sensorManager.unregisterListener(this)
    eventSink = null
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {

  }

  override fun onSensorChanged(event: SensorEvent?) {
    var matrix = FloatArray(9)
    SensorManager.getRotationMatrixFromVector(matrix, event!!.values)
    var orientation = FloatArray(3)
    SensorManager.getOrientation(matrix, orientation)
    val sensorValues = listOf(orientation[0], orientation[1], orientation[2])
    eventSink?.success(sensorValues)
  }
}