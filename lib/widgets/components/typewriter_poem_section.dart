// lib/widgets/sections/typewriter_poem_section.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/typewriter_text_switcher.dart';

class TypewriterPoemSection extends StatelessWidget {
  const TypewriterPoemSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: TypewriterTextSwitcher(
            lines: [
              '这一碗汤，藏着千千万万个遗憾。',
              '有人喝了忘爱，有人喝了忘恨。',
              '你呢？你想忘掉谁？',
              '轮回路远，不如先喝一口暖暖身子。',
              '别怕，喝了就不疼了。',
              '你那些放不下的，不过是时间不够长。',
              '喝吧，记忆终究是凡人的累赘。',
              '重来一次，说不定就能飞升呢。',
              '我见过太多修士，哭着来，笑着走。',
              '别问结果，命运哪有标准答案？',
              '你拼死修炼百年，却抵不过一碗热汤。',
              '这汤不苦，只是你心里还不甘。',
              '别回头，那些人早忘了你。',
              '你走的每一步，他们都不记得了。',
              '轮回不等人，命运不给面子。',
              '别犹豫了，再犹豫就得收夜摊了。',
              '再强的修为，也逃不过命运的删档。',
              '你是第 187694 个在这掉线的修士。',
              '放心，前面还有个美少女也喝了两碗。',
              '喝完别走太快，记得别撞了牛头马面。',
              '这碗汤，连天道也喝过。',
              '我只是个摆摊的，别看我笑，其实我很累。',
              '哦对了，你前世欠的债，还得重新还。',
              '喝吧，今生再演一场。',
              '还有问题？没有就闭眼喝。',
              '再不喝我就加点辣椒油了。',
              '你不喝，后面的鬼都催了三次单。',
              '再问就把你原档发到六道朋友圈。',
              '记住，下次投胎别再卷了。',
              '做个人吧，这回。',
            ],
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'ZcoolCangEr',
            ),
          ),
        ),
      ],
    );
  }
}
