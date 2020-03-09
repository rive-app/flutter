/// An interface for an object that has advancing logic. The object is advanced
/// by calling the [advance] method with an elapsed time value in seconds.
/// Advancing by time allows predictable (time wise) results on different
/// machines advancing at different speeds. Usually advance is called per frame,
/// but it doens't have to be.
abstract class Advancer {
  /// Method to be implemented to advance the state of this object forward by
  /// [elapsed] seconds. The return boolean value represents whether or not the
  /// object wants to keep advancing. The advance method can called even when
  /// object has previously returned false (I'm done), so the advance logic
  /// should deal with its own completed state internally. The purpose of
  /// returning false is for a higher level system to interpret if the entire
  /// system has stabilized and can needs to keep advancing (perhaps schedule
  /// another frame callback) or not.
  bool advance(double elapsed);
}