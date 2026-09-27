# ============================================================
#  《残夏 -The Last Tide-》 主剧本
#  语法： ::标签 / 角色id|台词 / |旁白 / @指令 / @choice ... @endchoice
#  指令表见 scripts/core/zs_compiler.gd
# ============================================================

:: start
@chapter 序章　梅雨
@cal 6/17 小潮（満潮18:42） 傍晚
@amb rain 2.0
@bgm none
@fx blackout_end 1.2
@bg bg_seawall_rain 1.4
|　　汐浦町的六月，一直在下雨。
|　　不是那种痛快的雨。是那种下到你觉得，它大概会一直这样下下去的雨。
@wait 1.0
|　　我在防波堤上看见一个女生。
|　　她蹲在最外侧的消波块上，校服湿了半边，脚边放着一个空的便当盒。
|　　这条防波堤上的每一个人我都认识。我不认识她。
@cg cg_umbrella_rain 1.6
@wait 2.0
@cg_hide 1.2

@char shiori_normal c 0.9
yuto|……你在这儿干什么？
shiori|（抬头，很快地把便当盒塞进书包）看海。
yuto|下雨。
shiori|嗯。
@wait 0.8
|　　雨声。四秒。
yuto|（把伞递过去）拿着。
shiori|我不冷。
yuto|我知道。你拿着。
@wait 0.6
|　　她接过去，握得很紧，指节发白。
|　　伞面朝她那边倾了大概三十度。
shiori|……谢谢。
yuto|你叫什么？
shiori|（停顿了一下）三浦。三浦栞。
|　　我的表情变了一下。很小的变化。
|　　她看到了。
shiori|你知道我家的事吗？
yuto|不知道。
shiori|哦。
|　　她把伞往回递了一半。两个人都没动。
@wait 1.0
@fx vignette 0.3
@hide all 0.6
@bg none 0.8

@bg bg_okada_kitchen 1.2
@amb room 1.5
@cal 6/17 小潮 夜
|　　回家的时候，奶奶坐在餐桌旁等我。
@char fumi c 0.8
fumi|悠人。
yuto|嗯。
fumi|你今天怎么淋湿了。
yuto|伞借给别人了。
fumi|（想了很久）那你回来的时候，是跑着的？
yuto|……是啊。
fumi|傻孩子。
@wait 0.8
|　　她说完这句话，又看了我一会儿。
|　　然后她问：你是谁家的孩子。
yuto|（把碗放下）冈田家的。我叫悠人。
fumi|哦。悠人啊。好名字。
yuto|嗯。
@hide all 0.6
@fx vignette 0.25
|　　我把碗洗了两遍。
|　　第一遍洗完了，忘了。又洗了一遍。

@bg bg_konbini_night 1.2
@amb room 1.0
@cal 6/21 中潮 夜
|　　第二天夜里，我在便利店后门看见了昨天那个人。
|　　她蹲在地上，把货架掉下来的饭团一个个捡起来。
@char shiori_normal c 0.8
yuto|不用买。那是店里的损耗。
shiori|没关系。
|　　她把压坏的那两个放进了自己的购物篮。
shiori|（很自然地说）反正我也要吃晚饭。
yuto|……
shiori|（看了我一眼）你是这里的店员？
yuto|不是。我奶奶住在后面那条街。
shiori|哦。
@wait 0.6
|　　收银台的旧风扇在转。转得很响。
|　　她数了数手里的零钱，然后又放回去两个。
@char shiori_smile c 0.8
shiori|（忽然）你们这条街的电线杆上，有十一个蝉蜕。
yuto|……什么？
shiori|我数过。第二根和第五根最多。
yuto|你数这个干什么。
shiori|（想了想）不知道。数着玩。
@hide all 0.8

@bg none 0.8
@fx blackout 1.0
@wait 1.0
|　　那天晚上，我在便利店的收银小票背面，写下了一行字。
@wait 1.4
|　　（小票背面很小。只能写一行。）
@care day1
@letter prologue
@goto ch1


# ============================================================
:: ch1
@chapter 第一章　蝉时雨
@cal 7/6 中潮（満潮19:20） 午后
@fx blackout_end 1.2
@amb cicada 2.0
@bgm daily 1.5
@bg bg_classroom 1.2
|　　七月。蝉开始叫了。
|　　叫得毫无节制，从早上五点叫到晚上七点，像是要把整个岛上的空气都撕开。
@wait 0.6
|　　我们学校三个年级，一共八十八个人。
|　　明年春天，这所学校要并到市里去。
|　　所以我们班分到了一个任务：编一本纪念册。
@char hitomi l 0.7
hitomi|冈田，你负责照片。我负责写。三浦负责排版。
yuto|为什么是我。
hitomi|因为你家有相机。而且你没意见。
@char shiori_normal r 0.8
shiori|我都可以。
hitomi|（看看这个，看看那个）……你们两个，是不是认识。
yuto|不认识。
shiori|不认识。
hitomi|（很长的沉默）好吧。
@hide all 0.8

@bg bg_music_room 1.4
@amb cicada 1.5
@cal 7/6 中潮 昼
|　　放学后，我去旧小学拍照片。
|　　汐浦东小在四年前废校了，门没锁。
|　　我在音乐教室里听见了钢琴声。
@wait 0.8
|　　只有一个音。反复按。每个音都是走音的。
@cg cg_piano 1.0
@hide all 0.4
@bgm shiori 2.0
shiori|这里漏雨。
yuto|嗯。屋顶早就没了。
shiori|可惜。
@wait 0.8
|　　她按下第一个音。走音得很厉害。她笑了一下。
yuto|你会弹？
shiori|我哥会。我在旁边看。
@wait 0.6
|　　她弹了一小段。四小节。
|　　第三小节有个地方，她跳过去了。
shiori|（停下来）忘了。
yuto|后面的呢？
shiori|忘了。
yuto|哦。
@wait 0.8
@cg_hide 1.0
@char shiori_normal c 0.9
@bg bg_music_room 0.0
shiori|（站起来，把琴盖合上）冈田同学。
yuto|嗯？
shiori|这首歌，你别学。
yuto|为什么？
shiori|不好听。
@wait 1.2
|　　琴盖合上的声音，盖过了蝉鸣。
@hide all 0.8

@bg bg_shopping_street 1.2
@amb cicada 1.5
@cal 7/9 中潮 午后
@bgm daily 1.5
|　　三天后，她出现在我家门口。
|　　手里拎着一袋商店街的临期食品。
@char shiori_normal c 0.8
@char fumi l 0.8 1.0
shiori|（对着奶奶）奶奶好。我是三浦。这个是店里要过期的，扔了可惜。
fumi|哦呀。哦呀哦呀。
yuto|……你怎么知道我家在哪。
shiori|纪念册上有地址。
yuto|那是学校的登记表。
shiori|（完全没有心虚）嗯。
@wait 0.6
|　　她进了厨房，看了一眼灶台边的药盒。
|　　然后她做了一件让我说不出话的事。
@wait 0.8
|　　她把奶奶的药，按日期分装成了小盒子。
|　　早上的、晚上的、睡前。分得很快，手很熟。
@char shiori_sad c 0.8
yuto|……你怎么会这个。
shiori|（手上的动作没停）家里有人吃过。
yuto|谁。
shiori|（把最后一个盒子盖上）分好了。早上两种，晚上三种。粉的是睡前。
@wait 0.6
yuto|我在问你话。
shiori|（抬头，很平静地）冈田同学。你奶奶的药，昨天和前天混在一起了。
yuto|……
shiori|这样不行。
@wait 1.0
yuto|……我知道。
shiori|嗯。
@hide all 0.8

