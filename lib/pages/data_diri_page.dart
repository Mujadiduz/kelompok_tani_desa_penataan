import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';


class DataDiriPage extends StatefulWidget {
  final String nik;

  const DataDiriPage({
    super.key,
    required this.nik,
  });

  @override
  State<DataDiriPage> createState()=>_DataDiriPageState();
}


class _DataDiriPageState extends State<DataDiriPage>{

  static const Color primaryGreen=
      Color(0xff167A6B);

  static const Color darkGreen=
      Color(0xff0E5F57);

  static const Color softGreen=
      Color(0xffE6F4F1);

  static const Color bgColor=
      Color(0xffF2F7F5);

  static const Color textDark=
      Color(0xff18212B);

  static const Color textGrey=
      Color(0xff66727F);

  static const Color border=
      Color(0xffE0E8E5);



  final DatabaseReference _anggotaRef=
      FirebaseDatabase.instanceFor(
        app:Firebase.app(),
        databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref('anggota');



  String get cleanNik{
    return widget.nik.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }



  String _text(
    dynamic value,{
    String fallback='-',
  }){

    final result=
        (value??'').toString().trim();

    return result.isEmpty
        ?fallback
        :result;
  }



  String _initial(
    String name,
  ){

    final value=name.trim();

    if(value.isEmpty||value=='-'){
      return 'A';
    }

    return value[0].toUpperCase();
  }



  String _landSize(
    Map<String,dynamic> data,
  ){

    final value=_text(
      data['luas_lahan'] ??
      data['luas_sawah'],
      fallback:'',
    );

    if(value.isEmpty){
      return '-';
    }

    return '$value ha';
  }



  String _formatDate(
    dynamic value,
  ){

    final text=_text(
      value,
      fallback:'',
    );

    if(text.isEmpty){
      return '-';
    }

    final date=
        DateTime.tryParse(text);

    if(date==null){
      return text;
    }

    return '${date.day.toString().padLeft(2,'0')}/'
        '${date.month.toString().padLeft(2,'0')}/'
        '${date.year}';
  }



  Future<void> _refresh()async{
    setState((){});
  }



  @override
  Widget build(BuildContext context){

    final width=
        MediaQuery.sizeOf(context).width;

    final padding=
        width<350
            ?12.0
            :width<600
                ?16.0
                :24.0;


    return Scaffold(
      backgroundColor:bgColor,

      body:AppBackground(
        showPattern:false,

        child:SizedBox.expand(
          child:Stack(
            fit:StackFit.expand,
            children:[
              const _UserDashboardBackground(),

              SafeArea(
                child:FutureBuilder<DataSnapshot>(
            future:_anggotaRef
                .child(cleanNik)
                .get()
                .timeout(
                  const Duration(
                    seconds:10,
                  ),
                ),

            builder:(context,snapshot){

              if(snapshot.connectionState==
                  ConnectionState.waiting){

                return const Center(
                  child:CircularProgressIndicator(
                    color:primaryGreen,
                  ),
                );
              }


              if(
                snapshot.hasError ||
                snapshot.data?.value==null ||
                snapshot.data?.value is! Map
              ){

                return _emptyState();
              }


              final data=
                  Map<String,dynamic>.from(
                    snapshot.data!.value as Map,
                  );


              return RefreshIndicator(
                color:primaryGreen,

                onRefresh:_refresh,

                child:ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:EdgeInsets.fromLTRB(
                    padding,
                    14,
                    padding,
                    28,
                  ),

                  children:[
                    _header(),

                    const SizedBox(height:14),

                    _profileCard(data),

                    const SizedBox(height:14),

                    _infoCard(data),
                  ],
                ),
              );
            },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(){

    return Container(
      padding:const EdgeInsets.all(15),

      decoration:BoxDecoration(
        gradient:const LinearGradient(
          colors:[
            darkGreen,
            primaryGreen,
          ],

          begin:Alignment.topLeft,
          end:Alignment.bottomRight,
        ),

        borderRadius:BorderRadius.circular(22),

        boxShadow:[
          BoxShadow(
            color:darkGreen.withValues(alpha:0.18),
            blurRadius:16,
            offset:const Offset(0,6),
          ),
        ],
      ),

      child:Row(
        children:[

          InkWell(
            onTap:(){
              Navigator.pop(context);
            },

            borderRadius:BorderRadius.circular(13),

            child:Container(
              height:40,
              width:40,

              decoration:BoxDecoration(
                color:Colors.white.withValues(alpha:0.15),
                borderRadius:BorderRadius.circular(13),
              ),

              child:const Icon(
                Icons.arrow_back_ios_new_rounded,
                color:Colors.white,
                size:17,
              ),
            ),
          ),

          const SizedBox(width:11),

          const Expanded(
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,

              children:[

                Text(
                  'Data Diri',
                  style:TextStyle(
                    color:Colors.white,
                    fontSize:19,
                    fontWeight:FontWeight.w900,
                  ),
                ),

                SizedBox(height:2),

                Text(
                  'Informasi anggota kelompok tani',
                  style:TextStyle(
                    color:Color(0xffD1FAE5),
                    fontSize:11,
                    fontWeight:FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height:40,
            width:40,

            decoration:BoxDecoration(
              color:Colors.white.withValues(alpha:0.15),
              borderRadius:BorderRadius.circular(13),
            ),

            child:const Icon(
              Icons.badge_rounded,
              color:Colors.white,
              size:22,
            ),
          ),
        ],
      ),
    );
  }



  Widget _profileCard(
    Map<String,dynamic> data,
  ){

    final nama=_text(
      data['nama'],
    );


    return Container(
      padding:const EdgeInsets.all(18),

      decoration:BoxDecoration(
        gradient:const LinearGradient(
          colors:[
            Color(0xff0E5F57),
            Color(0xff167A6B),
          ],

          begin:Alignment.topLeft,
          end:Alignment.bottomRight,
        ),

        borderRadius:BorderRadius.circular(24),

        boxShadow:[
          BoxShadow(
            color:darkGreen.withValues(alpha:0.18),
            blurRadius:16,
            offset:const Offset(0,7),
          ),
        ],
      ),

      child:Row(
        children:[

          Container(
            height:72,
            width:72,

            decoration:BoxDecoration(
              shape:BoxShape.circle,

              color:Colors.white.withValues(alpha:0.15),

              border:Border.all(
                color:Colors.white.withValues(alpha:0.25),
              ),
            ),

            child:Center(
              child:Text(
                _initial(nama),

                style:const TextStyle(
                  color:Colors.white,
                  fontSize:30,
                  fontWeight:FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(width:14),

          Expanded(
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,

              children:[

                Row(
                  children:[

                    Container(
                      padding:const EdgeInsets.symmetric(
                        horizontal:10,
                        vertical:5,
                      ),

                      decoration:BoxDecoration(
                        color:Colors.white.withValues(alpha:0.15),
                        borderRadius:BorderRadius.circular(99),
                      ),

                      child:const Row(
                        children:[

                          Icon(
                            Icons.verified_rounded,
                            color:Color(0xffA7F3D0),
                            size:12,
                          ),

                          SizedBox(width:4),

                          Text(
                            'Anggota Aktif',
                            style:TextStyle(
                              color:Color(0xffD1FAE5),
                              fontSize:10,
                              fontWeight:FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height:8),

                Text(
                  nama,

                  maxLines:1,
                  overflow:TextOverflow.ellipsis,

                  style:const TextStyle(
                    color:Colors.white,
                    fontSize:19,
                    fontWeight:FontWeight.w900,
                  ),
                ),

                const SizedBox(height:6),

                const Row(
                  children:[

                    Icon(
                      Icons.agriculture_rounded,
                      color:Color(0xffA7F3D0),
                      size:15,
                    ),

                    SizedBox(width:5),

                    Text(
                      'Kelompok Tani TaniGo',
                      style:TextStyle(
                        color:Color(0xffA7F3D0),
                        fontSize:11,
                        fontWeight:FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    Widget _infoCard(
    Map<String,dynamic> data,
  ){

    return Container(
      padding:const EdgeInsets.all(15),

      decoration:_cardDecoration(),

      child:Column(
        children:[

          _item(
            Icons.phone_in_talk_rounded,
            'Telepon',
            _text(data['telepon']),
          ),

          _divider(),

          _item(
            Icons.wc_rounded,
            'Jenis Kelamin',
            _text(data['jenis_kelamin']),
          ),

          _divider(),

          _item(
            Icons.location_on_rounded,
            'Alamat',
            _text(data['alamat']),
          ),

          _divider(),

          _item(
            Icons.agriculture_rounded,
            'Luas Lahan',
            _landSize(data),
          ),

          _divider(),

          _item(
            Icons.calendar_month_rounded,
            'Terdaftar',
            _formatDate(
              data['tanggal_daftar'],
            ),
          ),

          _divider(),

          _item(
            Icons.verified_user_rounded,
            'Verifikasi',
            _formatDate(
              data['tanggal_verifikasi'],
            ),
          ),
        ],
      ),
    );
  }



  Widget _item(
    IconData icon,
    String title,
    String value,
  ){

    return Padding(
      padding:const EdgeInsets.symmetric(
        vertical:8,
      ),

      child:Row(
        children:[

          Container(
            height:40,
            width:40,

            decoration:BoxDecoration(
              color:softGreen,

              borderRadius:
                  BorderRadius.circular(13),
            ),

            child:Icon(
              icon,
              color:primaryGreen,
              size:21,
            ),
          ),

          const SizedBox(width:12),

          Expanded(
            child:Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children:[

                Text(
                  title,

                  style:const TextStyle(
                    color:textGrey,
                    fontSize:12,
                    fontWeight:FontWeight.w700,
                  ),
                ),

                const SizedBox(height:2),

                Text(
                  value,

                  maxLines:2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:const TextStyle(
                    color:textDark,
                    fontSize:13.5,
                    fontWeight:FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color:Color(0xffB0B8B3),
            size:22,
          ),
        ],
      ),
    );
  }



  Widget _divider(){

    return Divider(
      height:14,
      color:border.withValues(alpha:0.8),
    );
  }
    Widget _emptyState(){

    return Center(
      child:Padding(
        padding:const EdgeInsets.all(24),

        child:Container(
          width:double.infinity,

          padding:const EdgeInsets.all(24),

          decoration:_cardDecoration(),

          child:Column(
            mainAxisSize:MainAxisSize.min,

            children:[

              Container(
                height:70,
                width:70,

                decoration:const BoxDecoration(
                  color:softGreen,
                  shape:BoxShape.circle,
                ),

                child:const Icon(
                  Icons.person_off_rounded,
                  color:primaryGreen,
                  size:38,
                ),
              ),

              const SizedBox(height:14),

              const Text(
                'Data Tidak Ditemukan',

                style:TextStyle(
                  color:textDark,
                  fontSize:17,
                  fontWeight:FontWeight.w900,
                ),
              ),

              const SizedBox(height:7),

              const Text(
                'Data anggota tidak tersedia untuk akun ini.',

                textAlign:TextAlign.center,

                style:TextStyle(
                  color:textGrey,
                  fontSize:12.5,
                  height:1.4,
                  fontWeight:FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  BoxDecoration _cardDecoration(){

    return BoxDecoration(
      color:Colors.white,

      borderRadius:BorderRadius.circular(22),

      border:Border.all(
        color:border,
      ),

      boxShadow:[
        BoxShadow(
          color:darkGreen.withValues(alpha:0.035),
          blurRadius:14,
          offset:const Offset(0,6),
        ),
      ],
    );
  }
}

class _UserDashboardBackground
    extends StatelessWidget {
  const _UserDashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            final height =
                constraints.maxHeight;

            final baseSize =
                width < height ? width : height;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 460.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.68)
                    .clamp(190.0, 330.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.42)
                    .clamp(120.0, 205.0)
                    .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xff0E5F57),
                          Color(0xff177A6B),
                          Color(0xffDDEFEA),
                          Color(0xffF2F7F5),
                        ],
                        stops: [
                          0,
                          0.22,
                          0.49,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.54,
                    right: -largeCircle * 0.29,
                    child: _DashboardCircle(
                      size: largeCircle,
                      color: const Color(0xff53B69C),
                      alpha: 0.20,
                      borderColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.12,
                    left: -smallCircle * 0.24,
                    child: _DashboardRing(
                      size: smallCircle,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: height * 0.28,
                    left: -mediumCircle * 0.57,
                    child: _DashboardCircle(
                      size: mediumCircle,
                      color: const Color(0xffA9DCCF),
                      alpha: 0.38,
                      borderColor:
                          const Color(0xff167A6B),
                    ),
                  ),
                  Positioned(
                    top: height * 0.48,
                    right: -mediumCircle * 0.61,
                    child: _DashboardCircle(
                      size: mediumCircle * 1.08,
                      color: const Color(0xffE6F2F8),
                      alpha: 0.84,
                      borderColor:
                          const Color(0xff326FA3),
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.52,
                    left: -largeCircle * 0.30,
                    child: _DashboardCircle(
                      size: largeCircle,
                      color: const Color(0xffDDEFE5),
                      alpha: 0.82,
                      borderColor:
                          const Color(0xff2E7D32),
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.36,
                    right: -mediumCircle * 0.43,
                    child: _DashboardCircle(
                      size: mediumCircle,
                      color: const Color(0xffEAF3FA),
                      alpha: 0.88,
                      borderColor:
                          const Color(0xff326FA3),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  final Color borderColor;

  const _DashboardCircle({
    required this.size,
    required this.color,
    required this.alpha,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withValues(
            alpha: 0.08,
          ),
          width: 2,
        ),
      ),
    );
  }
}

class _DashboardRing extends StatelessWidget {
  final double size;
  final Color color;

  const _DashboardRing({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}
