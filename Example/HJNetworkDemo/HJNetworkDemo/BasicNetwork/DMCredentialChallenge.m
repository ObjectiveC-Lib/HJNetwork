//
//  DMCredentialChallenge.m
//  HJNetworkDemo
//
//  Created by navy on 2022/6/8.
//

#import "DMCredentialChallenge.h"
#import <CommonCrypto/CommonDigest.h>
#import <AssertMacros.h>
#import <arpa/inet.h>


@implementation DMCredentialChallenge

static NSSet *_globalRootCAs = nil;
static NSSet *_globalRootCANames = nil;

static void HJCredentialChallengeInitGlobal() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* file:///System/Library/Security/Certificates.bundle/Contents/Resources/TrustStore.html */
        _globalRootCAs = [NSSet setWithObjects:
                          @"D7A7A0FB5D7E2731D771E9484EBCDEF71D5F0C3E0A2948782BC83EE0EA699EF4",
                          @"55926084EC963A64B96E2ABE01CE0BA86A64FBFEBCC7AAB5AFC155B37FD76066",
                          @"8C7209279AC04E275E16D07FD3B775E80154B5968046E31F52DD25766324E9A7",
                          @"687FA451382278FFF0C8B11F8D43D576671C6EB2BCEAB413FB83D965D06D2FF2",
                          @"A31F093053BD12C1F5C3C6EFD498023FD2914D7758D05D698CE084B50626E0E5",
                          @"0376AB1D54C5F9803CE4B2E201A0EE7EEF7B57B636E8A93C9B8D4860C96F5FA7",
                          @"0A81EC5A929777F145904AF38D5D509F66B5E2C58FCDB531058B0E17F3F0B41B",
                          @"BD71FDF6DA97E4CF62D1647ADD2581B07D79ADF8397EB4ECBA9C5E8488821423",
                          @"70A73F7F376B60074248904534B11482D5BF0E698ECC498DF52577EBF2E93B9A",
                          @"E3268F6106BA8B665A1A962DDEA1459D2A46972F1F2440329B390B895749AD45",
                          @"C2B9B042DD57830E7D117DAC55AC8AE19407D38E41D88F3215BC3A890444A050",
                          @"63343ABFB89A6A03EBB57E9B3F5FA7BE7C4F5C756F3017B3A8C488C3653E9179",
                          @"B0B1730ECBC7FF4505142C49F1295E6EDA6BCAED7E2C68C5BE91B5A11001F024",
                          @"0D83B611B648A1A75EB8558400795375CAD92E264ED8E9D7A757C1F5EE2BB22D",
                          @"2D47437DE17951215A12F3C58E51C729A58026EF1FCC0A5FB3D9DC012F600D19",
                          @"126BF01C1094D2F0CA2E352380B3C724294546CCC65597BEF7F12D8A171F1984",
                          @"F356BEA244B7A91EB35D53CA9AD7864ACE018E2D35D5F8F96DDF68A6F41AA474",
                          @"04048028BF1F2864D48F9AD4D83294366A828856553F3B14303F90147F5D40EF",
                          @"0ED3FFAB6C149C8B4E71058E8668D429ABFDA681C2FFF508207641F0D751A3E5",
                          @"16AF57A9F676B0AB126095AA5EBADEF22AB31119D644AC95CD4B93DBF3F26AEB",
                          @"9F9744463BE13714754E1A3BECF98C08CC205E4AB32028F4E2830C4A1B2775B8",
                          @"9A114025197C5BB95D94E63D55CD43790847B646B23CDF11ADA4A00EFF15FB48",
                          @"EDF7EBBCA27A2A384D387B7D4010C666E2EDB4843E4C29B4AE1D5B9332E6B24D",
                          @"F96F23F4C3E79C077A46988D5AF5900676A0F039CB645DD17549B216C82440CE",
                          @"E23D4A036D7B70E9F595B1422079D2B91EDFBB1FB651A0633EAA8A9DC5F80703",
                          @"E3B6A2DB2ED7CE48842F7AC53241C7B71D54144BFB40C11F3F1D0B42F5EEA12D",
                          @"FCBFE2886206F72B27593C8B070297E12D769ED10ED7930705A8098EFFC14D17",
                          @"2A99F5BC1174B73CBB1D620884E01C34E51CCB3978DA125F0E33268883BF4158",
                          @"EAA962C4FA4A6BAFEBE415196D351CCD888D4F53F3FA8AE6D7C466A94E6042BB",
                          @"D8E0FEBC1DB2E38D00940F37D27D41344D993E734B99D5656D9778D4D8143624",
                          @"B676F2EDDAE8775CD36CB0F63CD1D4603961F49E6265BA013A2F0307B6D0B804",
                          @"5C58468D55F58E497E743982D2B50010B6D165374ACF83A7D4A32DB768C4408E",
                          @"5CC3D78E4E1D5E45547A04E6873E64F90CF9536D1CCC2EF800F355C4C5FD70FD",
                          @"063E4AFAC491DFD332F3089B8542E94617D893D7FE944E10A7937EE29D9693C0",
                          @"0C258A12A5674AEF25F28BA7DCFAECEEA348E541E6F5CC4EE63B71B361606AC3",
                          @"8327BC8C9D69947B3DE3C27511537267F59C21B9FA7B613FAFBCCD53B7024000",
                          @"0F993C8AEF97BAAF5687140ED59AD1821BB4AFACF0AA9A58B5D57A338A3AFBCB",
                          @"04ACFB3B24793F300F67EF87E44DD72CB9B28B204F389A7CD5AE28785C7D42CD",
                          @"0C2CD63DF7806FA399EDE809116B575BF87989F06518F9808C860503178BAF66",
                          @"1793927A0614549789ADCE2F8F34F7F0B66D0F3AE3A3B84D21EC15DBBA4FADC7",
                          @"52F0E1C4E58EC629291B60317F074671B85D7EA80D5B07273463534B32B40234",
                          @"AE4457B40D9EDA96677B0D3C92D57B5177ABD7AC1037958356D1E094518BE5F2",
                          @"2605875AFCC176B2D66DD66A995D7F8D5EBB86CE120D0E7E9E7C6EF294A27D4C",
                          @"507941C74460A0B47086220D4E9932572AB5D1B5BBCB8980AB1CB17651A844D2",
                          @"49E7A442ACF0EA6287050054B52564B650E4F49E42E348D6AA38E039E957B1C1",
                          @"EEC5496B988CE98625B934092EEC2908BED0B0F316C2D4730C84EAF1F3D34881",
                          @"B6191A50D0C3977F7DA99BCDAAC86A227DAEB9679EC70BA3B0C9D92271C170D3",
                          @"3E9099B5015E8F486C00BCEA9D111EE721FABA355A89BCF1DF69561E3DC6325C",
                          @"7D05EBB682339F8C9451EE094EEBFEFA7953A114EDB2F44949452FAB7D2FC185",
                          @"7E37CB8B4C47090CAB36551BA6F45DB840680FBA166A952DB100717F43053FC2",
                          @"4348A0E9444C78CB265E058D5E8944B4D84F9662BD26DB257F8934A443C70161",
                          @"CB3CCBB76031E5E0138F8DD39A23F9DE47FFC35E43C1144CEA27D46A5AB1CB5F",
                          @"31AD6648F8104138C738F39EA4320133393E3A18CC02296EF97C2AC9EF6731D0",
                          @"7431E5F4C3C1CE4690774F0B61E05440883BA9A01ED00BA6ABD7806ED3B118CF",
                          @"552F7BDCF1A7AF9E6CE672017F4F12ABF77240C78E761AC203D1D9D20AC89988",
                          @"767C955A76412C89AF688E90A1C70F556CFD6B6025DBEA10416D7EB6831F8C40",
                          @"0687260331A72403D909F105E69BCF0D32E1BD2493FFC6D9206D11BCD6770739",
                          @"9A73929A500F1A0BF49DCB046E8039169696557345E9F813F10FF9380DB22695",
                          @"B0BFD52BB0D7D9BD92BF5D4DC13DA255C02C542F378365EA893911F55E55F23C",
                          @"6639D13CAB85DF1AD9A23C443B3A60901E2B138D456FA71183578108884EC6BF",
                          @"3E84BA4342908516E77573C0992F0979CA084E4685681FF195CCBA8A229B8A76",
                          @"02ED0EB28C14DA45165C566791700D6451D7FB56F0B2AB1D3B8EB070E56EDFF5",
                          @"43DF5774B03E7FEF5FE40D931A7BEDF1BB2E6B42738C4E6D3841103D3AA7F339",
                          @"73C176434F1BC6D5ADF45B0E76E727287C8DE57616C1E6E6141A2B2CBC7D8E4C",
                          @"D1C339EA2784EB870F934FC5634E4AA9AD5505016401F26465D37A574663359F",
                          @"6DC47172E01CBCB0BF62580D895FE2B8AC9AD4F873801E0C10B9C837D21EB177",
                          @"C0A6F4DC63A24BFDCF54EF2A6A082A0A72DE35803E2FF5FF527AE5D87206DFD5",
                          @"894EBC0B23DA2A50C0186B7F8F25EF1F6B2935AF32A94584EF80AAF877A3A06E",
                          @"FF856A2D251DCD88D36656F450126798CFABAADE40799C722DE4D2B5DB36A73A",
                          @"5EDB7AC43B82A06A8761E8D7BE4979EBF2611F7DD79BF91C1C6B566A219ED766",
                          @"B478B812250DF878635C2AA7EC7D155EAA625EE82916E2CD294361886CD1FBD4",
                          @"37D51006C512EAAB626421F1EC8C92013FC5F82AE98EE533EB4619B8DEB4D06C",
                          @"136335439334A7698016A0D324DE72284E079D7B5220BB8FBD747816EEBEBACA",
                          @"EF3CB417FC8EBF6F97876C9E4ECE39DE1EA5FE649141D1028B7D11C0B2298CED",
                          @"EBD41040E4BB3EC742C9E381D31EF2A41A48B6685C96E7CEF3C1DF6CD4331C99",
                          @"BEC94911C2955676DB6C0A550986D76E3BA005667C442C9762B4FBB773DE228C",
                          @"179FBC148A3DD00FD24EA13458CC43BFA7F59C8182D783A513F6EBEC100C8924",
                          @"CA42DD41745FD0B81EB902362CF9D8BF719DA1BD1B1EFC946F5B4C99F42C1B9E",
                          @"CBB522D7B7F127AD6A0113865BDF1CD4102E7D0759AF635A7CF4720DC963C53B",
                          @"C3846BF24B9E93CA64274C0EC67C1ECC5E024FFCACD2D74019350E81FE546AE4",
                          @"45140B3247EB9CC8C5B4F0D7B53091F73292089E6E5A63E2749DD3ACA9198EDA",
                          @"70B922BFDA0E3F4A342E4EE22D579AE598D071CC5EC9C30F123680340388AEA5",
                          @"BC104F15A48BE709DCA542A7E1D4B9DF6F054527E802EAA92D595444258AFE71",
                          @"F9E67D336C51002AC054C632022D66DDA2E7E3FFF10AD061ED31D8BBB410CFB2",
                          @"C0C05A8D8DA55EAF27AA9B910B0A6EF0D8BBDED346928DB872E182C2073E9802",
                          @"5D56499BE4D2E08BCFCAD08A3E38723D50503BDE706948E42F55603019E528AE",
                          @"30D0895A9A448A262091635522D1F52010B5867ACAE12C78EF958FD4F4389F2F",
                          @"96BCEC06264976F37460779ACF28C5A7CFE8A3C0AAE11A8FFCEE05C0BDDF08C6",
                          @"B0877AEE2D39274DF831F66FDEEB7717557C258FC9EB55231A9F8A647A75433F",
                          @"23804203CA45D8CDE716B8C13BF3B448457FA06CC10250997FA01458317C41E5",
                          @"2530CC8E98321502BAD96F9B1FBA1B099E2D299E0F4548BB914F363BC0D4531F",
                          @"6FDB3F76C8B801A75338D8A50A7C02879F6198B57E594D318D3832900FEDCD79",
                          @"3C5F81FEA5FAB82C64BFA2EAECAFCDE8E077FC8620A7CAE537163DF36EDBF378",
                          @"6C61DAC3A2DEF031506BE036D2A6FE401994FBD13DF9C8D466599274C446EC98",
                          @"15F0BA00A3AC7AF3AC884C072B1011A077BD77C097F40164B2F8598ABD83860C",
                          @"41C923866AB4CAD6B7AD578081582E020797A6CBDF4FFF78CE8396B38937D7F5",
                          @"6B9C08E86EB0F767CFAD65CD98B62149E5494A67F5845E7BD1ED019F27B86BD6",
                          @"8A866FD1B276B57E578E921C65828A2BED58E9F2F288054134B7F1F4BFC9CC74",
                          @"8FE4FB0AF93A4D0D67DB0BEBB23E37C71BF325DCBCDD240EA04DAF58B47E1840",
                          @"85A0DD7DD720ADB7FF05F83D542B209DC7FF4528F7D677B18389FEA5E5C49E86",
                          @"88EF81DE202EB018452E43F864725CEA5FBD1FC2D9D205730709C5D8B8690F46",
                          @"18F1FC7F205DF8ADDDEB7FE007DD57E3AF375A9C4D8D73546BF4F1FED1E18D35",
                          @"A45EDE3BBBF09C8AE15C72EFC07268D693A21C996FD51E67CA079460FD6D8873",
                          @"AF8B6762A1E528228161A95D5C559EE266278F75D79E830189A503506ABD6B4C",
                          @"4200F5043AC8590EBB527D209ED1503029FBCBD41CA1B506EC27F15ADE7DAC69",
                          @"F1C1B50AE5A20DD8030EC9F6BC24823DD367B5255759B4E71B61FCE9F7375D73",
                          @"A22DBA681E97376E2D397D728AAE3A9B6296B9FDBA60BC2E11F647F2C675FB37",
                          @"E75E72ED9F560EEC6EB4800073A43FC3AD19195A392282017895974A99026B6C",
                          @"513B2CECB810D4CDE5DD85391ADFC6C2DD60D87BB736D2B521484AA47A0EBEF6",
                          @"CD808284CF746FF2FD6EB58AA1D59C4AD4B3CA56FDC6274A8926A7835F32313D",
                          @"7908B40314C138100B518D0735807FFBFCF8518A0095337105BA386B153DD927",
                          @"4D2491414CFE956746EC4CEFA6CF6F72E28A1329432F9D8A907AC4CB5DADC15A",
                          @"668C83947DA63B724BECE1743C31A0E6AED0DB8EC5B31BE377BB784F91B6716F",
                          @"3C4FB0B95AB8B30032F432B86F535FE172C185D0FD39865837CF36187FA6F428",
                          @"1465FA205397B876FAA6F0A9958E5590E40FCC7FAA4FB7C2C8677521FB5FB658",
                          @"2CE1CB0BF9D2F9E102993FBE215152C3B2DD0CABDE1C68E5319B839154DBB7F5",
                          @"568D6905A2C88708A4B3025190EDCFEDB1974A606A13C6E5290FCB2AE63EDAB5",
                          @"C7BA6567DE93A798AE1FAA791E712D378FAE1F93C4397FEA441BB7CBE6FD5995",
                          @"C766A9BEF2D4071C863A31AA4920E813B2D198608CB7B7CFE21143B836DF09EA",
                          @"E17890EE09A3FBF4F48B9C414A17D637B7A50647E9BC752322727FCC1742A911",
                          @"21DB20123660BB2ED418205DA11EE7A85A65E2BC6E55B5AF7E7899C8A266D92E",
                          @"F09B122C7114F4A09BD4EA4F4A99D558B46E4C25CD81140D29C05613914C3841",
                          @"D95FEA3CA4EEDCE74CD76E75FC6D1FF62C441F0FA8BC77F034B19E5DB258015D",
                          @"62DD0BE9B9F50A163EA0F8E75C053B1ECA57EA55C8688F647C6881F2C8357B95",
                          @"7AF6EA9F753A1E709BD64D0BEB867C11E8C295A56E24A6E0471459DCCDAA1558",
                          @"3B222E566711E992300DC0B15AB9473DAFDEF8C84D0CEF7D3317B4C1821D1436",
                          @"59B3829F1FF443344958FAE8BFF621B684C848CFBF7EAD6B63A6CA50F2794F89",
                          @"BE6C4DA2BBB9BA59B6F3939768374246C3C005993FA98F020D1DEDBED48A81D5",
                          @"1E49AC5DC69E86D0565DA2C1305C419330B0B781BFEC50E54A1B35AF7FDDD501",
                          @"363F3C849EAB03B0A2A0F636D7B86D04D3AC7FCFE26A0A9121AB9795F6E176DF",
                          @"9D190B2E314566685BE8A889E27AA8C7D7AE1D8AADDBA3C1ECF9D24863CD34B9",
                          @"FE863D0822FE7A2353FA484D5924E875656D3DC9FB58771F6F616F9D571BC592",
                          @"CB627D18B58AD56DDE331A30456BC65C601A4E9B18DEDCEA08E7DAAA07815FF0",
                          @"53DFDFA4E297FCFE07594E8C62D5B8AB06B32C7549F38A163094FD6429D5DA43",
                          @"B32396746453442F353E616292BB20BBAA5D23B546450FDB9C54B8386167D529",
                          @"FABCF5197CDD7F458AC33832D3284021DB2425FD6BEA7A2E69B7486E8F51F9CC",
                          @"91E2F5788D5810EBA7BA58737DE1548A8ECACD014598BC0B143E041B17052552",
                          @"FD73DAD31C644FF1B43BEF0CCDDA96710B9CD9875ECA7E31707AF3E96D522BBD",
                          @"DD6936FE21F8F077C123A1A521C12224F72255B73E03A7260693E8A24B0FA389",
                          @"A4310D50AF18A6447190372A86AFAF8B951FFB431D837F1E5688B45971ED1557",
                          @"4B03F45807AD70F21BFC2CAE71C9FDE4604C064CF5FFB686BAE5DBAAD7FDD34C",
                          @"8D722F81A9C113C0791DF136A2966DB26C950A971DB46B4199F4EA54B78BFB9F",
                          @"92D8092EE77BC9208F0897DC05271894E63EF27933AE537FB983EEF0EAE3EEC8",
                          @"C1B48299ABA5208FE9630ACE55CA68A03EDA5A519C8802A0D3A673BE8F8E557D",
                          @"59769007F7685D0FCD50872F9F95D5755A5B2B457D81F3692B610A98672F0E1B",
                          @"BFD88FE1101C41AE3E801BF8BE56350EE9BAD1A6B9BD515EDC5C6D5B8711AC44",
                          @"E4C73430D7A5B50925DF43370A0D216E9A79B9D6DB8373A0C69EB1CC31C7C52A",
                          @"978CD966F2FAA07BA7AA9500D9C02E9D77F2CDADA6AD6BA74AF4B91C66593C50",
                          @"A1F05CCB80C2D710EC7D479ABDCBB879E58D7EDB7149FE78A87884E3D0BAD0F9",
                          @"93E65EC762F055DC718A332582C41A04430D72E3CB87E8B897B67516F0D1AA39",
                          @"4FF460D54B9C86DABFBCFC5712E0400D2BED3FBC4D4FBDAA86E06ADCD2A9AD7A",
                          @"E793C9B02FD8AA13E21C31228ACCB08119643B749C898964B1746D46C3D4CBD2",
                          @"85FB2F91DD12275A0145B636534F84024AD68B69B8EE88684FF711375805B348",
                          @"43F257412D440D627476974F877DA8F1FC2444565A367AE60EDDC27A412531AE",
                          @"6EA54741D004667EED1B4816634AA3A79E6E4B96950F8279DAFC8D9BD8812137",
                          @"C38DCB38959393358691EA4D4F3CE495CE748996E64ED1891D897A0FC4DD55C6",
                          @"6FFF78E400A70C11011CD85977C459FB5AF96A3DF0540820D0F4B8607875E58F",
                          @"CBB5AF185E942A2402F9EACBC0ED5BB876EEA3C1223623D00447E4F3BA554B65",
                          @"92A9D9833FE1944DB366E8BFAE7A95B6480C2D6C6C2A1BE65D4236B608FCA1BB",
                          @"EB04CF5EB1F39AFA762F2BB120F296CBA520C1B97DB1589565B81CB9A17B7244",
                          @"69DDD7EA90BB57C93E135DC85EA6FCD5480B603239BDC454FC758B2A26CF7F79",
                          @"9ACFAB7E43C8D880D06B262A94DEEEE4B4659989C3D0CAF19BAF6405E41AB7DF",
                          @"2399561127A57125DE8CEFEA610DDF2FA078B5C8067F4E828290BFB860E84B3C",
                          @"69FAC9BD55FB0AC78D53BBEE5CF1D597989FD0AAAB20A25151BDF1733EE7D122",
                          @"C57A3ACBE8C06BA1988A83485BF326F2448775379849DE01CA43571AF357E74B",
                          @"F008733EC500DC498763CC9264C6FCEA40EC22000E927D053CE9C90BFA046CB2",
                          @"A71272AEAAA3CFE8727F7FB39F0FB3D1E5426E9060B06EE6F13E9A3C5833CD43",
                          @"CECDDC905099D8DADFC5B1D209B737CBE2C18CFB2C10C0FF0BCF0D3286FC1AA2",
                          nil];
        
        _globalRootCANames = [NSSet setWithObjects:
                              @"AAA Certificate Services",
                              @"Actalis Authentication Root CA",
                              @"AddTrust Class 1 CA Root",
                              @"AddTrust External CA Root",
                              @"Admin-Root-CA",
                              @"AffirmTrust Commercial",
                              @"AffirmTrust Networking",
                              @"AffirmTrust Premium ECC",
                              @"AffirmTrust Premium",
                              @"ANF Global Root CA",
                              @"Apple Root CA - G2",
                              @"Apple Root CA - G3",
                              @"Apple Root CA",
                              @"Apple Root Certificate Authority",
                              @"ApplicationCA",
                              @"ApplicationCA2 Root",
                              @"Atos TrustedRoot 2011",
                              @"Autoridad de Certificacion Firmaprofesional CIF A62634068",
                              @"Autoridad de Certificacion Raiz del Estado Venezolano",
                              @"Baltimore CyberTrust Root",
                              @"Belgium Root CA2",
                              @"Buypass Class 2 Root CA",
                              @"Buypass Class 3 Root CA",
                              @"CA Disig Root R1",
                              @"CA Disig Root R2",
                              @"Certigna",
                              @"Certinomis - Autorité Racine",
                              @"Certinomis - Root CA",
                              @"certSIGN ROOT CA",
                              @"Certum CA",
                              @"Certum Trusted Network CA 2",
                              @"Certum Trusted Network CA",
                              @"CFCA EV ROOT",
                              @"Chambers of Commerce Root - 2008",
                              @"Chambers of Commerce Root",
                              @"Cisco Root CA 2048",
                              @"Class 2 Primary CA",
                              @"Common Policy",
                              @"COMODO Certification Authority",
                              @"COMODO ECC Certification Authority",
                              @"COMODO RSA Certification Authority",
                              @"ComSign CA",
                              @"ComSign Global Root CA",
                              @"ComSign Secured CA",
                              @"D-TRUST Root Class 3 CA 2 2009",
                              @"D-TRUST Root Class 3 CA 2 EV 2009",
                              @"Deutsche Telekom Root CA 2",
                              @"DigiCert Assured ID Root CA",
                              @"DigiCert Assured ID Root G2",
                              @"DigiCert Assured ID Root G3",
                              @"DigiCert Global Root CA",
                              @"DigiCert Global Root G2",
                              @"DigiCert Global Root G3",
                              @"DigiCert High Assurance EV Root CA",
                              @"DigiCert Trusted Root G4",
                              @"DST ACES CA X6",
                              @"DST Root CA X3",
                              @"DST Root CA X4",
                              @"E-Tugra Certification Authority",
                              @"Echoworx Root CA2",
                              @"EE Certification Centre Root CA",
                              @"Entrust Root Certification Authority - EC1",
                              @"Entrust Root Certification Authority - G2",
                              @"Entrust Root Certification Authority",
                              @"Entrust.net Certification Authority (2048)",
                              @"Entrust.net Certification Authority (2048)",
                              @"ePKI Root Certification Authority",
                              @"Federal Common Policy CA",
                              @"GeoTrust Global CA",
                              @"GeoTrust Primary Certification Authority - G2",
                              @"GeoTrust Primary Certification Authority - G3",
                              @"GeoTrust Primary Certification Authority",
                              @"Global Chambersign Root - 2008",
                              @"Global Chambersign Root",
                              @"GlobalSign Root CA",
                              @"GlobalSign",
                              @"GlobalSign",
                              @"GlobalSign",
                              @"GlobalSign",
                              @"Go Daddy Class 2 Certification Authority",
                              @"Go Daddy Root Certificate Authority - G2",
                              @"Government Root Certification Authority",
                              @"Hellenic Academic and Research Institutions RootCA 2011",
                              @"Hongkong Post Root CA 1",
                              @"I.CA - Qualified Certification Authority, 09/2009",
                              @"IdenTrust Commercial Root CA 1",
                              @"IdenTrust Public Sector Root CA 1",
                              @"ISRG Root X1",
                              @"Izenpe.com",
                              @"Izenpe.com",
                              @"Izenpe.com",
                              @"KISA RootCA 1",
                              @"Microsec e-Szigno Root CA 2009",
                              @"NetLock Arany (Class Gold) Főtanúsítvány",
                              @"Network Solutions Certificate Authority",
                              @"OISTE WISeKey Global Root GA CA",
                              @"OISTE WISeKey Global Root GB CA",
                              @"QuoVadis Root CA 1 G3",
                              @"QuoVadis Root CA 2 G3",
                              @"QuoVadis Root CA 2",
                              @"QuoVadis Root CA 3 G3",
                              @"QuoVadis Root CA 3",
                              @"QuoVadis Root Certification Authority",
                              @"RSA Security 2048 V3",
                              @"Secure Global CA",
                              @"SecureTrust CA",
                              @"Security Communication EV RootCA1",
                              @"Security Communication RootCA1",
                              @"Security Communication RootCA2",
                              @"Sonera Class1 CA",
                              @"Sonera Class2 CA",
                              @"Staat der Nederlanden EV Root CA",
                              @"Staat der Nederlanden Root CA - G2",
                              @"Staat der Nederlanden Root CA - G3",
                              @"Starfield Class 2 Certification Authority",
                              @"Starfield Root Certificate Authority - G2",
                              @"Starfield Services Root Certificate Authority - G2",
                              @"StartCom Certification Authority G2",
                              @"StartCom Certification Authority",
                              @"StartCom Certification Authority",
                              @"Swisscom Root CA 1",
                              @"Swisscom Root CA 2",
                              @"Swisscom Root EV CA 2",
                              @"SwissSign Gold CA - G2",
                              @"SwissSign Gold Root CA - G3",
                              @"SwissSign Platinum CA - G2",
                              @"SwissSign Platinum Root CA - G3",
                              @"SwissSign Silver CA - G2",
                              @"SwissSign Silver Root CA - G3",
                              @"Symantec Class 1 Public Primary Certification Authority - G4",
                              @"Symantec Class 1 Public Primary Certification Authority - G6",
                              @"Symantec Class 2 Public Primary Certification Authority - G4",
                              @"Symantec Class 2 Public Primary Certification Authority - G6",
                              @"Symantec Class 3 Public Primary Certification Authority - G4",
                              @"Symantec Class 3 Public Primary Certification Authority - G6",
                              @"SZAFIR ROOT CA",
                              @"T-TeleSec GlobalRoot Class 2",
                              @"T-TeleSec GlobalRoot Class 3",
                              @"TeliaSonera Root CA v1",
                              @"thawte Primary Root CA - G2",
                              @"thawte Primary Root CA - G3",
                              @"thawte Primary Root CA",
                              @"TRUST2408 OCES Primary CA",
                              @"Trustis FPS Root CA",
                              @"TWCA Global Root CA",
                              @"TWCA Root Certification Authority",
                              @"TÜBİTAK UEKAE Kök Sertifika Hizmet Sağlayıcısı - Sürüm 3",
                              @"TÜRKTRUST Elektronik Sertifika Hizmet Sağlayıcısı",
                              @"UCA Global Root",
                              @"UCA Root",
                              @"USERTrust ECC Certification Authority",
                              @"USERTrust RSA Certification Authority",
                              @"UTN - DATACorp SGC",
                              @"UTN-USERFirst-Client Authentication and Email",
                              @"UTN-USERFirst-Hardware",
                              @"UTN-USERFirst-Network Applications",
                              @"UTN-USERFirst-Object",
                              @"VeriSign Class 1 Public Primary Certification Authority - G3",
                              @"VeriSign Class 2 Public Primary Certification Authority - G3",
                              @"VeriSign Class 3 Public Primary Certification Authority - G3",
                              @"VeriSign Class 3 Public Primary Certification Authority - G4",
                              @"VeriSign Class 3 Public Primary Certification Authority - G5",
                              @"VeriSign Universal Root Certification Authority",
                              @"Visa eCommerce Root",
                              @"Visa Information Delivery Root CA",
                              @"VRK Gov. Root CA",
                              @"WellsSecure Public Root Certificate Authority",
                              @"XRamp Global Certification Authority",
                              nil];
    });
}