@bg bg_okada_kitchen 1.0
@amb room 1.5
@bgm none
@cal 7/9 中潮 傍晚
|　　傍晚五点，町内放送开始放《夕焼け小焼け》。
|　　全町的孩子都要回家。
@wait 1.0
@char fumi c 0.9
fumi|悠人。
yuto|（在洗碗）嗯。
fumi|悠人。
yuto|我在。
fumi|你什么时候长这么高了。
@wait 1.0
|　　我的手停了。水还在流。
|　　我关掉水龙头，转过身。
yuto|……奶奶。
fumi|你妈走的那天，你才到这儿。（比了一下腰的位置）我那时候还想，这孩子可怎么办。
yuto|……
fumi|别管我了。
yuto|奶奶。
fumi|奶奶活够了。你去过你自己的。
@wait 1.2
|　　我张了张嘴。最后我说——
yuto|碗还没洗完。
|　　我转回去，打开水龙头。水声很大。
@wait 1.6
@fx vignette 0.4
@hide all 0.8
|　　那天晚上，奶奶吃了两碗饭。
@wait 0.8
@bg bg_okada_kitchen 0.0
@cal 7/10 中潮 朝
|　　第二天早上，同一张餐桌。
@char fumi c 0.9
fumi|你谁家的孩子？
yuto|（把粥放下）冈田家的。我叫悠人。
fumi|哦。悠人啊。好名字。
yuto|嗯。谢谢。
@hide all 0.6

@bg bg_seawall_dusk 1.4
@amb sea 2.0
@bgm shiori 2.0
@cal 7/14 大潮 黄昏
|　　傍晚，我和她坐在防波堤上。
|　　潮位比昨天高。今天的海很安静。
@char shiori_normal c 0.85
shiori|冈田同学。
yuto|嗯。
shiori|如果明年这里要拆，你会来看最后一眼吗。
yuto|……拆什么。
shiori|学校。还有这一片。町里说明年要修防波堤。
yuto|（想了想）会吧。
shiori|嗯。
@wait 0.8
yuto|你呢。
shiori|（看着海）我不太喜欢做长期打算。
@wait 1.0
|　　她说这句话的时候，语气很平。
|　　平得像在说今天的天气。
@wait 0.6
shiori|（忽然）你那天为什么把伞给我。
yuto|因为你淋湿了。
shiori|就这个？
yuto|就这个。
@wait 0.8
@char shiori_smile c 0.85
shiori|……冈田同学，你这个人有点奇怪。
yuto|哪里。
shiori|你做事没有理由。
yuto|（想了想）要什么理由。
shiori|（很久）嗯。是呢。
@hide all 1.0

@bg bg_shopping_street 1.2
@amb cicada 1.5
@bgm daily 1.5
@cal 7/18 中潮 午后
|　　七月剩下的日子过得很快。
|　　纪念册、补习、打工、奶奶的复诊。
|　　还有她。她总是忽然出现，又忽然消失。
@wait 0.6
|　　有一天佐野瞳问我，你是不是喜欢三浦。
@char hitomi c 0.9
hitomi|你别装。你最近洗碗都哼歌。
yuto|我没有。
hitomi|你有。你哼的那首，还是走音的。
yuto|……
hitomi|（趴在桌上）唉。
yuto|怎么了。
hitomi|没什么。就是觉得，这个夏天好像会很长。
@wait 0.8
|　　她说这句话的时候，是笑着的。
|　　后来我才知道，她那一年，没有报名。
@hide all 0.8

@bg bg_konbini_night 0.0
@amb room 1.0
@bgm none
@cal 7/21 大潮 深夜
|　　七月二十一号，凌晨两点。
|　　她在便利店仓库里晕倒了。
@wait 1.0
@char shiori_sad c 0.85
shiori|（坐在地上，扶着货架）……没事。
yuto|你脸很白。
shiori|站起来太快了。
yuto|骗人。
shiori|（笑了一下）真的。
@wait 0.8
|　　她说完，自己站了起来，把散的货一个个摆回架上。
|　　摆得很整齐。
@char shiori_normal c 0.85
shiori|店长说明天开始，夜班不用我上了。
yuto|为什么。
shiori|他说女孩子半夜不安全。
yuto|（我知道不是这个原因）
@wait 0.8
yuto|栞。
shiori|（抬头。这是我第一次叫她的名字）
yuto|……
shiori|（很轻地）嗯。
yuto|……没什么。你早点回去。
shiori|好。
@hide all 1.0

@timeslot ch1
@care day2
@letter ch1
@goto ch2


# ============================================================
:: ch2
@chapter 第二章　潮祭
@cal 8/3 中潮（満潮20:05） 午后
@fx blackout_end 1.2
@amb cicada 2.0
@bgm daily 1.5
@bg bg_shopping_street 1.2
|　　八月。町里的人开始多起来。
|　　只有这两天，会有年轻人回来。
|　　潮祭是汐浦町一年里唯一还在办的事。
@wait 0.8
@char shiori_casual c 0.85
shiori|冈田同学。你明天有空吗。
yuto|有。
shiori|（很快地）你怎么答得这么快。
yuto|……碰巧。
shiori|（笑）嗯。碰巧。
@wait 0.8
|　　那天她穿了一件很旧的白色连衣裙。
|　　袖口洗得起了毛。她说那是她哥的毕业典礼时，她妈妈给她买的。
@wait 0.6
shiori|只有这一件。
yuto|挺好的。
shiori|（低头看了看）……嗯。
@hide all 0.8

@bg bg_shrine_stairs 1.4
@amb cicada 1.5
@bgm festival 2.0
@cal 8/14 大潮 夜
|　　八月十四号，潮祭。
|　　神社的石阶有八十七级。我今天才知道，因为我数了两遍。
@wait 0.8
@char shiori_casual c 0.85
@char hitomi l 0.7 0.8
hitomi|（在摊位那边大喊）冈——田——！你俩买不买棉花糖！
yuto|不买。
shiori|（很小声）……买一个吧。
yuto|（我也买了一个）
@wait 0.6
|　　捞金鱼的大叔说今年捞不上来。
|　　面具摊的老太太说，明年可能就不摆了。
|　　每个人都在说「明年」。
@hide all 0.6

@bg bg_seawall_dusk 1.2
@amb sea 2.0
@bgm none
@cal 8/14 大潮 夜
|　　八点四十，防波堤上放烟火。
|　　町里的预算是四万日元。只有四十发。
@cg cg_festival_fireworks 1.6
@wait 2.4
@cg_hide 1.2
@wait 0.4
|　　四十发。很快就没了。
@wait 1.2
@fx flash 0.6
@char shiori_smile c 0.9
shiori|（仰着头）……好漂亮。
yuto|四十发而已。
shiori|（没有回头）四十发也很好。
@wait 1.0
|　　我想说的话到了嘴边。
|　　我看了她一眼——她在看烟火，肩膀在很轻地起伏。
|　　呼吸有点快。
@wait 0.8
|　　我把话咽回去了。
@wait 1.0
@char shiori_normal c 0.9
shiori|（忽然）今天很好。
yuto|嗯。
shiori|今天很好就够了。
@wait 1.2
|　　她说这句话的时候，烟火刚好放完。
|　　天黑下来，比刚才更黑。
@hide all 1.0

