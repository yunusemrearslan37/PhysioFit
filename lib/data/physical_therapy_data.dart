class PhysicalTherapyExercise {
  final String name;
  final String description;
  final List<String> instructions;

  const PhysicalTherapyExercise({
    required this.name,
    required this.description,
    required this.instructions,
  });
}

class PhysicalTherapyCategory {
  final String name;
  final String englishName;
  final String level;
  final int exerciseCount;
  final List<PhysicalTherapyExercise> exercises;

  const PhysicalTherapyCategory({
    required this.name,
    required this.englishName,
    required this.level,
    required this.exerciseCount,
    required this.exercises,
  });
}

class PhysicalTherapyData {
  static const List<PhysicalTherapyCategory> categories = [
    PhysicalTherapyCategory(
      name: 'Boyun',
      englishName: 'Neck',
      level: 'Ev Seviyesi',
      exerciseCount: 6,
      exercises: [
        PhysicalTherapyExercise(
          name: 'Boyun Yan Eğme (Side Neck Stretch)',
          description:
              'Boyun yan kaslarını germek ve boyun bölgesindeki gerginliği azaltmak için kullanılan temel esneme hareketidir.',
          instructions: [
            'Dik oturun veya ayakta durun; omuzlar gevşek, göğüs yukarıda',
            'Başınızı yavaşça sağa eğin; sol elinizle başınıza hafifçe destek verebilirsiniz',
            'Hafif gerilme hissedene kadar bekleyin; keskin ağrı olmamalı',
            '20-30 saniye tutun, nefesinizi düzenli alın',
            'Başı orta hizaya getirip sol tarafa tekrarlayın',
            'Her taraf 2-3 tekrar',
            'Başınızı zorla çekmeyin; boyun ağrısında hareketi durdurun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Çene İçeri Çekme (Chin Tuck)',
          description:
              'Boyun duruşunu düzeltmek ve derin boyun fleksör kaslarını güçlendirmek için etkili bir postür egzersizidir.',
          instructions: [
            'Dik oturun; başınız ve omuzlarınız duvara veya nötr hizada',
            'Çenenizi hafifçe geriye çekin; boynunuzda çift çene oluşsun',
            'Başınızı yukarı veya aşağı eğmeyin',
            '5-10 saniye sıkı tutun',
            'Gevşetin ve 10-15 tekrar yapın',
            'Gün boyunca birkaç set uygulayabilirsiniz',
            'Boyun ağrısında hareket açıklığını azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Boyun Rotasyon (Neck Rotation)',
          description:
              'Boyun rotasyon hareketliliğini artırmak için yavaş ve kontrollü döndürme egzersizidir.',
          instructions: [
            'Dik oturun; omuzlar sabit ve gevşek',
            'Başınızı yavaşça sağa çevirin; bakışınız omuz hizasına gelsin',
            '2-3 saniye bekleyin',
            'Orta hizaya dönün ve sola tekrarlayın',
            'Her yön 8-10 tekrar',
            'Hızlı ve sert dönüş yapmayın',
            'Baş dönmesi veya ağrıda durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Ön Boyun Germe',
          description:
              'Boyun arka kaslarını germek ve öne eğilme sonrası gerginliği azaltmak için kullanılır.',
          instructions: [
            'Dik oturun veya ayakta durun',
            'Çenenizi göğsünüze doğru yavaşça eğin',
            'İki elinizi başınızın arkasına koyup hafif destek verebilirsiniz',
            'Boyun arkasında hafif gerilme hissedin',
            '20-30 saniye tutun',
            'Yavaşça başlangıç pozisyonuna dönün',
            'Keskin ağrıda zorlamayın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Omuz Silkme (Shoulder Shrug)',
          description:
              'Trapezius kaslarını gevşetmek ve boyun-omuz bölgesindeki gerginliği azaltmak için basit bir harekettir.',
          instructions: [
            'Ayakta veya oturarak dik durun',
            'Omuzlarınızı kulaklarınıza doğru yukarı kaldırın',
            '2-3 saniye sıkı tutun',
            'Omuzları tamamen gevşeterek indirin',
            '10-15 tekrar',
            'Nefes verirken kaldırın, nefes alırken indirin',
            'Boyun ağrısında hareket genişliğini azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Kürek Kemiği Sıkma',
          description:
              'Omuzları geriye alarak boyun ve üst sırt postürünü destekleyen aktivasyon egzersizidir.',
          instructions: [
            'Dik oturun veya ayakta durun; kollar yanlarda',
            'Kürek kemiklerinizi arkaya ve aşağıya doğru sıkıştırın',
            'Göğsünüz hafifçe yukarı açılsın',
            '5 saniye tutun',
            'Gevşetin ve 10-15 tekrar yapın',
            'Boynu öne uzatmayın',
            'Omuz ağrısında hareketi yavaşlatın',
          ],
        ),
      ],
    ),
    PhysicalTherapyCategory(
      name: 'Omuz',
      englishName: 'Shoulder',
      level: 'Ev Seviyesi',
      exerciseCount: 8,
      exercises: [
        PhysicalTherapyExercise(
          name: 'Kol Duvar Yürüyüşü (Wall Walk Up)',
          description:
              'Omuz fleksiyonunu ağrısız aralıkta artırmak için duvar destekli mobilizasyon hareketidir.',
          instructions: [
            'Duvara yan dönün; parmak uçları duvar hizasında',
            'Parmaklarınızla duvar üzerinde yavaşça yukarı yürüyün',
            'Ağrısız maksimum yüksekliğe ulaşın',
            'Aynı yolla kontrollü şekilde aşağı inin',
            '8-12 tekrar',
            'Omuzları kulaklara çekmeyin',
            'Keskin omuz ağrısında yüksekliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Omuz Dairesel Hareket (Shoulder Circles)',
          description:
              'Omuz eklemi hareketliliğini artırmak için küçük dairesel hareketlerle yapılan ısınma egzersizidir.',
          instructions: [
            'Ayakta dik durun; kollar yanlarda',
            'Omuzlarınızı küçük daireler çizerek öne, yukarı, geriye hareket ettirin',
            '10 daire ileri yön',
            '10 daire geri yön',
            'Hareket yavaş ve kontrollü olsun',
            'Ağrısız aralıkta kalın',
            'Omuz ağrısında daire boyutunu küçültün',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Sarkaç Hareketi (Pendulum)',
          description:
              'Omuz eklemini gevşetmek ve ağrıyı azaltmak için yerçekimi destekli pasif mobilizasyon hareketidir.',
          instructions: [
            'Sağlam bir masaya sağ elinizle yaslanın; gövde ~90° öne eğik',
            'Serbest kolunuz gevşekçe sallansın',
            'Kol öne-arkaya, sonra sağa-sola küçük daireler çizsin',
            '30-60 saniye her yön',
            'Kasla değil, gevşek sallanma ile yapın',
            'Başlangıçta küçük genlik kullanın',
            'Baş dönmesinde dik pozisyona geçin',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Kol Yan Açma (Side Raise - hafif)',
          description:
              'Orta deltoid kasını ağrısız aralıkta aktive etmek için hafif yük veya vücut ağırlığı ile yapılır.',
          instructions: [
            'Ayakta dik; hafif dumbbell veya el yansız',
            'Kolları yanlara omuz hizasına kadar yavaşça kaldırın',
            'Dirsekler hafif bükük',
            'Kontrollü şekilde indirin',
            '10-12 tekrar, 2 set',
            'Omuzları yukarı çekmeyin',
            'Ağrıda hareket açıklığını azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Göğüs Açma (Doorway Stretch)',
          description:
              'Göğüs kaslarını germek ve omuz ön hattındaki gerginliği azaltmak için kapı eşiği esnemesidir.',
          instructions: [
            'Kapı eşiğinde durun; ön kollar duvar kenarlarında',
            'Bir adım öne atarak göğsünüzü hafifçe öne verin',
            'Göğüs önünde gerilme hissedin',
            '20-30 saniye tutun',
            'Başlangıca dönün; 2-3 tekrar',
            'Boyun nötr kalsın',
            'Omuz ön ağrısında açıyı azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Omuz Flexion Kaydırma (Table Slide)',
          description:
              'Masada kol kaydırarak omuz fleksiyonunu ağrısız aralıkta artıran mobilizasyon hareketidir.',
          instructions: [
            'Sandalyede masaya karşı oturun; etkilenen el masada',
            'Parmaklarınızla masada yavaşça ileri kaydırın',
            'Gövde hafif öne eğilebilir; ağrısız sınıra kadar',
            'Aynı yolla geri kaydırın',
            '10-12 tekrar',
            'Omuzları kulaklara çekmeyin',
            'Ağrıda mesafeyi kısaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Towel Behind Back Stretch',
          description:
              'Havlu ile yapılan iç rotasyon esnemesi; omuz arkası ve rotator cuff esnekliğini destekler.',
          instructions: [
            'Bir elden havluyu baş üstünden, diğer elden bel arkasından tutun',
            'Üst el yukarı, alt el aşağı yavaşça çeksin',
            'Omuz arkasında hafif gerilme hissedin',
            '20-30 saniye tutun',
            'Elleri değiştirerek diğer tarafı yapın',
            'Zorlamayın',
            'Omuz ağrısında hareketi durdurun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Wall Angels - basic',
          description:
              'Duvara yaslanarak yapılan omuz ve kürek kemiği mobilizasyonu; postür düzeltmesine yardımcı olur.',
          instructions: [
            'Sırt, baş ve kalça duvara yaslı; bel boşluğu minimal',
            'Kollar duvara L pozisyonunda (dirsek 90°)',
            'Kolları yavaşça yukarı kaydırın; duvara temas korunsun',
            'Ağrısız yüksekliğe ulaşın ve geri indirin',
            '8-12 tekrar',
            'Beli duvardan ayırmayın',
            'Omuz ağrısında hareket aralığını kısaltın',
          ],
        ),
      ],
    ),
    PhysicalTherapyCategory(
      name: 'Diz',
      englishName: 'Knee',
      level: 'Ev Seviyesi',
      exerciseCount: 10,
      exercises: [
        PhysicalTherapyExercise(
          name: 'Quad Sıkma (Quad Set)',
          description:
              'Quadriceps kasını izometrik olarak aktive etmek için diz düz pozisyonda yapılan temel rehabilitasyon hareketidir.',
          instructions: [
            'Sırt üstü yatın; bacak düz, diz altına küçük havlu rulosu koyun',
            'Dizinizi düz tutarak quadriceps kasını sıkın',
            'Topuğunuzu yere doğru bastırın',
            '5-10 saniye tutun',
            'Gevşetin; 10-15 tekrar her bacak',
            'Kalça ve bel sabit kalsın',
            'Diz ağrısında süreyi kısaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Topuk Kaydırma (Heel Slide)',
          description:
              'Diz fleksiyonunu ağrısız aralıkta artırmak için yerde topuk kaydırma hareketidir.',
          instructions: [
            'Sırt üstü yatın; bacaklar uzatılmış',
            'Topuğu yavaşça kalçaya doğru kaydırarak dizinizi bükün',
            'Ağrısız maksimum bükülmeye ulaşın',
            'Kontrollü şekilde bacağı düzleştirin',
            '10-15 tekrar her bacak',
            'Hareket yavaş ve kontrollü olsun',
            'Keskin diz ağrısında açıklığı azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Düz Bacak Kaldırma (Straight Leg Raise)',
          description:
              'Quadriceps ve kalça fleksörlerini güçlendirirken diz eklemini koruyan klasik rehab hareketidir.',
          instructions: [
            'Sırt üstü yatın; etkilenen bacak düz, diğer diz bükük',
            'Düz bacağı yavaşça yere paralel veya biraz üstüne kaldırın',
            '2-3 saniye tutun',
            'Kontrollü indirin',
            '10-12 tekrar her bacak, 2 set',
            'Bel boşluğu oluşmamasına dikkat edin',
            'Bel veya diz ağrısında yüksekliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Köprü (Glute Bridge)',
          description:
              'Kalça ve hamstring kaslarını güçlendirerek diz ve bel stabilitesini destekleyen harekettir.',
          instructions: [
            'Sırt üstü yatın; dizler bükük, ayaklar kalça genişliğinde',
            'Kalçanızı sıkarak yukarı kaldırın; diz-omuz-boyun hizası oluşsun',
            'Üst noktada 2-3 saniye tutun',
            'Kontrollü şekilde indirin',
            '12-15 tekrar, 2-3 set',
            'Belden değil kalçadan kaldırın',
            'Diz ağrısında yüksekliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Mini Squat (Yarım Çömelme)',
          description:
              'Diz eklemini fonksiyonel yük altında güçlendirmek için kısa açıklıkta çömelme hareketidir.',
          instructions: [
            'Ayakta dik; ayaklar kalça genişliğinde',
            'Dizleri hafif bükerek 15-30 cm çömelin',
            'Dizler ayak parmaklarıyla hizalı kalsın',
            'Yukarı kalkın',
            '10-15 tekrar, 2 set',
            'Dizleri içe çöktürmeyin',
            'Diz ağrısında derinliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Duvar Squat (Wall Sit - kısa süre)',
          description:
              'Quadriceps dayanıklılığını artırmak için duvara yaslanarak yapılan izometrik oturma pozisyonudur.',
          instructions: [
            'Sırt duvara yaslı; ayaklar önde',
            'Yavaşça aşağı kayarak dizler ~45-60° bükülene kadar inin',
            'Pozisyonu 15-20 saniye tutun',
            'Yukarı kayarak kalkın',
            '3-5 tekrar; süreyi kademeli artırın',
            'Dizler ayak üzerinde kalsın',
            'Diz ağrısında süreyi veya açıyı azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Tek Ayak Denge',
          description:
              'Diz ve ayak bileği propriyospsiyonunu geliştiren basit denge egzersizidir.',
          instructions: [
            'Düz zeminde ayakta durun',
            'Bir ayağınızı yerden kaldırın',
            '10-20 saniye dengede kalın',
            'Diğer ayakla tekrarlayın',
            '3 set her bacak',
            'Gerekirse duvara hafifçe dokunun',
            'Denge kaybında hemen ayağı yere koyun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Hamstring Germe',
          description:
              'Arka bacak kaslarını germek ve diz arkası gerginliğini azaltmak için oturarak yapılan esnemedir.',
          instructions: [
            'Yerde oturun; bir bacak düz önde, diğeri bükük',
            'Düz bacakta gövdenizi hafifçe öne eğin',
            'Arka bacakta gerilme hissedin',
            '20-30 saniye tutun',
            'Diğer bacakla tekrarlayın',
            'Zorlamayın; sırtı yuvarlamayın',
            'Keskin ağrıda durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Baldır Germe',
          description:
              'Baldır kaslarını germek; diz ve ayak bileği hareketliliğini desteklemek için duvar esnemesidir.',
          instructions: [
            'Duvara ellerinizle yaslanın; bir ayak önde, arka bacak düz',
            'Arka topuğu yerde tutarak öne eğilin',
            'Arka bacak baldırında gerilme hissedin',
            '20-30 saniye tutun',
            'Bacak değiştirin',
            'Diz hafif bükük alternatif de yapılabilir',
            'Aşırı ağrıda durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Adım Öne Geri (Step Touch)',
          description:
              'Diz kontrolünü ve hafif fonksiyonel hareketi artırmak için basit adım egzersizidir.',
          instructions: [
            'Ayakta dik durun',
            'Bir adım öne atın; ön diz hafif bükülsün',
            'Aynı ayağı geri getirin',
            'Diğer ayakla tekrarlayın',
            '10-12 adım her bacak',
            'Denge için yavaş başlayın',
            'Diz ağrısında adım mesafesini kısaltın',
          ],
        ),
      ],
    ),
    PhysicalTherapyCategory(
      name: 'Bel / Alt Sırt',
      englishName: 'Lower Back',
      level: 'Ev Seviyesi',
      exerciseCount: 8,
      exercises: [
        PhysicalTherapyExercise(
          name: 'Cat-Cow',
          description:
              'Omurga mobilizasyonu için dört ayak pozisyonunda yapılan fleksiyon-ekstansiyon hareketidir.',
          instructions: [
            'Dört ayak pozisyonu; eller omuz altında, dizler kalça altında',
            'Nefes verirken sırtı yukarı yuvarlayın (kedi); çenenizi göğse yaklaştırın',
            'Nefes alırken sırtı çökertip başı hafif kaldırın (inek)',
            'Hareketi yavaş ve akıcı yapın',
            '10-15 tekrar',
            'Bel ağrısında genliği azaltın',
            'Keskin ağrıda durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: "Çocuk Pozu (Child's Pose)",
          description:
              'Bel ve kalça bölgesini gevşetmek için yapılan dinlenme ve esneme pozisyonudur.',
          instructions: [
            'Dizlerinizin üzerine oturun; kalça topuklara yakın',
            'Kolları öne uzatarak gövdenizi yere doğru indirin',
            'Alnınız yere veya ellerinize değebilir',
            '20-40 saniye nefes alarak bekleyin',
            'Yavaşça kalkın',
            'Diz ağrısında minder kullanın',
            'Bel ağrısında pozisyonu kısaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Diz Göğse Çekme',
          description:
              'Bel alt bölgesini gevşetmek ve kalça fleksörlerini hafifçe germek için yapılan yatar pozisyon hareketidir.',
          instructions: [
            'Sırt üstü yatın; bacaklar uzatılmış',
            'Bir dizinizi göğsünüze doğru çekin; ellerle destekleyin',
            'Bel yerde kalabilir; hafif gerilme hissedin',
            '20-30 saniye tutun',
            'Diğer bacakla tekrarlayın',
            'Her taraf 2-3 tekrar',
            'Keskin bel ağrısında durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Köprü (Glute Bridge)',
          description:
              'Kalça ve bel stabilizatörlerini güçlendirerek alt sırt desteği sağlayan harekettir.',
          instructions: [
            'Sırt üstü yatın; dizler bükük, ayaklar sabit',
            'Kalçayı sıkarak yukarı kaldırın',
            'Diz-omuz hizası oluşsun',
            '2-3 saniye tutun, kontrollü indirin',
            '12-15 tekrar, 2 set',
            'Belden değil kalçadan hareket edin',
            'Bel ağrısında yüksekliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Gövde Rotasyon (Supine Trunk Rotation)',
          description:
              'Bel rotasyon mobilizasyonu için dizler yana düşürülerek yapılan kontrollü harekettir.',
          instructions: [
            'Sırt üstü yatın; kollar yanlarda T pozisyonunda',
            'Dizleri bükün ve birlikte yavaşça sağa düşürün',
            'Omuzlar yerde kalsın; belde hafif rotasyon hissedin',
            '20-30 saniye tutun, orta hizaya dönün',
            'Sola tekrarlayın',
            'Her taraf 2-3 tekrar',
            'Bel ağrısında dönüş açısını azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Pelvik Tilt',
          description:
              'Bel boşluğunu nötralize etmek ve derin karın kaslarını aktive etmek için pelvis tilt hareketidir.',
          instructions: [
            'Sırt üstü yatın; dizler bükük, ayaklar yerde',
            'Bel boşluğunu yere doğru bastırın (pelvis arkaya)',
            '5 saniye tutun',
            'Gevşetin; bel hafifçe öne gelsin',
            '10-15 tekrar',
            'Hareket küçük ve kontrollü olsun',
            'Bel ağrısında genliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Piriformis Stretch (Figure-4)',
          description:
              'Kalça rotator kaslarını germek ve bel-kalça gerginliğini azaltmak için figür-4 esnemesidir.',
          instructions: [
            'Sırt üstü yatın',
            'Bir ayak bileğini diğer dizin üstüne koyun (4 şekli)',
            'Alt bacağı size doğru çekin',
            'Kalça arkasında gerilme hissedin',
            '20-30 saniye tutun',
            'Bacak değiştirin',
            'Zorlamayın',
            'Bel veya kalça ağrısında durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Kalça Fleksör Germe',
          description:
              'Kalça ön kaslarını germek; bel üzerindeki öne çekici etkiyi azaltmak için lunge esnemesidir.',
          instructions: [
            'Bir diz yerde, diğer ayak önde lunge pozisyonu',
            'Kalçayı öne vererek ön bacak kasında gerilme hissedin',
            'Gövde dik; core hafif sıkı',
            '20-30 saniye tutun',
            'Bacak değiştirin',
            'Diz altına minder kullanın',
            'Diz veya bel ağrısında açıyı azaltın',
          ],
        ),
      ],
    ),
    PhysicalTherapyCategory(
      name: 'Kalça',
      englishName: 'Hip',
      level: 'Ev Seviyesi',
      exerciseCount: 8,
      exercises: [
        PhysicalTherapyExercise(
          name: 'Clamshell (Ekipmansız)',
          description:
              'Kalça abdüktör ve rotator kaslarını güçlendirmek için yan yatar pozisyonda yapılan harekettir.',
          instructions: [
            'Yan yatın; dizler 45° bükük, ayaklar üst üste',
            'Üst dizi ayakları ayırmadan yukarı açın',
            'Kalça kasını sıkın; pelvis sabit kalsın',
            'Yavaşça kapatın',
            '12-15 tekrar her taraf, 2 set',
            'Belden yardım almayın',
            'Kalça ağrısında açıklığı azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Fire Hydrant (Dört Ayakta)',
          description:
              'Kalça abdüktör ve stabilizatör kasları güçlendiren dört ayak pozisyonu hareketidir.',
          instructions: [
            'Dört ayak pozisyonu; core sıkı, sırt nötr',
            'Bir dizi yana ve hafif arkaya doğru kaldırın',
            'Pelvis sabit; bel hareket etmesin',
            'Kontrollü indirin',
            '10-12 tekrar her bacak',
            'Hızlı sallanma yapmayın',
            'Bel veya kalça ağrısında yüksekliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Yan Bacak Kaldırma (Side Leg Raise)',
          description:
              'Kalça abdüktör kaslarını güçlendirmek için yan yatar pozisyonda bacak kaldırma hareketidir.',
          instructions: [
            'Alt taraf yan yatın; alt bacak hafif bükük destek için',
            'Üst bacağı düz veya hafif arkaya doğru kaldırın',
            '2 saniye tutun, kontrollü indirin',
            '10-12 tekrar her taraf',
            'Pelvis öne-arkaya sallanmasın',
            'Bel nötr kalsın',
            'Kalça ağrısında yüksekliği azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Mini Glute Bridge',
          description:
              'Köprü hareketinin kısa açıklıklı versiyonu; kalça aktivasyonu için güvenli başlangıç hareketidir.',
          instructions: [
            'Sırt üstü yatın; dizler bükük',
            'Kalçayı sadece birkaç cm yukarı kaldırın',
            '2-3 saniye sıkın',
            'Kontrollü indirin',
            '15-20 tekrar',
            'Belden değil kalçadan kaldırın',
            'Bel ağrısında hareketi durdurun',
          ],
        ),
        PhysicalTherapyExercise(
          name: '90-90 Kolay Rotasyon',
          description:
              'Kalça iç ve dış rotasyon mobilizasyonu için oturarak yapılan 90-90 pozisyon hareketidir.',
          instructions: [
            'Oturun; ön bacak 90° dışta, arka bacak 90° içte',
            'Gövde dik; eller önde destek',
            'Kalçayı hafifçe öne-arkaya veya yanlara kaydırarak rotasyon hissedin',
            'Ağrısız aralıkta 30-60 saniye tutun',
            'Bacakları değiştirin',
            'Zorlamayın',
            'Kalça ağrısında açıyı azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Adductor Stretch',
          description:
              'İç bacak kaslarını germek ve kalça hareketliliğini desteklemek için oturarak yapılan esnemedir.',
          instructions: [
            'Yerde oturun; ayak tabanları birleşik, dizler yana açık',
            'Dizleri yere doğru hafifçe bastırın veya gövdeyi öne eğin',
            'İç bacakta gerilme hissedin',
            '20-30 saniye tutun',
            '2-3 tekrar',
            'Sırtı yuvarlamayın',
            'Keskin ağrıda durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Hip Flexor Stretch (Lunge)',
          description:
              'Kalça fleksör kaslarını germek; kalça ön hattındaki gerginliği azaltmak için lunge esnemesidir.',
          instructions: [
            'Arka diz yerde veya havada; ön ayakta lunge',
            'Kalçayı öne verin; ön bacak kasında gerilme',
            'Gövde dik, core sıkı',
            '20-30 saniye her bacak',
            'Diz altına minder kullanın',
            'Diz ağrısında açıyı azaltın',
            'Bel ağrısında durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Standing Hip Abduction',
          description:
              'Ayakta kalça abdüktör kaslarını aktive etmek için bacağı yana kaldırma hareketidir.',
          instructions: [
            'Ayakta dik; duvara veya sandalyeye hafif destek',
            'Bir bacağı yana doğru yavaşça kaldırın',
            '2 saniye tutun, kontrollü indirin',
            '10-12 tekrar her bacak',
            'Gövde yana eğilmesin',
            'Dengeyi koruyun',
            'Kalça ağrısında yüksekliği azaltın',
          ],
        ),
      ],
    ),
    PhysicalTherapyCategory(
      name: 'Ayak Bileği',
      englishName: 'Ankle',
      level: 'Ev Seviyesi',
      exerciseCount: 6,
      exercises: [
        PhysicalTherapyExercise(
          name: 'Ayak Bileği Alfabe (Ankle ABC)',
          description:
              'Ayak bileği hareketliliğini artırmak için havada alfabe çizme mobilizasyon egzersizidir.',
          instructions: [
            'Oturun; bacağı uzatın veya havada tutun',
            'Ayak bileğinizle havada A''dan Z''ye harfler çizin',
            'Hareket yavaş ve tam genlikte olsun',
            'Tüm alfabe 1-2 tur',
            'Her bacak için tekrarlayın',
            'Ağrısız aralıkta kalın',
            'Bilek ağrısında harf boyutunu küçültün',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Parmak Ucu Kalkma (Heel Raise)',
          description:
              'Baldır kaslarını güçlendirmek ve ayak bileği stabilitesini artırmak için topuk kaldırma hareketidir.',
          instructions: [
            'Ayakta dik; duvara hafif destek alabilirsiniz',
            'Topukları yerden kaldırarak parmak uçlarında yükselin',
            'Üst noktada 2 saniye bekleyin',
            'Kontrollü şekilde indirin',
            '12-15 tekrar, 2-3 set',
            'Dizleri kilitlemeyin',
            'Bilek ağrısında tekrar sayısını azaltın',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Parmak Germe (Toe Stretch)',
          description:
              'Ayak parmakları ve ön ayak esnekliğini artırmak için yapılan germe hareketidir.',
          instructions: [
            'Oturun; bir ayağı diğer dizin üzerine koyun',
            'Parmakları geriye doğru hafifçe çekin',
            'Ayak üstünde gerilme hissedin',
            '15-20 saniye tutun',
            'Diğer ayağa geçin',
            'Zorlamayın',
            'Ağrıda durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Baldır Germe (Gastrocnemius)',
          description:
              'Baldır kaslarını germek; ayak bileği dorsifleksiyonunu desteklemek için duvar esnemesidir.',
          instructions: [
            'Duvara ellerinizle yaslanın',
            'Bir ayak önde, arka bacak düz ve topuk yerde',
            'Öne eğilerek arka baldırda gerilme hissedin',
            '20-30 saniye tutun',
            'Bacak değiştirin',
            'Diz hafif bükük versiyon da yapılabilir (soleus)',
            'Aşırı ağrıda durun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Tek Ayak Denge',
          description:
              'Ayak bileği propriyospsiyonunu ve denge reaksiyonunu geliştiren basit egzersizdir.',
          instructions: [
            'Düz zeminde ayakta durun',
            'Bir ayağı kaldırın; 15-30 saniye dengede kalın',
            'Gözler öne baksın',
            'Diğer ayakla tekrarlayın',
            '3 set her bacak',
            'Gerekirse duvara parmak ucuyla destek',
            'Denge kaybında ayağı hemen yere koyun',
          ],
        ),
        PhysicalTherapyExercise(
          name: 'Ayak Bileği Yukarı-Aşağı Hareketi',
          description:
              'Ayak bileği fleksiyon ve ekstansiyon hareketliliğini artırmak için oturarak yapılan ROM egzersizidir.',
          instructions: [
            'Sandalyede oturun; bacak rahat uzatılmış',
            'Ayak bileğini yukarı (ayak ucu size) çekin',
            'Sonra aşağı (ayak ucu dışarı) indirin',
            'Her yönde 2 saniye tutun',
            '10-15 tekrar her bacak',
            'Hareket yavaş ve kontrollü',
            'Bilek ağrısında açıklığı azaltın',
          ],
        ),
      ],
    ),
  ];

  static List<PhysicalTherapyCategory> getCategories() => categories;

  static PhysicalTherapyCategory? getCategoryForBodyPart(String bodyPart) {
    final normalized = _normalizeBodyPart(bodyPart);
    for (final category in categories) {
      if (_normalizeBodyPart(category.name) == normalized) {
        return category;
      }
    }
    return null;
  }

  static List<PhysicalTherapyExercise> getExercisesForBodyPart(String bodyPart) {
    return getCategoryForBodyPart(bodyPart)?.exercises ?? const [];
  }

  static String _normalizeBodyPart(String bodyPart) {
    final normalized = bodyPart.toLowerCase().trim();
    switch (normalized) {
      case 'bel':
      case 'bel / alt sirt':
      case 'alt sirt':
        return 'bel';
      case 'ayak bilegi':
      case 'ayak bileği':
        return 'ayak bilegi';
      case 'kalca':
      case 'kalça':
        return 'kalca';
      default:
        return normalized;
    }
  }
}
