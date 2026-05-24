import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'favorites_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashPage(),
    );
  }
}

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});
  
  

  @override
  State<TravelPage> createState() => _TravelPageState();
}

  class _TravelPageState extends State<TravelPage> {

    @override
void initState() {
  super.initState();
  loadRecentRoutes();
}
  

  String selectedCity = "";
  String? selectedInterest  ;
  String? selectedDay ;
  DateTimeRange? selectedDateRange;

  String responseText = "";
  bool isLoading = false;
  bool isDarkMode = false;
  String weatherInfo = "";
  List<Map<String, dynamic>> recentRoutes = [];

  final TextEditingController citySearchController = TextEditingController();

  final List<String> cities = [
  "Adana","Adıyaman","Afyonkarahisar","Ağrı","Aksaray",
  "Amasya","Ankara","Antalya","Ardahan","Artvin",
  "Aydın","Balıkesir","Bartın","Batman","Bayburt",
  "Bilecik","Bingöl","Bitlis","Bolu","Burdur",
  "Bursa","Çanakkale","Çankırı","Çorum","Denizli",
  "Diyarbakır","Düzce","Edirne","Elazığ","Erzincan",
  "Erzurum","Eskişehir","Gaziantep","Giresun","Gümüşhane",
  "Hakkari","Hatay","Iğdır","Isparta","İstanbul",
  "İzmir","Kahramanmaraş","Karabük","Karaman","Kars",
  "Kastamonu","Kayseri","Kırıkkale","Kırklareli","Kırşehir",
  "Kilis","Kocaeli","Konya","Kütahya","Malatya",
  "Manisa","Mardin","Mersin","Muğla","Muş",
  "Nevşehir","Niğde","Ordu","Osmaniye","Rize",
  "Sakarya","Samsun","Siirt","Sinop","Sivas",
  "Şanlıurfa","Şırnak","Tekirdağ","Tokat","Trabzon",
  "Tunceli","Uşak","Van","Yalova","Yozgat","Zonguldak"
];
  final List<String> interests = ["Tarihi yerler", "Doğa", "Yemek", "Alışveriş"];
  final List<String> days = [
  "Yarım Gün",
  "1 Gün",
  "2 Gün",
  "3 Gün",
  "4 Gün",
  "5 Gün",
  "1 Hafta"
];

Future<void> loadRecentRoutes() async {
  final prefs = await SharedPreferences.getInstance();
  final savedRoutes = prefs.getStringList("recent_routes") ?? [];

  setState(() {
    recentRoutes = savedRoutes
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  });
}

Future<void> saveRecentRoute(String routeText) async {
  final prefs = await SharedPreferences.getInstance();

  final recentRoute = {
    "city": selectedCity,
    "interest": selectedInterest,
    "duration": selectedDay,
    "routeText": routeText,
    "weatherInfo": weatherInfo,
  };

  List<String> savedRoutes =
      prefs.getStringList("recent_routes") ?? [];

  savedRoutes.insert(0, jsonEncode(recentRoute));

  if (savedRoutes.length > 5) {
    savedRoutes = savedRoutes.take(5).toList();
  }

  await prefs.setStringList("recent_routes", savedRoutes);

  await loadRecentRoutes();
}

int getTravelDayCount() {
  if (selectedDay == "Yarım Gün") return 1;
  if (selectedDay == "1 Gün") return 1;
  if (selectedDay == "2 Gün") return 2;
  if (selectedDay == "3 Gün") return 3;
  if (selectedDay == "4 Gün") return 4;
  if (selectedDay == "5 Gün") return 5;
  if (selectedDay == "1 Hafta") return 7;
  return 1;
}

  Future<void> sendRequest() async {
    if (
  selectedCity.isEmpty ||
  selectedInterest == null ||
  selectedDateRange == null
) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Lütfen şehir, ilgi alanı ve seyahat tarihi seçiniz.",
      ),
    ),
  );
  return;
}
    setState(() {
      isLoading = true;
      responseText = "";
    });
    showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 6.28,
                  child: child,
                );
              },
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: Color(0xFF4F46E5),
                size: 46,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Rotan hazırlanıyor...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Popüler duraklar seçiliyor ✨",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  },
);

    try {
      final weatherUrl = Uri.parse(
  "https://api.openweathermap.org/data/2.5/forecast?q=$selectedCity,tr&appid=YOUR_OPENWEATHER_API_KEY",
);

final weatherResponse = await http.get(weatherUrl);

if (weatherResponse.statusCode == 200) {
  final weatherData = jsonDecode(weatherResponse.body);

  final List forecastList = weatherData["list"];

  final int travelDays = getTravelDayCount();
  final int maxDays = travelDays > 5 ? 5 : travelDays;

  List<String> dailyWeather = [];

  for (int i = 0; i < maxDays; i++) {
    final item = forecastList[i * 8];

    final temp = item["main"]["temp"];
    final description = item["weather"][0]["description"];

    dailyWeather.add(
      "${i + 1}. Gün: $temp derece, $description",
    );
  }

  if (travelDays > 5) {
    dailyWeather.add(
      "6-7. Gün: 5 günden sonrası için hava tahmini alınamadı, genel mevsim koşullarına göre rota öner.",
    );
  }

  weatherInfo = dailyWeather.join("\n");
} else {
  weatherInfo = "Hava durumu alınamadı";
}
      final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer YOUR_GROQ_API_KEY",
            },
            body: jsonEncode({
              "model": "llama-3.3-70b-versatile",
              "messages": [
                {
                  "role": "user",
                   "content": """
Sen Türkiye şehirlerini bilen profesyonel bir seyahat rehberisin.

Görev:
Kullanıcının seçtiği şehir, ilgi alanı, süre ve hava durumuna göre gezi planı oluştur.

Kullanıcı Bilgileri:
Şehir: $selectedCity
İlgi Alanı: ${selectedInterest!}
Süre: ${selectedDay!}
Hava Durumu: $weatherInfo

Kesin Kurallar:
- Sadece gerçek ve popüler mekanları öner.
- Uydurma mekan yazma.
- Mekanlar sadece seçilen şehirde olsun.
- Başka şehirden mekan yazma.
- Google Maps'te bulunabilecek bilinen yerleri seç.
- Aynı mekanı tekrar etme.
- Hava durumunu dikkate al.
- Yağmurluysa kapalı mekanları önceliklendir.
- Güneşliyse açık hava mekanlarını da ekle.
- Giriş cümlesi yazma.
- Emoji ve markdown kullanma.

Süre Kuralları:
- Yarım Gün: 1 gün yaz, toplam 2 durak öner.
- 1 Gün: 1 gün yaz, toplam 4 durak öner.
- 2 Gün: 2 gün yaz, her gün 3 durak öner.
- 3 Gün: 3 gün yaz, her gün 3 durak öner.
- 4 Gün: 4 gün yaz, her gün 3 durak öner.
- 5 Gün: 5 gün yaz, her gün 3 durak öner.
- 1 Hafta: 7 gün yaz, her gün 2 veya 3 durak öner.

Formatı bozma:

1. Gün

Durak 1: Yer adı
Saat: 09:00 - 10:00
Ulaşım: Yürüyerek / Metro / Tramvay / Otobüs
Not: Tek kısa cümle

Durak 2: Yer adı
Saat: 10:30 - 11:30
Ulaşım: Yürüyerek
Not: Tek kısa cümle
"""
            
                }
            ],
              "stream": false
            }),
          )
          
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      setState(() {
        if (response.statusCode == 200) {
          responseText = data["choices"][0]["message"]["content"]
    .replaceAll("**", "")
    .replaceAll("#", "")
    .replaceAll("*", "")
    .replaceAll(RegExp(r'[^\w\sğüşöçıİĞÜŞÖÇ.,:;!?()-]'), "")
    .trim();
final createdRoute = responseText;
saveRecentRoute(createdRoute);
Navigator.pop(context);
 Navigator.push(
  context,
  PageRouteBuilder(
    transitionDuration: const Duration(
      milliseconds: 320,
    ),
    pageBuilder: (
      context,
      animation,
      secondaryAnimation,
    ) {
        return RouteResultPage(
  city: selectedCity,
  interest: selectedInterest!,
  day: selectedDay!,
  routeText: createdRoute,
  weather: weatherInfo,
);
    },
    transitionsBuilder: (
      context,
      animation,
      secondaryAnimation,
      child,
    ) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  ),
);

setState(() {
  responseText = "";
});
        } else {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }

  responseText = "API hatası: ${response.statusCode}\n${response.body}";

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("API hatası: ${response.statusCode}"),
    ),
  );
}
        isLoading = false;
      });
    } catch (e) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }

  setState(() {
    responseText = "Bağlantı hatası: $e";
    isLoading = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Bağlantı hatası: $e"),
    ),
  );
}
  }
  Future<void> openMap() async {
  final query = Uri.encodeComponent("$selectedCity gezilecek yerler");
  final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode: LaunchMode.inAppBrowserView,
    );
  }
}

  Widget buildDropdown({
    required IconData icon,
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6D3FD9)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF2D2440),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
Future<void> pickTravelDateRange() async {
  final pickedRange = await showDateRangePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(
      const Duration(days: 365),
    ),
    initialDateRange: selectedDateRange,
  );

  if (pickedRange != null) {
    final totalDays =
        pickedRange.end.difference(pickedRange.start).inDays + 1;

    setState(() {
      selectedDateRange = pickedRange;

      if (totalDays <= 1) {
        selectedDay = "1 Gün";
      } else if (totalDays == 2) {
        selectedDay = "2 Gün";
      } else if (totalDays == 3) {
        selectedDay = "3 Gün";
      } else if (totalDays == 4) {
        selectedDay = "4 Gün";
      } else if (totalDays == 5) {
        selectedDay = "5 Gün";
      } else {
        selectedDay = "1 Hafta";
      }
    });
  }
}
  void showCitySearchSheet() {
  List<String> filteredCities = List.from(cities);
  citySearchController.clear();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  const Text(
                    "Şehir Ara",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: citySearchController,
                    decoration: InputDecoration(
                      hintText: "Örn: Bursa",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        filteredCities = cities
                            .where((city) => city
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return ListTile(
                          title: Text(city),
                          trailing: city == selectedCity
                              ? const Icon(Icons.check, color: Color(0xFF4F46E5))
                              : null,
                          onTap: () {
                            setState(() {
                              selectedCity = city;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode
         ? const Color(0xFF0F172A)
         : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                 ? [
                     const Color(0xFF020617),
                     const Color(0xFF0F172A),
                     const Color(0xFF111827),
                  ]
                 : [
                     const Color(0xFF0F172A),
                     const Color(0xFF312E81),
                     const Color(0xFFF8FAFC),
                  ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.36, 0.36],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
               Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FavoritesPage(),
          ),
        );
      },
      icon: const Icon(
        Icons.favorite,
        color: Colors.white,
      ),
    ),

    IconButton(
      onPressed: () {
        setState(() {
          isDarkMode = !isDarkMode;
        });
      },
      icon: Icon(
        isDarkMode
            ? Icons.light_mode_rounded
            : Icons.dark_mode_rounded,
        color: Colors.white,
      ),
    ),
  ],
),
                const Text(
                  "Akıllı Seyahat Asistanı",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Şehir, ilgi alanı ve süre seç. Yapay zeka sana özel rota oluştursun.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    infoChip(Icons.auto_awesome, "AI Destekli"),
                    infoChip(Icons.route, "Kişisel Rota"),
                    infoChip(Icons.schedule, "Saatlik Plan"),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFFE2E8F0),
                            child: Icon(
                              Icons.travel_explore_rounded,
                              color: Color(0xFF4F46E5),
                              size: 26,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Gezi Rotanı Oluştur",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF241B35),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                    
                      const SizedBox(height: 22),

                      Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Row(
      children: [
        Icon(Icons.location_city_rounded, size: 18, color: Color(0xFF4F46E5)),
        SizedBox(width: 8),
        Text(
          "Şehir Seç",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF2D2440),
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),
    InkWell(
      onTap: showCitySearchSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedCity,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.search, color: Color(0xFF4F46E5)),
          ],
        ),
      ),
    ),
  ],
),
                      const SizedBox(height: 18),

                      buildDropdown(
                        icon: Icons.favorite_rounded,
                        title: "İlgi Alanı Seç",
                        value: selectedInterest,
                        items: interests,
                        onChanged: (value) {
                          setState(() {
                            selectedInterest = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Row(
      children: [
        Icon(
          Icons.event_rounded,
          size: 18,
          color: Color(0xFF4F46E5),
        ),
        SizedBox(width: 8),
        Text(
          "Seyahat Tarihi",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF2D2440),
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),
    InkWell(
       onTap: pickTravelDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDateRange == null
    ? "Tarih aralığı seç"
    : "${selectedDateRange!.start.day}.${selectedDateRange!.start.month}.${selectedDateRange!.start.year} - "
      "${selectedDateRange!.end.day}.${selectedDateRange!.end.month}.${selectedDateRange!.end.year}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF4F46E5),
            ),
          ],
        ),
      ),
    ),
    if (selectedDay != null) ...[
  const SizedBox(height: 10),
  Text(
    "Otomatik Süre: $selectedDay",
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF4F46E5),
    ),
  ),
],
  ],
),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () {
                           sendRequest();
                            },
                          style: ElevatedButton.styleFrom(
                            elevation: 8,
                            shadowColor:
                                const Color(0xFF6D3FD9).withOpacity(0.35),
                            backgroundColor: const Color(0xFF4F46E5),
                            disabledBackgroundColor: const Color(0xFFD8CCF7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "AI Rota Oluştur",
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

               const SizedBox(height: 22),
               if (recentRoutes.isNotEmpty) ...[
  Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Son Oluşturulanlar",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF241B35),
          ),
        ),
        const SizedBox(height: 12),

        ...recentRoutes.map((item) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.history,
              color: Color(0xFF4F46E5),
            ),
            title: Text("${item["city"]} Rotası"),
            subtitle: Text(
              "${item["interest"]} • ${item["duration"]}",
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteResultPage(
                    city: item["city"],
                    interest: item["interest"],
                    day: item["duration"],
                    routeText: item["routeText"],
                    weather: item["weatherInfo"],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ],
    ),
  ),
  const SizedBox(height: 22),
],