@bg bg_seawall_rain 1.2
@amb rain 1.5
@bgm none
@cal 8/15 大潮 深夜
|　　祭典的第二天下雨了。
|　　凌晨两点，我在便利店后巷看见她蹲在地上。
@char shiori_sad c 0.85
yuto|栞？
shiori|（抬头。脸色比上次更白）……你怎么在这儿。
yuto|我奶奶说想吃关东煮。
shiori|（笑了一下）……半夜两点。
yuto|她就是会这样。
@wait 0.8
|　　她扶着墙站起来。扶了两次。
@wait 0.6
yuto|这是第几次了。
shiori|什么第几次。
yuto|晕倒。
shiori|（很久）第二次。
@wait 1.0
|　　她撒谎的时候，会先想很久。
|　　后来我才知道，那是第三次。
@hide all 0.8

@bg bg_okada_kitchen 1.0
@amb room 1.5
@bgm sad 2.0
@cal 8/16 大潮 夜
|　　八月十六号晚上，奶奶在饭桌上说了那句我记了很久的话。
@char fumi c 0.9
fumi|悠人。今天有个姑娘来给我分了药。
yuto|嗯。
fumi|她说她姓三浦。
yuto|嗯。
fumi|（很慢地）三浦家的孩子啊。
@wait 0.8
yuto|奶奶，你知道三浦家的事吗。
fumi|（看着窗外）三十年前，那个厂的账，是我让你爷爷去签的字。
yuto|……什么。
fumi|（回头看我，眼睛很清亮）你爷爷那时候是渔协的理事。
yuto|……
fumi|（又转回窗外）记不得喽。
@wait 1.2
@fx vignette 0.35
|　　那天晚上她没有再说话。
|　　第二天早上，她问我：你谁家的孩子。
@hide all 0.8

@timeslot ch2
@care day3
@letter ch2
@goto ch3


# ============================================================
:: ch3
@set stage_mid true
@chapter 第三章　台风一号
@cal 8/24 小潮 午后
@fx blackout_end 1.2
@amb wind 2.0
@bgm tension 1.5
@bg bg_shopping_street 1.2
|　　八月二十四号，台风一号。
|　　町内放送从早上开始一直在响，念的是避难所名单。
|　　名单里有一半是老人。
@wait 0.8
|　　学校停课。商店街的卷帘门全部拉下来。
|　　我在找她。
@wait 0.6
|　　她不在便利店，不在学校，不在家。
|　　我知道她在哪。
@hide all 0.6

@bg bg_factory_interior 1.6
@amb rain 2.0
@bgm none
@cal 8/24 小潮 夕
|　　第三工场。
|　　三十年前的水产加工厂，她父亲是最后一任厂长。
|　　铁门锁着，西边有一扇被撬开的窗。
@wait 1.0
@fx shake 8
|　　风雨从破掉的屋顶灌进来。铁皮在响。
|　　她坐在一条生锈的传送带上，抱着膝盖。
@char shiori_weak c 0.9
yuto|三浦栞。
shiori|（抬头，愣了两秒）……你怎么来了。
yuto|猜的。
shiori|（很轻地）……你这个人，真的很奇怪。
@wait 1.0
|　　我坐到她旁边。铁皮一直在响，所以我们说话都得大点声。
@wait 0.6
shiori|我爸当年，就是站在这里，跟工人说工厂要关的。
yuto|你记得？
shiori|我妈讲的。她说那天下了很大的雨。
@wait 0.8
shiori|（看着屋顶）我不想在别的地方待着。就想在这儿。
yuto|为什么。
shiori|因为这里已经坏掉了。
@wait 0.6
shiori|坏掉的东西，待着比较安心。
@wait 1.2
yuto|……三浦。
shiori|嗯。
yuto|你在怕什么。
@wait 1.4
@fx vignette 0.4
shiori|（很久。外面一阵风）我想活到冬天。
yuto|……什么？
shiori|（转过来，笑了一下）没什么。我想看雪。
@wait 1.0
|　　汐浦町一年下不了几次雪。
|　　她说这话的时候，眼睛看着我的肩膀，没有看我的脸。
@hide all 1.0

@bg bg_okada_genkan 1.2
@amb rain 1.5
@bgm dark 2.0
@cal 8/24 小潮 夜
|　　台风夜里，父亲没有回来。他在渔港守船。
|　　凌晨一点，奶奶不见了。
@wait 0.8
|　　玄关的鞋少了一双。门开着。
@wait 1.0
@fx shake_big
|　　雨里找了两个小时。
|　　最后在町内会馆的门口找到她。她穿着一只鞋，另一只不知道丢在哪儿了。
@wait 0.8
@char fumi c 0.9
fumi|我要回家。
yuto|（喘着气）奶奶。这就是回家的路。
fumi|（看着会馆的门）不是这里。
yuto|……
fumi|（很固执）不是这里。
@wait 1.2
@fx flash_dark
yuto|（我吼了）这里就是！你住的地方就在前面！你连这个都忘了吗！
@wait 1.4
|　　她愣住了。
|　　她看着我，像看一个陌生人。
@wait 1.0
fumi|……对不起。
yuto|……
fumi|（很小声）对不起。我不认识路。
@wait 1.2
@hide all 0.8
@bg bg_okada_genkan 0.0
@fx vignette 0.5
|　　我把她背回家。
|　　到家以后，我在玄关跪下来，哭了很久。
|　　玄关的灯是白的，很亮，照得人很难看。
@wait 1.6
@fx vignette 0.0 1.5
|　　那天以后，蝉忽然全停了。
|　　八月二十四号。我记住了这个日子。
@wait 1.0

@bg bg_classroom 1.2
@amb room 1.0
@bgm sad 2.0
@cal 8/27 中潮 午后
|　　台风过了以后，她回学校了。
|　　年级第一，还是年级第一。
|　　只是她开始在课间趴在桌上。
@char shiori_normal c 0.85
|　　那天放学，她的书包没关严。
|　　我看见了里面的东西。
@wait 1.0
|　　一个药袋。
|　　上面写着我看不懂的药名。
@wait 1.2
@choice
* 「……这是什么。」 -> ch3_ask
* （我没有问。我把书包带给她系好了。） -> ch3_silent
@endchoice

:: ch3_ask
@char shiori_sad c 0.85
shiori|（很快地把书包拉上）维生素。
yuto|骗人。
shiori|（没有生气。很平静地）冈田同学。
yuto|……
shiori|（把书包背好）不要问了。
@wait 1.0
shiori|求你了。
@wait 1.2
|　　她说「求你了」的时候，声音在抖。
|　　所以我停下了。
@set ch3_noticed true
@goto ch3_after

:: ch3_silent
@char shiori_normal c 0.85
|　　我把书包带递给她。
|　　她说了声谢谢。
|　　我们谁都没有再提这件事。
@set ch3_noticed true
@goto ch3_after

