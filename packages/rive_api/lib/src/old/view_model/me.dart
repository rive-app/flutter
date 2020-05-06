// /// Basic data for a logged in user

// import 'package:meta/meta.dart';
// import 'package:rive_api/src/model/me.dart';

// class MeVM {
//   MeVM({
//     @required int id,
//     @required this.name,
//     this.avatarUrl,
//   })  : assert(id != null),
//         assert(name != null),
//         _id = id;
//   final int _id;
//   final String name;
//   final String avatarUrl;

//   /// Builds an instance from a model
//   factory MeVM.fromModel(Me model) => MeVM(
//         id: model.id,
//         name: model.name,
//         avatarUrl: model.avatarUrl,
//       );

//   /// Tests if this is equivalent to a model
//   bool equalsModel(Me model) => _id == model.id;

//   @override
//   String toString() => 'MeVM($name)';

//   @override
//   bool operator ==(o) => o is MeVM && o._id == _id;

//   @override
//   int get hashCode => _id;
// }
