import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'kelimeler.dart';

void main() => runApp(const MaterialApp(home: TabuGiris(), debugShowCheckedModeBanner: false));

class TabuKart {
  final String anaKelime;
  final List<String> yasakliKelimeler;
  TabuKart({required this.anaKelime, required this.yasakliKelimeler});
}

class OyunAyarlari {
  String takim1; String takim2;
  int sure; int pasHakki; int hedefPuan;
  OyunAyarlari({required this.takim1, required this.takim2, required this.sure, required this.pasHakki, required this.hedefPuan});
}

class TabuGiris extends StatefulWidget {
  const TabuGiris({super.key});
  @override
  State<TabuGiris> createState() => _TabuGirisState();
}

class _TabuGirisState extends State<TabuGiris> {
  final TextEditingController _t1Controller = TextEditingController(text: "TAKIM 1");
  final TextEditingController _t2Controller = TextEditingController(text: "TAKIM 2");
  int _secilenSure = 60;
  int _secilenPas = 3;
  int _secilenHedef = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text("TABU", style: TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900, letterSpacing: 10)),
                const SizedBox(height: 40),
                _input(_t1Controller, Colors.blueAccent),
                const SizedBox(height: 15),
                _input(_t2Controller, Colors.amber),
                const SizedBox(height: 30),
                _ayarlarRow(),
                const SizedBox(height: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: () {
                    final ayarlar = OyunAyarlari(takim1: _t1Controller.text, takim2: _t2Controller.text, sure: _secilenSure, pasHakki: _secilenPas, hedefPuan: _secilenHedef);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OyunEkrani(ayarlar: ayarlar)));
                  },
                  child: const Text("OYUNA BAŞLA", style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, Color col) {
    return Container(width: 300, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: TextField(controller: c, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white), decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.group, color: col))));
  }

  Widget _ayarlarRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _ayarBtn("SÜRE", "$_secilenSure", () => _secimDialog(45, 180, (v) => setState(() => _secilenSure = v))),
      const SizedBox(width: 10),
      _ayarBtn("PAS", "$_secilenPas", () => _secimDialog(1, 10, (v) => setState(() => _secilenPas = v))),
      const SizedBox(width: 10),
      _ayarBtn("HEDEF", "$_secilenHedef", () => _secimDialog(10, 100, (v) => setState(() => _secilenHedef = v))),
    ]);
  }

  Widget _ayarBtn(String t, String v, VoidCallback tap) {
    return InkWell(onTap: tap, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(t, style: const TextStyle(color: Colors.white54, fontSize: 10)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])));
  }

  void _secimDialog(int min, int max, Function(int) s) {
    showModalBottomSheet(context: context, builder: (c) => Container(height: 250, color: const Color(0xFF24243E), child: ListView(children: [45, 60, 90, 120, 1, 2, 3, 5, 10, 25, 50, 100].where((x) => x >= min && x <= max).map((e) => ListTile(title: Text("$e", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)), onTap: () { s(e); Navigator.pop(context); })).toList())));
  }
}

class OyunEkrani extends StatefulWidget {
  final OyunAyarlari ayarlar;
  const OyunEkrani({super.key, required this.ayarlar});
  @override
  State<OyunEkrani> createState() => _OyunEkraniState();
}