:: ch3_after
@hide all 0.8
@bg none 0.6
@fx blackout 0.8
@wait 0.8
|　　那天晚上，我在第四封信上写了这件事。
|　　写完之后，我把纸揉了，又重新写了一遍。
|　　第二遍写的东西，和第一遍不一样。
@letter ch3
@timeslot ch3
@goto ch4


# ============================================================
:: ch4
@set stage_heavy true
@chapter 第四章　退潮
@cal 9/6 干潮（干潮15:10） 昼
@fx blackout_end 1.2
@amb room 1.0
@bgm daily 1.5
@bg bg_classroom 1.2
|　　九月六号。新月。潮位是一年里最低的几天。
|　　退潮的时候，渔港的味道会变得很重。
@wait 0.8
|　　那天下午第二节课，她在楼梯上倒下了。
@wait 1.0
@fx shake_big
@se fall
@bg none 0.2
@fx blackout 0.35
@wait 1.2
|　　这次没有「站起来太快」。
@wait 1.0
|　　佐野瞳背她下楼。我在旁边举着她的头。
|　　她一直在说没事。说到第三遍的时候，声音没有了。

@fx blackout_end 0.8
@bg bg_clinic 1.2
@amb room 1.2
@bgm tension 1.5
@cal 9/6 干潮 夕
@char daikan c 0.9
|　　大贯医生把听诊器摘下来，挂在脖子上。
|　　他没有马上说话。
daikan|你今年多大。
shiori|（坐在诊察床上）十七。
daikan|（点头。点头点了很久）……你家里人呢。
shiori|我妈妈在市里做透析。周三、周五、周日。
daikan|……
@wait 1.2
shiori|医生，您直说就行。我知道的。
@wait 1.0
|　　大贯抬起头看她。看了大概三秒。
daikan|小姑娘。
shiori|嗯。
daikan|我这里只能看感冒。
@wait 1.2
daikan|你去市里。别在这儿耽误。
shiori|好。
@wait 0.8
|　　她站起来，把椅子推回去。推得很正。
@char daikan c 0.9
daikan|（突然，很轻）……我这话说了三年了。
shiori|……
daikan|没有一个人去。
@wait 1.0
|　　她在门口站住。没有回头。
shiori|我去了。六月。
@se door
@hide all 1.0
@fx vignette 0.45
|　　关门声。
|　　诊所里只剩大贯一个人。
|　　窗外，蝉早就没有了。
@hide all 0.8

@bg bg_hospital_corridor 1.6
@amb room 1.5
@bgm none
@cal 9/8 中潮 午
|　　市立中央医院。从汐浦町坐公交，两个小时，一天四班。
|　　医院里没有音乐，只有自动贩卖机的声音，和叫号的广播。
@wait 1.0
|　　心脏内科的门牌上写着主治医师的名字。
|　　我们在走廊上坐了四十分钟。
@wait 0.8
|　　她一直看着对面墙上的消防栓。
@wait 1.0
@char shiori_normal c 0.9
shiori|冈田同学。
yuto|嗯。
shiori|你要不要先回去。末班车是五点四十。
yuto|不用。
shiori|（很轻）……好。
@wait 1.0
|　　叫号的广播念了她的名字。
|　　她站起来。站起来的时候扶了一下椅子。
@wait 1.0
@hide all 0.8
@fx blackout 1.2
@wait 1.4
|　　医生说了很多词。扩张型心肌病。家族性。代偿期。左心室辅助装置。移植登录。
|　　我只听懂了一半。
@wait 1.0
|　　另一半是她的表情。她一直在点头，像在听别人念一份她已经背下来的文件。
@wait 1.2
@fx vignette 0.5
|　　医生问她：家属呢。
|　　她说：就我一个。
@wait 1.0
|　　医生看了我一眼，然后什么都没说，把一张纸推过来。
@fx blackout_end 1.0

@bg bg_hospital_corridor 1.0
@amb room 1.2
@bgm sad 2.0
@cal 9/8 中潮 夕
@char shiori_normal c 0.9
|　　出医院的时候天已经黑了。
|　　她在自动贩卖机前面站了很久，最后买了一罐咖啡，一百二十日元。
@wait 0.8
yuto|……你三个月前就知道了。
shiori|（把咖啡递给我）嗯。
yuto|为什么不告诉我。
@wait 1.4
shiori|（看着贩卖机的灯）因为告诉你的话，你就不会走了。
@wait 1.6
@fx vignette 0.45
|　　我拿着那罐咖啡，站了很久。
|　　咖啡是热的。烫手。
@wait 1.0
yuto|我哥也是这个病。
shiori|我知道。
yuto|我哥等不到心脏。
shiori|（很平）等了两年零四个月。
@wait 1.2
yuto|……
shiori|（转过来看我）冈田同学。我算过账。
yuto|算什么账。
shiori|（笑了一下）我这条命的价格，我们家付不起第二次。
@wait 1.6
@hide all 0.8
@fx blackout 1.4
@wait 1.2
|　　那罐咖啡我一直没喝。
|　　回到汐浦町的时候，它已经凉了。

@bg bg_okada_genkan 1.2
@amb night 1.5
@bgm none
@cal 9/12 中潮 夜
|　　九月十二号晚上，我给我妈打了一个电话。
|　　她在邻市的超市上晚班。
@wait 1.0
|　　「妈。」
|　　「怎么了？奶奶出事了？」
|　　「没有。」
@wait 0.8
|　　「那你这么晚打电话干什么。」
@wait 1.0
|　　「……妈，你能不能回来一次。」
@wait 1.2
|　　「……店里排班排不开。」
@wait 1.4
|　　「……我知道了。」
@wait 1.0
@se hangup
|　　挂断。
@wait 1.4
@fx vignette 0.5
|　　我站在玄关。鞋柜上有我爸的酒瓶，我妈的拖鞋，奶奶的伞。
|　　一样都没有动过。
@wait 1.6
|　　那天晚上我没睡。
|　　我找出了一张表格。
@wait 0.8
|　　是介护保险的申请书。我在町役场的窗口拿的，拿了两个星期，一直没填。
@wait 1.0
|　　第二天早上，我把它填完了。
|　　填错了三个地方，又去要了一张。
@set care_form_done true
@timeslot ch4
@care day4
@letter ch4
@goto ch5


# ============================================================
:: ch5
@chapter 第五章　朔
@cal 9/16 中潮 朝
@fx blackout_end 1.2
@amb room 1.0
@bgm tension 1.5
@bg bg_port_morning 1.2
|　　九月十六号，我开始凑钱。
|　　医生说，先说过渡治疗。先说能撑多久。
|　　医生没有说数字。医生只说了方案和风险。
@wait 0.8
|　　我把家里能卖的东西列了一遍。
|　　列完之后，我把纸撕了——上面只有六样。
@wait 0.6
|　　我退了补习班的报名费。三万八。
|　　我把我爸留给我的一条旧项链卖了。一万二。
@wait 0.8
|　　差得很远。差得不是一点。
@hide all 0.6

