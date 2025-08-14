import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:the_tumeric_papplication/models/catogary_model.dart';
import 'package:the_tumeric_papplication/models/food_detail_model.dart';

class CatogaryService {
  final CollectionReference _catogaryCollection = FirebaseFirestore.instance
      .collection("category");

  final CollectionReference _foodCollection = FirebaseFirestore.instance
      .collection("menus");

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

  Stream<List<FoodDetailModel>> getFoodsSafe() {
    print('=== STARTING getFoodsSafe STREAM ===');
    
    return _foodCollection
        .snapshots()
        .handleError((error) {
          print('=== FIRESTORE STREAM ERROR ===');
          print('Error: $error');
          if (error is FirebaseException) {
            print('Firebase Error Code: ${error.code}');
            print('Firebase Error Message: ${error.message}');
            print('Firebase Error Details: ${error.stackTrace}');
          }
        })
        .map((snapshot) {
          print('=== PROCESSING SNAPSHOT ===');
          print('Total documents: ${snapshot.docs.length}');
          
          if (snapshot.docs.isEmpty) {
            print('No documents found in menus collection!');
            return <FoodDetailModel>[];
          }
          
          List<FoodDetailModel> foods = [];
          int successCount = 0;
          int errorCount = 0;
          
          for (int i = 0; i < snapshot.docs.length; i++) {
            final doc = snapshot.docs[i];
            print('\n--- Processing document ${i + 1}/${snapshot.docs.length} ---');
            print('Document ID: ${doc.id}');
            
            if (doc.data() == null) {
              print('Document data is null, skipping');
              errorCount++;
              continue;
            }
            
            try {
              final data = doc.data() as Map<String, dynamic>;
              final food = FoodDetailModel.fromJsonFood(data, doc.id);
              foods.add(food);
              successCount++;
              print('✅ Successfully parsed document ${doc.id}');
            } catch (e) {
              errorCount++;
              print('❌ Failed to parse document ${doc.id}: $e');
              print('Document data: ${doc.data()}');
              // Continue processing other documents
            }
          }
          
          print('\n=== PROCESSING SUMMARY ===');
          print('Total documents: ${snapshot.docs.length}');
          print('Successfully parsed: $successCount');
          print('Errors: $errorCount');
          print('Returning ${foods.length} food items');
          
          return foods;
        });
  }

  // STEP 3: MANUAL DEBUG METHOD
  Future<void> manualDebugFirestore() async {
    print('\n=== MANUAL FIRESTORE DEBUG ===');
    
    try {
      print('Testing connection to menus collection...');
      final QuerySnapshot snapshot = await _foodCollection.limit(5).get();
      
      print('Found ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('❌ NO DOCUMENTS FOUND IN MENUS COLLECTION!');
        print('Check your collection name and Firebase project');
        return;
      }
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        print('\n--- Document ${i + 1} ---');
        print('ID: ${doc.id}');
        print('Exists: ${doc.exists}');
        
        if (doc.data() == null) {
          print('❌ Document data is NULL');
        } else {
          final data = doc.data() as Map<String, dynamic>;
          print('✅ Document data exists');
          print('Keys: ${data.keys.toList()}');
          print('Full data: $data');
          
          // Try to parse this document
          try {
            final food = FoodDetailModel.fromJsonFood(data, doc.id);
            print('✅ Parsing successful: ${food.foodName}');
          } catch (e) {
            print('❌ Parsing failed: $e');
          }
        }
      }
    } catch (e) {
      print('❌ CRITICAL ERROR accessing Firestore: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // STEP 4: SIMPLE TEST METHOD
  Future<List<FoodDetailModel>> getSimpleFoodsList() async {
    try {
      final snapshot = await _foodCollection.get();
      List<FoodDetailModel> foods = [];
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          try {
            foods.add(FoodDetailModel.fromJsonFood(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ));
          } catch (e) {
            print('Skipping document ${doc.id} due to error: $e');
          }
        }
      }
      
      return foods;
    } catch (e) {
      print('Error in getSimpleFoodsList: $e');
      return [];
    }
  }
}

// STEP 5: TEST WIDGET
/*
class DebugFoodWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = CatogaryService();
    
    return Scaffold(
      appBar: AppBar(title: Text('Debug Foods')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => service.manualDebugFirestore(),
            child: Text('Manual Debug'),
          ),
          Expanded(
            child: StreamBuilder<List<FoodDetailModel>>(
              stream: service.getFoodsSafe(),
              builder: (context, snapshot) {
                print('StreamBuilder state: ${snapshot.connectionState}');
                print('StreamBuilder has error: ${snapshot.hasError}');
                print('StreamBuilder has data: ${snapshot.hasData}');
                
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text('Stream Error: ${snapshot.error}'),
                      ElevatedButton(
                        onPressed: () => service.manualDebugFirestore(),
                        child: Text('Debug Firestore'),
                      ),
                    ],
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData) {
                  return Text('No data received');
                }
                
                final foods = snapshot.data!;
                if (foods.isEmpty) {
                  return Column(
                    children: [
                      Text('No food items found'),
                      ElevatedButton(
                        onPressed: () => service.manualDebugFirestore(),
                        child: Text('Debug Firestore'),
                      ),
                    ],
                  );
                }
                
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return ListTile(
                      title: Text(food.foodName),
                      subtitle: Text('Price: \$${food.price}'),
                      trailing: Text('Time: ${food.cookedTime}min'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
*/