class _OyunEkraniState extends State<OyunEkrani> {
  late List<TabuKart> aktifKelimeler;
  late TabuKart mevcutKart;
  int skorT1 = 0; int skorT2 = 0;
  bool siraT1 = true;
  late int kalanSure; late int kalanPas;
  Timer? zamanlayici;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _listeHazirla();
    kalanSure = widget.ayarlar.sure;
    kalanPas = widget.ayarlar.pasHakki;
    sureyiBaslat();
  }

  void _listeHazirla() {
    aktifKelimeler = List.from(devKelimeListesi);
    aktifKelimeler.shuffle();
    mevcutKart = aktifKelimeler[0];
  }

  void sureyiBaslat() {
    zamanlayici = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (kalanSure > 0) {
        if (mounted) setState(() => kalanSure--);
        if (kalanSure <= 5 && kalanSure > 0) _player.play(AssetSource('tick.mp3'));
      } else {
        zamanlayici?.cancel();
        _player.play(AssetSource('finish.mp3'));
        _kelimeyiAtla(); // SÜRE BİTİNCE KELİME DEĞİŞİR
        _turBittiDialog();
      }
    });
  }

  void _kelimeyiAtla() {
    setState(() {
      if (aktifKelimeler.isNotEmpty) {
        aktifKelimeler.removeAt(0);
        if (aktifKelimeler.isEmpty) _listeHazirla();
        mevcutKart = aktifKelimeler[0];
      }
    });
  }

  void cevapla(int p, bool pas) {
    if (pas) {
      if (kalanPas > 0) { setState(() => kalanPas--); _kelimeyiAtla(); }
    } else {
      setState(() {
        if (siraT1) skorT1 += p; else skorT2 += p;
        _sampiyonKontrol();
      });
      _kelimeyiAtla();
    }
  }

  void _sampiyonKontrol() {
    if (skorT1 >= widget.ayarlar.hedefPuan || skorT2 >= widget.ayarlar.hedefPuan) {
      zamanlayici?.cancel();
      _kazananDialog(skorT1 >= widget.ayarlar.hedefPuan ? widget.ayarlar.takim1 : widget.ayarlar.takim2);
    }
  }

  void _turBittiDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF004D40),
      title: const Text("SÜRE BİTTİ", textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
      content: Text("Sıradaki: ${!siraT1 ? widget.ayarlar.takim1 : widget.ayarlar.takim2}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
      actions: [Center(child: ElevatedButton(onPressed: () {
        Navigator.pop(context);
        setState(() { siraT1 = !siraT1; kalanSure = widget.ayarlar.sure; kalanPas = widget.ayarlar.pasHakki; });
        sureyiBaslat();
      }, child: const Text("BAŞLAT")))],
    ));
  }

  void _kazananDialog(String k) {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(title: const Text("🏆 ŞAMPİYON"), content: Text("$k Kazandı!"), actions: [TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text("MENÜ"))]));
  }

  @override
  void dispose() { zamanlayici?.cancel(); _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 15),
          _skorPaneli(),
          const SizedBox(height: 20),
          _kartGovdesi(),
          _altButonlar(),
        ]),
      ),
    );
  }

  Widget _skorPaneli() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _skorBirim(widget.ayarlar.takim1, skorT1, siraT1, Colors.cyanAccent),
      Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: kalanSure / widget.ayarlar.sure, color: Colors.amber, backgroundColor: Colors.white10),
        Text("$kalanSure", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
      _skorBirim(widget.ayarlar.takim2, skorT2, !siraT1, Colors.amberAccent),
    ]));
  }

  Widget _skorBirim(String n, int s, bool a, Color c) {
    return Column(children: [Text(n.length > 8 ? n.substring(0, 8) : n, style: TextStyle(color: a ? c : Colors.white12, fontWeight: FontWeight.bold, fontSize: 12)), Text("$s", style: TextStyle(color: a ? c : Colors.white12, fontSize: 28, fontWeight: FontWeight.w900))]);
  }

  Widget _kartGovdesi() {
    return Expanded(child: Container(
      width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: const Color(0xFF00695C), borderRadius: BorderRadius.circular(30)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(mevcutKart.anaKelime.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.amber)),
        const SizedBox(height: 40),
        ...mevcutKart.yasakliKelimeler.map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(w.toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white)))),
      ]),
    ));
  }

  Widget _altButonlar() {
    return Padding(padding: const EdgeInsets.only(bottom: 25, top: 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _btn("TABU", Colors.orange, () => cevapla(-1, false)),
      _btn("PAS (${kalanPas})", const Color(0xFF455A64), () => cevapla(0, true)),
      _btn("DOĞRU", const Color(0xFF2ECC71), () => cevapla(1, false)),
    ]));
  }

  Widget _btn(String l, Color c, VoidCallback t) {
    return SizedBox(width: 105, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: t, child: Text(l, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))));
  }
}