@bg bg_okada_genkan 1.2
@amb night 1.5
@bgm sad 2.0
@cal 9/16 中潮 夜
|　　九月十六号晚上，我爸没有回来吃饭。
|　　第二天早上，餐桌上多了一个信封，和一瓶没开的酒。
@wait 1.0
@char seiichi c 0.9
yuto|……爸。
seiichi|（背对着我，在穿鞋）酒没了就去买。别站那儿看我。
yuto|这是什么。
seiichi|（没有回头）渔船份额。
yuto|……
seiichi|（系鞋带。系了两次）你爷爷的，你太爷爷的。到我这代，第三份。
@wait 1.0
yuto|爸。
seiichi|（站起来，往门外走）卖了。
@wait 0.8
seiichi|（在门口停下）……那姑娘不错。
@wait 0.6
seiichi|（走了）
@hide all 1.0
@fx vignette 0.4
|　　后来我才知道，近海渔业的份额是不能随便卖的。
|　　卖给人，就等于把冈田家在这片海上的位置，从户口本上划掉。
@wait 1.0
|　　他没有解释过一句。
|　　他那天晚上没有回家。

@bg bg_okada_genkan 1.0
@amb rain 1.5
@bgm none
@cal 9/17 中潮 夕
|　　九月十七号，下雨。
|　　傍晚，浜口源治站在我家门口。
@char hamaguchi c 0.9
|　　他是渔具店的老板。三十年前在第三工场干过七个月。
|　　他恨三浦家恨了三十年。这件事全町都知道。
@wait 0.8
hamaguchi|（把信封递过来）拿着。
yuto|浜口叔……
hamaguchi|三十年前，你爷爷还在的时候，我在那个厂干了七个月。
yuto|我知道。
hamaguchi|没拿到钱。三浦他爹跑的。这事我记了三十年。
yuto|……
@wait 0.8
hamaguchi|我孙子今年八岁。
yuto|……
hamaguchi|（停顿）也是这个病。
@wait 1.2
|　　我的手僵在半空。
@wait 0.6
hamaguchi|我不是给你的。
yuto|……什么？
hamaguchi|（把信封拍在我手心里）我不欠你们家的了。
@wait 1.0
|　　他转身往外走。走到门口停下了，站了很久。
|　　雨声。
hamaguchi|（背对着我）……你告诉她，我不恨她爹了。
@se door
@hide all 1.0
@wait 1.0
@cg cg_envelopes 1.4
@hide all 0.0
@bgm none
|　　然后是第二个老人。
|　　第三个。第四个。第六个。
@wait 0.8
|　　没有人多说话。每个信封上都有一个名字。
|　　都是三十年前的工资。
@wait 1.0
|　　那天晚上，玄关的鞋摆满了。
|　　我数了三遍。一共十四个信封。
@wait 1.2
|　　十四个信封加在一起，是四十七万。
|　　过渡治疗的第一笔，要一百八十万。
@wait 1.6
@fx vignette 0.5
|　　我坐在玄关，抱着那十四个信封。
|　　这是我这辈子最有钱的一个晚上，也是我最穷的一个晚上。
@cg_hide 1.0
@set envelopes_done true
@hide all 0.6

|　　那天晚上，我在玄关坐了很久。
|　　后来我在那叠信封的最上面，写了几行字。
|　　写完之后我又读了一遍。我没有撕掉。
@letter ch5

@bg bg_hospital_corridor 1.2
@amb room 1.2
@bgm shiori 2.0
@cal 9/18 中潮 昼
|　　九月十八号，医院。
|　　我在走廊上遇见佐野瞳。她穿着白色的实习服，手里抱着一摞病历。
@char hitomi c 0.9
hitomi|（看见我，愣了一下）……你怎么在这儿。
yuto|陪人。
hitomi|（点头。她没问是谁）
@wait 0.8
hitomi|我来交材料。下个月开始，我在这儿实习。
yuto|你考上了？
hitomi|（笑）嗯。介护福祉。町里给补助，条件是毕业回来干五年。
yuto|……你想去市里的。
hitomi|（看着走廊尽头）想啊。
@wait 1.0
hitomi|（转回来）冈田。
yuto|嗯。
hitomi|（很认真）你走吧。
yuto|……
hitomi|真的。这里总得有人留下，但不一定是你。
@wait 1.2
yuto|……你留下就行了？
hitomi|（笑了一下，笑得很难看）我不是没考上。我是没报名。
@wait 1.0
|　　这是她第一次说这句话。说完她就转身走了，走得很快。
@hide all 0.8

@timeslot ch5

@bg bg_hospital_corridor 1.0
@amb room 1.0
@bgm tension 1.5
@cal 9/18 中潮 夕
|　　傍晚，我在医院门口看见一辆黑色的车。
|　　车上下来的男人，四十多岁，西装，没有打领带。
@char kiryu c 0.9
kiryu|你是冈田同学吧。
yuto|你是谁。
kiryu|桐生。桐生正人。
@wait 0.8
kiryu|（很客气）她父亲以前和我在一个厂。
yuto|……
kiryu|（看着医院大楼）她的治疗费，我在出。
@wait 1.0
|　　我听懂了。
|　　我也听懂了另一件事——她从来没有跟我说过。
@wait 1.2
kiryu|（很平静地）她跟我签了一份东西。毕业以后。
yuto|……
kiryu|（终于看向我）我没有别的意思。
@wait 1.0
kiryu|我只是……也不知道该怎么对一个人好。
@wait 1.4
|　　他说完这句话，就上车走了。
|　　他没有要我等他的回答。他好像并不需要回答。
@hide all 0.8
@set met_kiryu true
@fx vignette 0.55
@wait 1.0

@bg bg_hospital_corridor 1.0
@amb room 1.0
@bgm none
@cal 9/18 中潮 夜
|　　走到 816 门口的时候，我听见里面有说话的声音。
|　　我停下了。
@wait 1.0
chizuru|栞。
@wait 0.8
|　　……
@wait 0.6
chizuru|妈妈不治了。
@wait 1.2
|　　……
@wait 0.6
chizuru|妈妈不治了。你把钱留着自己用。
@wait 1.0
shiori|（很平）妈，你上次也这么说。
shiori|（很平）然后你去了。
@wait 1.2
|　　……
@wait 0.8
shiori|所以我们都不算数。
shiori|我们都不算数，就这样过吧。
@wait 1.4
|　　门里面安静了很久。
|　　我把手放在门把上，一直没有推开。
@wait 1.2
@fx vignette 0.4
@char chizuru c 0.9
|　　门从里面打开了。
|　　她看见我，愣了一下。她什么都没有问。
chizuru|（侧身让开）你进去吧。
yuto|……好。
@wait 0.8
|　　她走了两步，又停下来。
chizuru|（背对着我）冈田同学。
yuto|嗯。
chizuru|（想了很久）她要是跟你说什么，你就听着。
chizuru|别劝她。
@wait 1.0
yuto|……为什么。
@wait 1.0
chizuru|（很久）因为她劝不动我。
@wait 1.2
|　　她走了。走廊很长，她的脚步声一直在响。
@hide all 1.0
@fx vignette 0.3
|　　我回到病房。
|　　她坐在窗边，正在把奶奶的药单抄在一本册子上。
@char shiori_weak c 0.9
shiori|（没有抬头）你回来了。
yuto|你在写什么。
shiori|（很快地翻过去）没什么。
@wait 1.0
|　　窗外的天已经黑了。
|　　这是最后一个晚上。后来我才知道——这是最后一个晚上。
@wait 1.2
@hide all 0.4
@fx vignette 0.3
|　　我该说点什么。
@wait 1.0
@if memory >= 10
@choice
* 「……你是打算把自己卖掉吗。」 -> route_ask
* 「我来想办法。你一定要治。」 -> route_treatment
* 「……好。我听你的。」 -> route_respect
* 「我不替你决定。但你要答应我一件事。」 -> route_promise
@endchoice
@else
@choice
* 「……你是打算把自己卖掉吗。」 -> route_ask
* 「我来想办法。你一定要治。」 -> route_treatment
* 「……好。我听你的。」 -> route_respect
* 「我考出去。这里的事……我不想再想了。」 -> route_leave
@endchoice
@endif

