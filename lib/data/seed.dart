import '../core/calendar.dart';
import 'database.dart';
import 'repository.dart';

/// Sample world from the design handoff, so the UI can be tried right away.
Future<void> seedSampleWorld(Repository repo, String worldId) async {
  Future<String> add(EntryType t, String title, String summary, EntryStatus s,
      {List<String> aliases = const [], List<String> tags = const [], Map<String, String> fields = const {}, String body = ''}) async {
    final e = await repo.createEntry(
        worldId: worldId, type: t, title: title, summary: summary, status: s,
        aliases: aliases, tags: tags, fields: fields, body: body);
    return e.id;
  }

  final lyra = await add(EntryType.character, 'ไลรา วาเลน', 'กัปตันเรือสินค้าผู้ตามหาความจริงเรื่องพ่อที่หายไปในพายุครั้งใหญ่', EntryStatus.canon,
      aliases: ['นกกระเรียนเงิน', 'กัปตันไลรา'], tags: ['ตัวเอก', 'นักเดินเรือ'],
      fields: {'อายุ': '27', 'อาชีพ': 'กัปตันเรือ', 'เป้าหมาย': 'ไขปริศนาพายุ'},
      body: 'เกิดและโตที่ [[ท่าเรือโคราล]] ในครอบครัวช่างซ่อมเรือ เข้าร่วม [[สมาคมเข็มทิศ]] ตั้งแต่อายุสิบหก และได้ฉายา “นกกระเรียนเงิน” จากการนำเรือฝ่าหมอกทะเลเหนือ\n\n'
          'พ่อของเธอ [[ออร์ริน วาเลน]] หายไประหว่าง [[พายุปีกำแพง]] สิ่งเดียวที่เหลือคือ [[เข็มทิศไร้เหนือ]] ซึ่งเธอเชื่อว่าชี้ไปยังที่ที่เขาอยู่\n\n'
          'คู่ปรับตลอดกาลคือ [[เซเรน ดาห์]] ทั้งคู่เคยร่วมเรือเดียวกันก่อนแตกหักกันที่ [[เกาะไร้ชื่อ]]');
  final orrin = await add(EntryType.character, 'ออร์ริน วาเลน', 'นักทำแผนที่ชื่อดัง หายตัวไปในพายุปีกำแพง', EntryStatus.draft,
      aliases: ['ผู้เฒ่าแห่งท่าเรือ'], tags: ['สูญหาย'],
      fields: {'อายุ': '58 (ตอนหายตัว)', 'อาชีพ': 'นักทำแผนที่', 'เป้าหมาย': 'ทำแผนที่ทะเลชั้นใน'},
      body: 'นักทำแผนที่ประจำ [[สมาคมเข็มทิศ]] ผู้เชื่อว่า [[น้ำขึ้นจันทร์คู่]] เปิดเส้นทางลับสู่ทะเลชั้นใน\n\n'
          'ออกเรือครั้งสุดท้ายในคืนก่อน [[พายุปีกำแพง]] โดยทิ้งลูกสาว [[ไลรา วาเลน]] ไว้ที่ [[ท่าเรือโคราล]]');
  final seren = await add(EntryType.character, 'เซเรน ดาห์', 'อดีตต้นหนผู้กลายเป็นหัวหน้ากองเรือโจรสลัด', EntryStatus.canon,
      aliases: ['ใบเรือดำ'], tags: ['คู่ปรับ', 'โจรสลัด'],
      fields: {'อายุ': '31', 'อาชีพ': 'หัวหน้ากองเรือ', 'เป้าหมาย': 'ครอบครองเข็มทิศ'},
      body: 'ลูกครึ่ง [[ชาวเกล็ดเงิน]] ที่เติบโตบนเรือ เคยเป็นต้นหนของ [[ไลรา วาเลน]] ก่อนทรยศเพื่อแย่งชิง [[เข็มทิศไร้เหนือ]]');
  final koral = await add(EntryType.place, 'ท่าเรือโคราล', 'เมืองท่าการค้าที่ใหญ่ที่สุดของหมู่เกาะ สร้างบนแนวปะการังตาย', EntryStatus.canon,
      aliases: ['เมืองปะการัง'], tags: ['เมืองท่า'],
      fields: {'ภูมิอากาศ': 'ร้อนชื้น', 'ประชากร': '~40,000', 'ปกครองโดย': 'สภาพ่อค้า'},
      body: 'ที่ตั้งสำนักงานใหญ่ของ [[สมาคมเข็มทิศ]] ทุกปีเมื่อ [[น้ำขึ้นจันทร์คู่]] ถนนชั้นล่างจะจมน้ำทั้งหมด');
  await add(EntryType.place, 'หอคอยน้ำเค็ม', 'หอคอยร้างกลางทะเล โผล่พ้นน้ำเฉพาะช่วงน้ำลงต่ำสุด', EntryStatus.idea,
      aliases: ['หอเงียบ'], tags: ['ปริศนา'],
      fields: {'ภูมิอากาศ': 'หมอกหนา', 'ประชากร': '—', 'ค้นพบ': 'ยังไม่ระบุ'},
      body: 'อาจเกี่ยวข้องกับ [[พายุปีกำแพง]] — ยังไม่ตัดสินใจ');
  final guild = await add(EntryType.org, 'สมาคมเข็มทิศ', 'กิลด์นักเดินเรือและนักทำแผนที่ ผูกขาดเส้นทางการค้าทั้งหมด', EntryStatus.canon,
      aliases: ['กิลด์นักเดินเรือ'], tags: ['กิลด์'],
      fields: {'ก่อตั้ง': 'ปีที่ 212', 'สมาชิก': '~1,200', 'ฐาน': 'ท่าเรือโคราล'},
      body: 'ตั้งอยู่ที่ [[ท่าเรือโคราล]] ห้ามสมาชิกเดินเรือในช่วง [[น้ำขึ้นจันทร์คู่]] อย่างเด็ดขาด');
  final storm = await add(EntryType.event, 'พายุปีกำแพง', 'พายุที่จมเรือกว่าสามสิบลำในคืนเดียว เมื่อสิบเอ็ดปีก่อน', EntryStatus.draft,
      aliases: ['คืนสิบสองคลื่น'], tags: ['ภัยพิบัติ'],
      fields: {'วันที่': 'ปีที่ 401, เดือนหมอก', 'ระยะเวลา': '1 คืน', 'ผู้เสียชีวิต': '~600'},
      body: 'เกิดขึ้นตรงกับ [[น้ำขึ้นจันทร์คู่]] ครั้งที่แรงที่สุดในรอบศตวรรษ ซากเรือหลายลำถูกพัดไปเกยที่ [[หอคอยน้ำเค็ม]]');
  final compass = await add(EntryType.item, 'เข็มทิศไร้เหนือ', 'เข็มทิศที่ชี้ไปยังสิ่งที่ผู้ถือปรารถนาที่สุด', EntryStatus.draft,
      tags: ['วัตถุวิเศษ'],
      fields: {'วัสดุ': 'ทองเหลือง, กระจกทะเล', 'เจ้าของ': 'ไลรา วาเลน', 'ที่มา': 'ไม่ทราบ'},
      body: 'ถูกพบในซากเรือหลัง [[พายุปีกำแพง]] [[เซเรน ดาห์]] ต้องการมันมาตลอด');
  await add(EntryType.rule, 'น้ำขึ้นจันทร์คู่', 'เมื่อจันทร์ทั้งสองดวงเต็มพร้อมกัน ระดับน้ำทะเลจะสูงขึ้นสิบเมตร', EntryStatus.canon,
      aliases: ['น้ำสองจันทร์'], tags: ['ธรรมชาติ'],
      fields: {'ความถี่': 'ทุก 7 ปี', 'ระยะเวลา': '3 วัน', 'ผลกระทบ': 'ทั้งหมู่เกาะ'},
      body: 'เป็นกฎตายตัวของโลก ใช้เป็นจุดอ้างอิงของปฏิทินหมู่เกาะ');
  final scale = await add(EntryType.species, 'ชาวเกล็ดเงิน', 'เผ่าพันธุ์ครึ่งมนุษย์ที่หายใจใต้น้ำได้ในช่วงจันทร์เต็ม', EntryStatus.idea,
      aliases: ['ชาวทะเลลึก'], tags: ['ชนเผ่า'],
      fields: {'อายุขัย': '~120 ปี', 'ถิ่นที่อยู่': 'แนวปะการังลึก', 'ภาษา': 'ภาษาคลื่น'},
      body: 'สัมพันธ์ใกล้ชิดกับ [[น้ำขึ้นจันทร์คู่]] เชื่อว่าเป็นช่วงที่ทะเลเปิดประตู');

  Future<void> rel(String a, String b, String t, String inv, [String note = '']) =>
      repo.addRelation(from: a, to: b, type: t, inverseType: inv, note: note);
  await rel(lyra, orrin, 'ลูกสาวของ', 'พ่อของ', 'ห่างกันตั้งแต่ไลราอายุ 16');
  await rel(lyra, seren, 'ศัตรู', 'ศัตรู', 'เคยเป็นลูกเรือคู่กัน');
  await rel(lyra, guild, 'สังกัด', 'สมาชิก', 'กัปตันระดับสาม');
  await rel(lyra, koral, 'อาศัยอยู่ที่', 'ผู้อยู่อาศัย', 'บ้านริมอู่เรือ');
  await rel(lyra, compass, 'ครอบครอง', 'เจ้าของ', 'ได้รับมาหลังพายุ');
  await rel(orrin, guild, 'สังกัด', 'สมาชิก', 'นักทำแผนที่อาวุโส');
  await rel(seren, scale, 'เชื้อสาย', 'ลูกหลาน', 'ฝั่งมารดา');
  await rel(guild, koral, 'ตั้งอยู่ที่', 'ที่ตั้งของ');
  await rel(orrin, storm, 'สูญหายใน', 'ผู้สูญหาย');

  // A custom calendar and a few dated events.
  await repo.setCalendar(
    worldId,
    const CalendarConfig(yearLabel: 'ปีที่', months: [
      'เดือนลม', 'เดือนฝน', 'เดือนหมอก', 'เดือนคลื่น', 'เดือนเกลือ', 'เดือนจันทร์',
      'เดือนปะการัง', 'เดือนพาย', 'เดือนน้ำลง', 'เดือนน้ำขึ้น', 'เดือนดาว', 'เดือนสงบ',
    ]),
  );
  await repo.setTimeline(guild, start: const WorldDate(212, 1, 1), participants: [koral]);
  await repo.setTimeline(lyra, start: const WorldDate(385, 6, 20));
  await repo.setTimeline(storm,
      start: const WorldDate(401, 3, 12), end: const WorldDate(401, 3, 13), participants: [orrin, lyra, koral]);
  await repo.setTimeline(compass, start: const WorldDate(401, 4, 2), participants: [lyra, seren]);
}