static BOOL HJIsIPAddress(NSString *str) {
    if (!str) return NO;
    
    int success;
    struct in_addr dst;
    struct in6_addr dst6;
    const char *utf8 = [str UTF8String];
    
    success = inet_pton(AF_INET, utf8, &(dst.s_addr)); // check IPv4 address
    if (!success) {
        success = inet_pton(AF_INET6, utf8, &dst6); // check IPv6 address
    }
    
    return success;
}

static BOOL HJServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);
#pragma clang diagnostic pop
    
    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
    
_out:
    return isValid;
}

static SecTrustRef HJChangedHostForTrust(SecTrustRef serverTrust, NSString *host, int *caTrust) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    CFMutableArrayRef certificates = CFArrayCreateMutable(kCFAllocatorDefault, certificateCount, &kCFTypeArrayCallBacks);
    
    BOOL caKnown = false;
    
    for (CFIndex i = certificateCount - 1; i >= 0; i--) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        CFArrayInsertValueAtIndex(certificates, 0, certificate);
        if (!caKnown) {
            SecCertificateRef someCertificates[] = {certificate};
            CFArrayRef tmpCertificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);
            
            SecTrustRef trust;
            __Require_noErr_Quiet(SecTrustCreateWithCertificates(tmpCertificates, policy, &trust), _out);
            
            if (!HJServerTrustIsValid(trust)) {
                NSData *certificateData = (__bridge_transfer NSData *)SecCertificateCopyData(certificate);
                uint8_t digest[CC_SHA256_DIGEST_LENGTH];
                CC_SHA256(certificateData.bytes, (CC_LONG)certificateData.length, digest);
                NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
                for(int k = 0; k < CC_SHA256_DIGEST_LENGTH; k++) {
                    [output appendFormat:@"%02X", digest[k]];
                }
                
                NSString *summary = (NSString*)CFBridgingRelease(SecCertificateCopySubjectSummary(certificate));
                if (![_globalRootCAs containsObject:output] &&
                    ![_globalRootCANames containsObject:summary]) {
                    goto _out;
                }
            }
            
            caKnown = true;
            
        _out:
            if (trust) {
                CFRelease(trust);
            }
            
            if (tmpCertificates) {
                CFRelease(tmpCertificates);
            }
            continue;
        }
    }
    
    if (policy) {
        CFRelease(policy);
    }
    
    *caTrust = caKnown?1:0;
    
    if (!caKnown) {
        CFRelease(certificates);
        return NULL;
    }
    
    if (host == nil || [host length] == 0 || HJIsIPAddress(host)) {
        CFRelease(certificates);
        return serverTrust;
    }
    
    CFMutableArrayRef newTrustPolicies = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    SecPolicyRef sslPolicy = SecPolicyCreateSSL(true, (__bridge CFStringRef) host);
    CFArrayAppendValue(newTrustPolicies, sslPolicy);
    
    SecTrustRef newTrust = NULL;
    if (SecTrustCreateWithCertificates(certificates, newTrustPolicies, &newTrust) != errSecSuccess) {
        CFRelease(certificates);
        CFRelease(newTrustPolicies);
        CFRelease(sslPolicy);
        return NULL;
    }
    
    CFRelease(certificates);
    CFRelease(newTrustPolicies);
    CFRelease(sslPolicy);
    
    return newTrust;
}