:: route_ask
@char shiori_sad c 0.9
@set route_ask true
@bgm dark 2.0
yuto|三浦。桐生正人是谁。
shiori|（手停了）
yuto|他刚才在楼下。
shiori|……
yuto|你跟他签了什么。
shiori|（把册子合上）
yuto|回答我。
@wait 1.2
yuto|你是打算把自己卖掉吗。
@wait 1.6
|　　她抬起头。她看了我很久。
|　　然后她说了一个字。
shiori|是。
@wait 1.4
yuto|……
shiori|（站起来，把册子放进包里，动作很慢）冈田同学。
shiori|你说得对。
@wait 1.0
shiori|（走到门口）你回去吧。
@wait 1.0
|　　门关上了。
|　　我在病房里站了很久，站到护士来赶我。
@wait 1.2
@hide all 1.0
@goto finale

:: route_treatment
@set route_treatment true
@char shiori_normal c 0.9
yuto|我来想办法。
shiori|（抬头）
yuto|钱的事我来想办法。你一定要治。
@wait 1.0
shiori|冈田同学，你听我说——
yuto|（打断她）我听过了。医生说的我都听过了。
yuto|现在听我说。
@wait 1.2
yuto|你哥哥等了两年零四个月。
shiori|……
yuto|这一次，不会让你一个人等。
@wait 1.4
|　　她没有说话。
|　　她低下头，肩膀在抖。
|　　我这才发现，这是我认识她三个月以来，第一次看见她哭。
@hide all 1.0
@goto finale

:: route_respect
@set route_respect true
@char shiori_normal c 0.9
yuto|……好。
shiori|（抬头）
yuto|我听你的。
@wait 1.2
shiori|（看了我很久）……你为什么不留我。
yuto|因为这是你的事。
@wait 1.0
shiori|（很小声）……你这个人，真的很奇怪。
@wait 1.0
|　　她笑了一下。那个笑很轻。
|　　后来我想过很多次：如果我那天说了别的话，会不会不一样。
|　　想了很多年，没有答案。
@hide all 1.0
@goto finale

:: route_promise
@set route_promise true
@char shiori_normal c 0.9
yuto|我不替你决定。
shiori|……
yuto|治不治，是你的事。我不管。
@wait 0.8
shiori|（有点意外）
yuto|但你要答应我一件事。
shiori|什么。
@wait 1.0
yuto|不要一个人扛。
@wait 1.4
shiori|……
yuto|你分我奶奶的药，分了三个月。你教我怎么填介护保险的表。
yuto|你把我以后的每一天都安排好了。
@wait 1.0
yuto|现在轮到我了。
@wait 1.4
|　　她很久没有说话。
|　　然后她伸出手，把我手心里那个信封拿过去，看了看上面的名字。
shiori|（很轻）……浜口叔的。
yuto|嗯。
@wait 1.0
shiori|（把信封还给我）好。
yuto|什么？
shiori|（点头）我答应你。
@wait 1.2
|　　那天晚上她把那本册子给我看了一半。
|　　她说，剩下的一半，等以后。
@hide all 1.0
@goto finale

:: route_leave
@set route_leave true
@char shiori_normal c 0.9
yuto|我考出去。
shiori|（抬头）
yuto|这里的事……我不想再想了。
@wait 1.4
|　　她看了我很久。
|　　然后她笑了一下。她笑得比我见过的任何一次都轻松。
shiori|嗯。
shiori|（很轻）这样最好。
@wait 1.2
|　　我不知道她为什么说「最好」。
|　　我是很多年以后才知道的。
@hide all 1.0
@goto finale


# ============================================================
:: finale
@chapter 终章　残夏
@cal 9/19 朔望大潮（満潮17:58・涨潮提前1小时20分） 夜
@fx blackout_end 1.4
@amb night 2.0
@bgm none
@bg bg_seawall_night 1.6
|　　九月十九号。中秋名月。
|　　满月。朔望大潮。
@wait 1.0
|　　这一天，汐浦港的潮位比平常高四十厘米。
|　　涨潮的时间，比潮汐表上写的提前了一小时二十分。
@wait 1.2
|　　这张潮汐表，从六月的第一天起就贴在我房间的墙上。
|　　我看过它很多次。我从来没有看懂过它。
@wait 1.4
@if route_ask
@goto ending_silent
@endif
@if route_leave
@goto ending_noreply
@endif
@if route_respect
@goto ending_ebb
@endif
@goto finale_night


:: finale_night
@bgm shiori 2.0
@bg bg_seawall_night 0.0
|　　那天下午，她给我发了一条消息。
|　　只有一行字：「今天想看海。」
@wait 1.0
@char shiori_casual c 0.9
|　　她穿的是那件白色连衣裙。袖口还是起毛的。
shiori|（站在防波堤上）退潮了。
yuto|嗯。今天是大潮。
shiori|（指着远处）你看。
@wait 1.0
@cg cg_moon_sea 1.6
@hide all 0.4
|　　沉船露出来了。
@wait 1.0
|　　汐浦丸。昭和三十八年的船。它已经在海底躺了五十年。
|　　只有在大潮的退潮，它才会露出来一次。有时候一年都露不出来。
@wait 1.2
shiori|我哥小时候在这上面摔断过腿。
yuto|……在这上面？
shiori|（笑）他爬上去过。我妈打了他一顿。
@wait 1.0
shiori|他躺在医院里的时候还说，等我好了再去爬一次。
@wait 1.4
|　　这是她第一次主动说起她哥哥。
|　　也是我第一次听见她笑出声。
@wait 1.0
shiori|（坐下来，拍了拍旁边的沙）冈田同学。
yuto|嗯。
shiori|坐这儿。
@wait 1.2
|　　月亮很低，压在海面上。
|　　我们坐了很久，谁都没有说话。
@wait 1.4
shiori|（很小声）今天很好。
yuto|嗯。
shiori|今天很好。真的。
@wait 1.6
@cg_hide 1.2
@char shiori_weak c 0.9
|　　后来她靠在我肩膀上，说想睡一会儿。
|　　我说好。
@wait 1.0
|　　她的呼吸很轻。
|　　轻到我隔了很久才发现——她已经不是在睡觉了。
@wait 1.6
@fx vignette 0.6
|　　我抬起头。
|　　水已经在消波块下面了。
@wait 1.0
|　　涨潮比潮汐表早了整整一小时二十分。
@wait 1.2
@bgm none
@amb sea 1.0
@fx shake_big
@se wave
|　　我背着她往回跑。
@wait 1.0
|　　水漫过我的膝盖。我摔了两次。
|　　第一次摔在消波块上，膝盖破了。第二次是踩空。
|　　第二次的时候，她在我背上哼了一声。
@wait 1.4
|　　她醒了。她说，你别跑了。
|　　我没有停。
@wait 1.2
@bg none 0.8
@fx blackout 1.0
@wait 1.2
|　　自行车。商店街。没有人的镇子。
|　　驾驶座上的老人。大贯医生的手。
@wait 1.0
|　　救护车从市里来，要四十分钟。
|　　那四十分钟里，我一直在数她的呼吸。
@wait 1.6
@fx blackout_end 1.0
@amb room 1.0
@bg bg_hospital_corridor 1.2
@bgm none
@cal 9/19 朔望大潮 深夜
|　　救护车上，她清醒了几分钟。
@wait 0.8
@char shiori_weak c 0.9
|　　她戴着氧气面罩。眼睛是睁着的。
|　　她把手抬起来，抓住我的袖口。
shiori|（面罩里，声音很轻）悠人。
yuto|在。我在。
shiori|我房间。
yuto|嗯。
shiori|书桌。第二格。
yuto|……什么？
shiori|你奶奶的药。早上和晚上不一样。
@wait 1.2
|　　我握着她的手。我说不出话。
shiori|别搞错。
yuto|……好。
@wait 1.4
|　　她停了一会儿。监护仪的声音。
shiori|你别学那首歌。
yuto|……
shiori|（很小声）……今天很好。
@wait 1.6
|　　她的手松了。
@hide all 0.8
@fx vignette 0.5
@wait 1.2
@if route_treatment
@goto ending_flood
@endif
@goto ending_true


