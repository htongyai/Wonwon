import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_category.freezed.dart';
part 'service_category.g.dart';

@freezed
class ServiceCategory with _$ServiceCategory {
  const factory ServiceCategory({
    required String id,
    required String nameTh,
    required String nameEn,
    required String icon,
    required List<SubService> subServices,
  }) = _ServiceCategory;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      _$ServiceCategoryFromJson(json);
}

@freezed
class SubService with _$SubService {
  const factory SubService({
    required String id,
    required String nameTh,
    required String nameEn,
    required String icon,
    String? descriptionTh,
    String? descriptionEn,
  }) = _SubService;

  factory SubService.fromJson(Map<String, dynamic> json) =>
      _$SubServiceFromJson(json);
}

class ServiceCategories {
  static List<ServiceCategory> getCategories() {
    return [
      ServiceCategory(
        id: 'clothing',
        nameTh: 'เสื้อผ้า',
        nameEn: 'Clothing',
        icon: 'assets/icons/clothing.png',
        subServices: [
          SubService(
            id: 'zipper_replacement',
            nameTh: 'เปลี่ยนซิป',
            nameEn: 'Zipper replacement',
            icon: 'assets/icons/zipper.png',
          ),
          SubService(
            id: 'pants_hemming',
            nameTh: 'ตัดขากางเกง',
            nameEn: 'Pants hemming',
            icon: 'assets/icons/hemming.png',
          ),
          SubService(
            id: 'waist_adjustment',
            nameTh: 'ปรับเอวกางเกง/กระโปรง',
            nameEn: 'Waist adjustment',
            icon: 'assets/icons/waist.png',
          ),
          SubService(
            id: 'elastic_replacement',
            nameTh: 'เปลี่ยนยางยืด',
            nameEn: 'Elastic replacement',
            icon: 'assets/icons/elastic.png',
          ),
          SubService(
            id: 'button_replacement',
            nameTh: 'เปลี่ยนกระดุม',
            nameEn: 'Button replacement',
            icon: 'assets/icons/button.png',
          ),
          SubService(
            id: 'collar_replacement',
            nameTh: 'เปลี่ยนคอเสื้อ',
            nameEn: 'Collar replacement',
            icon: 'assets/icons/collar.png',
          ),
          SubService(
            id: 'tear_repair',
            nameTh: 'ซ่อมรอยขาด',
            nameEn: 'Tear repair',
            icon: 'assets/icons/tear.png',
          ),
          SubService(
            id: 'add_pockets',
            nameTh: 'ทำกระเป๋ากางเกง/เสื้อ',
            nameEn: 'Add pockets',
            icon: 'assets/icons/pocket.png',
          ),
        ],
      ),
      ServiceCategory(
        id: 'footwear',
        nameTh: 'รองเท้า',
        nameEn: 'Footwear',
        icon: 'assets/icons/footwear.png',
        subServices: [
          SubService(
            id: 'sole_replacement',
            nameTh: 'เปลี่ยนพื้นรองเท้า',
            nameEn: 'Sole replacement',
            icon: 'assets/icons/sole.png',
          ),
          SubService(
            id: 'leather_repair',
            nameTh: 'ซ่อมรองเท้าหนัง',
            nameEn: 'Leather shoe repair',
            icon: 'assets/icons/leather.png',
          ),
          SubService(
            id: 'heel_repair',
            nameTh: 'ซ่อมหรือเปลี่ยนส้นรองเท้า',
            nameEn: 'Heel repair/replacement',
            icon: 'assets/icons/heel.png',
          ),
          SubService(
            id: 'shoe_cleaning',
            nameTh: 'ทำความสะอาดรองเท้า',
            nameEn: 'Shoe cleaning',
            icon: 'assets/icons/cleaning.png',
          ),
        ],
      ),
      ServiceCategory(
        id: 'watch',
        nameTh: 'นาฬิกา',
        nameEn: 'Watch',
        icon: 'assets/icons/watch.png',
        subServices: [
          SubService(
            id: 'scratch_removal',
            nameTh: 'ลบรอย',
            nameEn: 'Scratch removal',
            icon: 'assets/icons/scratch.png',
          ),
          SubService(
            id: 'battery_replacement',
            nameTh: 'เปลี่ยนแบต',
            nameEn: 'Battery replacement',
            icon: 'assets/icons/battery.png',
          ),
          SubService(
            id: 'watch_cleaning',
            nameTh: 'ล้างนาฬิกา',
            nameEn: 'Watch cleaning',
            icon: 'assets/icons/cleaning.png',
          ),
          SubService(
            id: 'strap_replacement',
            nameTh: 'เปลี่ยนสายนาฬิกา',
            nameEn: 'Strap replacement',
            icon: 'assets/icons/strap.png',
          ),
          SubService(
            id: 'glass_replacement',
            nameTh: 'เปลี่ยนกระจก',
            nameEn: 'Glass replacement',
            icon: 'assets/icons/glass.png',
          ),
          SubService(
            id: 'authenticity_check',
            nameTh: 'ตรวจแท้ตรวจปลอม',
            nameEn: 'Authenticity check',
            icon: 'assets/icons/authenticity.png',
          ),
        ],
      ),
      ServiceCategory(
        id: 'bag',
        nameTh: 'กระเป๋า',
        nameEn: 'Bag',
        icon: 'assets/icons/bag.png',
        subServices: [
          SubService(
            id: 'bag_repair',
            nameTh: 'ซ่อมกระเป๋าหลากหลายประเภท',
            nameEn: 'Various bag repairs',
            descriptionTh:
                'กระเป๋าสตรี, แบรนด์เนม, เดินทาง, เอกสาร, เป้, กีฬา, นักเรียน, ถุงกอล์ฟ, เข็มขัด, เสื้อหนัง, กระเป๋าโน๊ตบุ๊ค, เครื่องดนตรี, ส่งอาหาร, ซ่อมรองเท้า, ซ่อมรถเข็นเด็ก',
            descriptionEn:
                'Women\'s bags, brand name, travel, document, backpack, sports, student, golf bag, belt, leather jacket, laptop bag, musical instruments, food delivery, shoe repair, stroller repair',
            icon: 'assets/icons/bag_repair.png',
          ),
        ],
      ),
      ServiceCategory(
        id: 'appliances',
        nameTh: 'เครื่องใช้ไฟฟ้า',
        nameEn: 'Appliances',
        icon: 'assets/icons/appliance.png',
        subServices: [
          SubService(
            id: 'small_appliances',
            nameTh: 'เครื่องใช้ไฟฟ้าขนาดเล็ก',
            nameEn: 'Small appliances',
            descriptionTh: 'พัดลม, ไดเป่าผม, ไมโครเวฟ, รีโมทแอร์',
            descriptionEn: 'Fan, hair dryer, microwave, air conditioner remote',
            icon: 'assets/icons/small_appliance.png',
          ),
          SubService(
            id: 'large_appliances',
            nameTh: 'เครื่องใช้ไฟฟ้าขนาดใหญ่',
            nameEn: 'Large appliances',
            descriptionTh: 'ตู้เย็น, เครื่องซักผ้า, เครื่องอบผ้า',
            descriptionEn: 'Refrigerator, washing machine, dryer',
            icon: 'assets/icons/large_appliance.png',
          ),
        ],
      ),
      ServiceCategory(
        id: 'electronics',
        nameTh: 'อิเล็กทรอนิกส์',
        nameEn: 'Electronics',
        icon: 'assets/icons/electronics.png',
        subServices: [
          SubService(
            id: 'laptop',
            nameTh: 'โน๊ตบุ๊ค',
            nameEn: 'Laptop',
            icon: 'assets/icons/laptop.png',
          ),
          SubService(
            id: 'mac',
            nameTh: 'Mac / iMac / Mac Pro',
            nameEn: 'Mac / iMac / Mac Pro',
            icon: 'assets/icons/mac.png',
          ),
          SubService(
            id: 'mobile',
            nameTh: 'โทรศัพท์มือถือ และแท็บเล็ต',
            nameEn: 'Mobile phones and tablets',
            descriptionTh: 'iPhone, iPad',
            descriptionEn: 'iPhone, iPad',
            icon: 'assets/icons/mobile.png',
          ),
          SubService(
            id: 'network',
            nameTh: 'อุปกรณ์เน็ตเวิร์ค',
            nameEn: 'Networking devices',
            icon: 'assets/icons/network.png',
          ),
          SubService(
            id: 'printer',
            nameTh: 'เครื่องพิมพ์',
            nameEn: 'Printers',
            icon: 'assets/icons/printer.png',
          ),
          SubService(
            id: 'audio',
            nameTh: 'หูฟัง, ลำโพง',
            nameEn: 'Audio devices',
            icon: 'assets/icons/audio.png',
          ),
          SubService(
            id: 'other_electronics',
            nameTh: 'อื่น ๆ',
            nameEn: 'Others',
            icon: 'assets/icons/other.png',
          ),
        ],
      ),
    ];
  }
}