+ (BOOL)isIPAddress:(NSString *)address {
    return HJIsIPAddress(address);
}

+ (void)challenge:(NSURLAuthenticationChallenge *)challenge host:(NSString *)host
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    HJCredentialChallengeInitGlobal();
    
    NSURLCredential *credential = nil;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        int caTrust = 0;
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        if (!HJServerTrustIsValid(serverTrust)) {
            SecTrustRef newTrust = HJChangedHostForTrust(serverTrust, host, &caTrust);
            if (caTrust == 0 && !HJServerTrustIsValid(newTrust)) {
                if (completionHandler) {
                    completionHandler(disposition, credential);
                }
                return;
            }
            serverTrust = newTrust;
        }
        
        credential = [NSURLCredential credentialForTrust:serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

+ (NSURLCredential *)challenge:(NSURLAuthenticationChallenge *)challenge host:(NSString *)host {
    HJCredentialChallengeInitGlobal();
    
    NSURLCredential *credential = nil;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        int caTrust = 0;
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        if (!HJServerTrustIsValid(serverTrust)) {
            SecTrustRef newTrust = HJChangedHostForTrust(serverTrust, host, &caTrust);
            if (caTrust == 0 && !HJServerTrustIsValid(newTrust)) {
                return credential;
            }
            serverTrust = newTrust;
        }
        
        credential = [NSURLCredential credentialForTrust:serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    }
    
    return credential;
}

@end