# ============================================================
:: ending_true
@bg bg_hospital_corridor 0.8
@amb room 1.0
@bgm none
@cal 9/20 病院 朝
|　　她没有再醒过来。
|　　低氧性脑损伤。脑死亡判定。两次，间隔六小时。
@wait 1.2
|　　医生问我，她有没有签过什么东西。
|　　我说我不知道。
|　　后来护士在她的包里找到了两份复印件。
@wait 1.0
|　　一份是移植登录同意书。
|　　另一份，是器官捐献意愿书。
@wait 1.4
|　　第一份她自己划掉了。
|　　第二份留了下来。
@wait 1.6
@fx blackout 1.2
@wait 1.0
@bg bg_seawall_dusk 1.2
@amb sea 1.5
@bgm sad 2.0
@cal 9/23 葬仪 午后
|　　葬礼在町营葬仪场办的。
|　　来了八十几个人。比汐浦町过去十年任何一场葬礼都多。
@wait 1.0
|　　浜口源治跪在灵前，一句话也说不出来。
|　　他把那个信封放在了香案上。
|　　那个信封他攒了三十年。他一分钱利息都没加。
@wait 1.2
|　　桐生正人来了。被她母亲当众赶了出去。
|　　他没有反抗，只是在门外站着，站到最后。
@wait 1.0
|　　奶奶也来了。她问：那个给我分药的姑娘呢。
|　　没有人回答她。
|　　第二天早上，她又问了一遍。
@wait 1.6
|　　九月二十五号，市立医院打来电话。
|　　她的心脏，移植给了浜口源治的孙子。
|　　另外两个器官，去了市里，给了两个我们不认识的人。
@wait 1.4
@fx vignette 0.4
|　　那个孩子活下来了。
|　　他今年八岁。
@cg_hide 0.6
@bg bg_shiori_room 1.4
@amb room 1.0
@bgm shiori 2.0
@cal 9/28 三浦家 午后
|　　她的房间很小。窗台上摆着十一个蝉蜕。
@wait 1.0
|　　书桌第二格。一本笔记本。
|　　封面写着「给冈田同学」。
@wait 1.2
|　　第一页：
|　　「你奶奶的药：早上 2 种（白、黄），晚上 3 种（白、黄、粉）。粉的是睡前。」
|　　「不要用茶水。她不喜欢，但会喝。」
|　　「——三浦栞。7 月 12 日。」
@wait 1.6
|　　第十四页：
|　　「傍晚五点左右，她会重复问同一件事。不要纠正她。顺着说，她会安心。」
|　　「这一点很重要，请务必记住。」
@wait 1.4
|　　第三十一页：
|　　「介护保险的申请：町役场 1 号窗口，负责人叫中村，周二周四在。」
|　　「要主治医师的意见书，先找大贯医生开，他写字很快。」
@wait 1.4
|　　最后一页，字迹比前面潦草：
@wait 1.0
|　　「冈田同学。」
|　　「你不要觉得欠我什么。」
|　　「我只是……很想让这个夏天，有一个人记得。」
|　　「——栞」
@wait 2.0
|　　抽屉最里面，还有一张纸。
|　　是一份入学申请书的复印件。
|　　志愿校那一栏，她替我填好了一半。写着东京。
@wait 1.8
@amb sea 2.0
@bg bg_beach_night 1.4
@cal 10/2 岬 夕
|　　十月二号，我一个人去了那个小岬。
|　　我没有哭。
@wait 1.0
|　　我把第七封信放进了海里。
|　　那封信我写了三天，最后还是只有一句话。
@wait 1.6
@fx blackout 1.6
@wait 1.4
@bg bg_hospital_corridor 1.4
@amb room 1.0
@bgm shiori 2.0
@cal 多年后·东京 - 午后 午后
|　　我在东京念了看护福祉。
|　　毕业以后，我在一间医院做事。
@wait 1.0
|　　那天下午在下雨。一个学生站在走廊上问我。
@wait 0.8
|　　「老师。」
|　　「嗯。」
|　　「你为什么会做这个？」
@wait 1.4
|　　我看着窗外。雨。
@wait 1.0
|　　「……因为有人教过我。」
|　　「教你什么？」
@wait 1.2
|　　「怎么把一个人的份也活下去。」
@wait 2.0
@fx blackout 2.0
@wait 1.6
@ending true


# ============================================================
:: ending_flood
@bg bg_hospital_corridor 0.8
@amb room 1.0
@bgm none
@cal 9/20 病院 朝
|　　她被推进了抢救室。
|　　三点十七分，护士出来说了一句：心率回来了。
@wait 1.2
|　　她在重症监护室躺了十一天。
|　　第十二天早上，她睁开眼睛，问的第一句话是：我奶奶的药单呢。
@wait 1.0
|　　我说，是「你」。
|　　她说，哦。
@wait 1.4
|　　钱的问题，在我爸卖掉渔船份额的那个下午就解决了一半。
|　　剩下的一半，是我退学，进町里的土木公司，签了一份要还很多年的借款。
@wait 1.2
|　　我退掉了补习班的报名费，退掉了考试。
|　　我把那本纪念册的稿子交给佐野瞳的时候，她说：你想清楚了吗。
|　　我说想清楚了。
@wait 1.0
|　　她说：你骗人。
@wait 1.6
@bg bg_hospital_corridor 1.0
@amb room 1.0
@bgm sad 2.0
@cal 一年后·汐浦站 - 午后
|　　她接受了治疗，正式登录了移植。
|　　一年后，她搬去市里做定期随访。
@wait 1.0
|　　我留在汐浦町。照顾奶奶，也照顾她母亲。
|　　她母亲每周三、周五、周日透析。我记住了日子。
@wait 1.2
|　　我们每个月通一次电话。每次都聊不到十分钟。
|　　她总是问：奶奶好吗。
|　　我总是说：好。
@wait 1.6
@bg bg_station 1.4
@amb room 1.0
@cal 多年后 汐浦站 候车室
|　　多年以后，我在汐浦站的候车室遇见她。
@wait 1.0
@char shiori_normal c 0.9
shiori|（愣了一下）……冈田同学。
yuto|嗯。
@wait 1.0
shiori|你瘦了。
yuto|……你也是。
@wait 1.4
|　　我们坐在同一张长椅上，等同一班车。
|　　谁都没有再说话。
@wait 1.2
|　　广播念了站名。列车进站。
@wait 1.0
shiori|（站起来，把包背上）那我走了。
yuto|嗯。
@wait 1.0
shiori|（走了两步，回头）冈田同学。
yuto|嗯。
@wait 1.2
shiori|（想了很久）……没什么。
@wait 1.4
|　　她上了车。
|　　车开走以后，我在候车室坐了很久。
@wait 1.6
|　　我们都活着。
|　　这不是同一件事。
@wait 2.0
@fx blackout 2.0
@wait 1.4
@ending flood


