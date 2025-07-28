import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_tumeric_papplication/models/catogary_model.dart';

class CatogaryService {
  final CollectionReference _catogaryCollection = FirebaseFirestore.instance
      .collection("category");

  //Get catogary details
  Stream<List<CatogaryModel>> getCatogary() {
    return _catogaryCollection.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .where((doc) => doc.data() != null)
              .map(
                (doc) => CatogaryModel.fromJsonCatogary(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
    );
  }

  
}
