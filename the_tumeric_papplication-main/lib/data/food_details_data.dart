import 'package:the_tumeric_papplication/models/food_detail_model.dart';

class FoodDetailsData {
  List<FoodDetailModel> foodDetailsList = [
    FoodDetailModel(
      foodName: "Chicken Biriysni",
      discription:
          "A flavorful and aromatic rice dish made with tender chicken pieces, long-grain basmati rice, and a blend of traditional spices. Cooked to perfection with layers of herbs, fried onions, and saffron, this classic biryani offers a rich and satisfying taste in every bite.",
      imageUrl:
          "https://images.rawpixel.com/image_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDI0LTA3L2FuZ3VzdGVvd19hX3Bob3RvX29mX2FfY2hpY2tlbl9oYW5kaV9iaXJ5YW5pX3NpZGVfdmlld19pc29sYXRlZF85ZmZjNjI3MC05M2IzLTQ3NDMtYjllYS05OGE2NzEwMjFkZThfMS5qcGc.jpg",
      price: 4.23,
      cookedTime: 23,
    ),
    FoodDetailModel(
      foodName: "Kottu",
      discription:
          "A beloved Sri Lankan street food made by chopping flatbread (roti) and stir-frying it with vegetables, eggs, and your choice of meat. Infused with spicy curry flavors and sizzling on a hot griddle, Kottu delivers a loud, satisfying taste in every bite.",

      imageUrl:
          "https://media-cdn.tripadvisor.com/media/photo-s/0f/b0/5c/a0/wok-cheese-kottu.jpg",
      price: 3.00,
      cookedTime: 30,
    ),
  ];
}