# ============================================================
:: ending_ebb
@bg bg_okada_kitchen 1.0
@amb room 1.2
@bgm none
@cal 9/20 冈田家 朝
|　　她没有再去过医院。
|　　她母亲求过她一次。她说的还是那句话。
|　　栞回答她的，也是同一句。
@wait 1.4
|　　我陪她把清单上的事一件一件做完。
@wait 0.8
|　　第一件：让她母亲学会一个人去透析。她花了两个星期，反复教她怎么挂号。
|　　第二件：跟房东谈好，一个人的房租减半。
|　　第三件：去哥哥的墓前扫了一次草。
|　　第四件：去看一次海。
@wait 1.4
@bg bg_shopping_street 1.2
@amb cicada 1.0
@bgm shiori 2.0
@cal 十月·商店街 - 午后
|　　九月剩下的日子过得很快。
|　　她开始走不动路了。从家门口到商店街，要歇两次。
@char shiori_casual c 0.9
shiori|（坐在长椅上）冈田同学。
yuto|嗯。
shiori|你明年春天，要去哪里。
yuto|……不知道。
shiori|（看着卷帘门）你应该知道。
@wait 1.2
|　　十月，十一月。
|　　汐浦町的灯油炉开始有味道了。
@wait 1.0
@hide all 1.0
@bg bg_okada_kitchen 1.4
@amb wind 1.5
@bgm none
@cal 11/28 三浦家 朝
|　　十一月二十八号的清晨。
|　　她母亲在床边，我在楼下买早饭。
@wait 1.2
|　　回来的时候，门口停着一辆车。
@wait 1.6
@fx vignette 0.5
|　　她很安静。脸上没有一点难受的样子。
@wait 1.4
|　　她的清单上有九件事。全部完成。
|　　第十件是空的。
@wait 1.2
|　　后来我在那本册子的最后找到了一行很浅的字，像是写了一半又擦掉了：
|　　「（不用写了。）」
@wait 2.0
@bg bg_station 1.4
@amb wind 1.2
@cal 多年后·汐浦町 - 午后
|　　我再也没有离开汐浦町。
@wait 1.0
|　　我照顾奶奶，也照顾她母亲。她母亲的透析日是周三、周五、周日。
|　　佐野瞳在养老设施上班，我们偶尔在便利店碰见，聊两句天气。
@wait 1.2
|　　我活成了她希望的样子。
|　　代价是我自己的一生。
@wait 1.6
|　　我不后悔。
|　　我只是有时候，会想起那年夏天她数蝉蜕的样子。
@wait 2.0
@fx blackout 2.0
@wait 1.4
@ending ebb


# ============================================================
:: ending_silent
@bg bg_seawall_night 1.2
@amb sea 1.5
@bgm dark 2.0
@cal 9/19 朔望大潮 夜
|　　那天晚上，她一个人去了防波堤。
@wait 1.2
|　　我在家里。我把那本纪念册的稿子看了一遍，看到她写的那一页。
|　　她写：「汐浦町的海，一年里有三百天是灰色的。」
|　　「剩下那六十五天，很好看。」
@wait 1.4
|　　晚上十一点四十，佐野瞳给我打电话。
|　　她说：防波堤那边，水已经上来了。
@wait 1.6
@fx shake_big
|　　我骑车过去用了九分钟。
|　　潮位比平常高四十厘米。涨潮比潮汐表早了一小时二十分。
@wait 1.2
|　　我在消波块的缝里找到她的鞋。
@wait 1.6
@fx vignette 0.6
|　　找到她的时候，是凌晨两点零七分。
@wait 1.4
|　　溺水。低氧性脑损伤。
|　　在救护车上，医生做了四十分钟的心肺复苏。
@wait 1.6
@bg bg_shiori_room 1.4
@amb room 1.0
@bgm none
@cal 9/22·三浦家 - 午后
|　　她的日记放在书桌上，没有锁。
|　　我翻到最后一页。
@wait 1.2
|　　「今天他骂我了。」
@wait 1.0
|　　「……太好了。」
@wait 0.8
|　　「这样他以后就不会难过。」
@wait 2.0
|　　我把那一页读了六遍。
|　　窗台上摆着十一个蝉蜕。
@wait 1.6
|　　我后来想了很多年：如果我那天没有说那句话。
|　　如果我说了别的。
@wait 1.2
|　　可是那天我确实说了那句话。
|　　而这个世界，不会因为你想得久一点，就给你第二次机会。
@wait 2.0
@fx blackout 2.0
@wait 1.4
@ending silent


# ============================================================
:: ending_noreply
@bg bg_station 1.2
@amb wind 1.2
@bgm sad 2.0
@cal 次年春·汐浦站 - 午后
|　　第二年春天，我考上了市里的大学。
|　　走的那天，佐野瞳来送我。她给我塞了一袋便利店的饭团。
@wait 1.2
|　　列车开动的时候，我看见站台尽头有个人。
|　　我没有看清。列车就过去了。
@wait 1.6
@fx blackout 1.4
@wait 1.2
@bg bg_hospital_corridor 1.2
@amb room 1.0
@bgm none
@cal 多年后·东京 - 午后
|　　她的信，一封都没有寄出去。
@wait 1.2
|　　很多年以后，一个陌生号码打来。
|　　是三浦千鹤的声音。
@wait 1.0
|　　「……你是悠人吧。」
|　　「栞的东西里，有你的名字。」
@wait 1.8
@bg bg_shiori_room 1.4
@amb room 1.0
@bgm shiori 2.0
|　　我回到汐浦町。
|　　她的房间还是那样。窗台上摆着十一个蝉蜕。
@wait 1.2
|　　我翻开那本手写的册子。
|　　封面写着「给冈田同学」。
@wait 1.0
|　　第一页：
|　　「你奶奶的药，早上和晚上不一样。别搞错。」
|　　「——三浦栞。写于 7 月 12 日。」
@wait 2.0
|　　而我认识她，是 6 月 17 日。
@wait 1.6
|　　我从认识她的第二十五天起，就在她的安排里。
|　　我用了很多年，才明白这件事有多重。
@wait 1.8
@fx vignette 0.5
|　　那天下午我在她房间里坐了很久。
|　　天黑了，我没有开灯。
@wait 2.0
@fx blackout 2.4
@wait 1.6
@ending noreply