if (isLoading) ...[
  Container(
    padding: const EdgeInsets.all(24),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 6.28,
              child: child,
            );
          },
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: Color(0xFF4F46E5),
              size: 32,
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          "Rotan hazırlanıyor...",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF241B35),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Şehir, hava durumu ve ilgi alanın analiz ediliyor.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF6E647C),
          ),
        ),

        const SizedBox(height: 18),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const LinearProgressIndicator(
            minHeight: 7,
            color: Color(0xFF4F46E5),
            backgroundColor: Color(0xFFEDEBFF),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          "Popüler duraklar seçiliyor ✨",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4F46E5),
          ),
        ),
      ],
    ),
  ),
],
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class RouteResultPage extends StatelessWidget {
  final String city;
  final String interest;
  final String day;
  final String routeText;
  final String weather;

  bool isFavorite = false;

   RouteResultPage({
    super.key,
    required this.city,
    required this.interest,
    required this.day,
    required this.routeText,
    required this.weather,
  });

List<String> getDaySections() {
  if (routeText.isEmpty) return [];

  final matches = RegExp(
    r'(\d+\.\s*Gün.*?)(?=\d+\.\s*Gün|$)',
    dotAll: true,
  ).allMatches(routeText);

  return matches
      .map((m) => m.group(0)!.trim())
      .toList();
}

String getMapQuery() {
  final lines = routeText.split('\n');

  final stops = lines
      .where((line) => line.trim().startsWith("Durak"))
      .map((line) {
        return line
            .replaceAll(RegExp(r'Durak\s+\d+:'), '')
            .trim();
      })
      .where((place) => place.isNotEmpty)
      .take(5)
      .join(" ");

  return "$city $stops";
}
Future<void> saveFavorite(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  List<String> favorites =
      prefs.getStringList("favorite_routes") ?? [];

  final favoriteRoute = {
    "city": city,
    "interest": interest,
    "duration": day,
    "routeText": routeText,
    "weatherInfo": weather,
  };

  final encodedRoute = jsonEncode(favoriteRoute);

  if (favorites.contains(encodedRoute)) {
    isFavorite = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Bu rota zaten favorilerde ❤️",
        ),
      ),
    );
    return;
  }

  favorites.add(encodedRoute);

  await prefs.setStringList(
    "favorite_routes",
    favorites,
  );

  isFavorite = true;

  (context as Element).markNeedsBuild();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Rota favorilere kaydedildi ❤️",
      ),
    ),
  );
}
void shareRoute() {
  final text = """
$city $interest Rotası
Süre: $day
Hava Durumu: $weather

$routeText
""";

  Share.share(text);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF241B35),
        title: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      "$city ${interest.split(' ').first} Rotası",
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
    ),
    Text(
      "$day Keşif Planı",
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    ),
  ],
),
actions: [
  IconButton(
    icon: const Icon(Icons.share),
    onPressed: shareRoute,
  ),
   IconButton(
    icon: Icon(
      isFavorite
          ? Icons.favorite
          : Icons.favorite_border,
      color:
          isFavorite ? Colors.red : null,
    ),
    onPressed: () {
      saveFavorite(context);
    },
  ),
],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: infoBox(
                          Icons.location_on_rounded,
                          city,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: infoBox(
                          Icons.favorite_rounded,
                          interest,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: infoBox(
                          Icons.schedule_rounded,
                          day,
                        ),
                      ),
                    ],
                  ),
                Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: const Color(0xFFF4F4FF),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: const Color(0xFFE4E7F2),
    ),
  ),
  child: Row(
    children: [
      const Icon(
        Icons.cloud_rounded,
        color: Color(0xFF4F46E5),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          weather,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF312942),
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 18),
                const SizedBox(height: 22),

                  Column(
                    children:
                        getDaySections().asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final dayText = entry.value;

                      return Container(
                        width: double.infinity,
                        margin:
                            const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius:
                              BorderRadius.circular(22),
                              boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 18,
    offset: const Offset(0, 8),
  ),
],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$index. Gün",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w800,
                                color:
                                    Color(0xFF4F46E5),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              dayText.replaceFirst(
                                RegExp(r'\d+\.\s*Gün'),
                                "",
                              ).trim(),
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color:
                                    Color(0xFF312942),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

SizedBox(
  width: double.infinity,
  height: 54,
  child: OutlinedButton.icon(
    onPressed: () async {
      final query = Uri.encodeComponent(getMapQuery());

      final url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$query",
      );

        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      },
     
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Color(0xFF4F46E5),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    icon: const Icon(
      Icons.map_rounded,
      color: Color(0xFF4F46E5),
    ),
    label: const Text(
      "Google Maps'te Aç",
      style: TextStyle(
        color: Color(0xFF4F46E5),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoBox(
    IconData icon,
    String text,
  ) {
  return Container(
    padding: const EdgeInsets.symmetric(
      vertical: 16,
      horizontal: 10,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0xFFE7E9F4),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),

    child: Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4F46E5),
          size: 20,
        ),

        const SizedBox(height: 6),

        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
}
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TravelPage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF312E81),
              Color(0xFF4F46E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  "Akıllı Seyahat Asistanı",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "AI Travel Planner",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 34),

                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}