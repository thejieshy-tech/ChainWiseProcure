@Entry
@Component
struct AiAssistantPage {
  @State inputText: string = '';
  @State userQuestion: string = '';
  @State aiReply: string = '';
  @State inputFeedback: string = '';

  private askQuickQuestion(question: string, reply: string): void {
    this.userQuestion = question;
    this.aiReply = reply;
    this.inputFeedback = '';
  }

  private sendQuestion(): void {
    const question: string = this.inputText.trim();
    if (question === '') {
      this.inputFeedback = '请输入需要分析的问题';
      return;
    }
    this.userQuestion = question;
    this.aiReply = '已收到您的问题。根据当前采购数据，建议优先核查订单、发票、收货和付款信息，并关注高风险供应商。';
    this.inputText = '';
    this.inputFeedback = '';
  }

  @Builder
  QuickQuestionButton(title: string, action: () => void) {
    Button(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#4E3DA4')
      .width('100%')
      .height(42)
      .backgroundColor('#F0EDFF')
      .borderRadius(21)
      .onClick(() => {
        action();
      })
  }

  @Builder
  ConversationArea() {
    Column({ space: 14 }) {
      Text('对话区域')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#14213D')
        .width('100%')

      if (this.userQuestion === '') {
        Text('选择一个快捷问题，或在下方输入您想咨询的内容。')
          .fontSize(13)
          .fontColor('#7B879C')
          .width('100%')
          .padding(14)
          .backgroundColor('#F8FAFD')
          .borderRadius(12)
      } else {
        Row() {
          Text(this.userQuestion)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .width('82%')
            .padding({ left: 14, right: 14, top: 11, bottom: 11 })
            .backgroundColor('#1769E0')
            .borderRadius(14)
        }
        .width('100%')
        .justifyContent(FlexAlign.End)

        Row({ space: 10 }) {
          Text('AI')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width(34)
            .height(34)
            .textAlign(TextAlign.Center)
            .backgroundColor('#6554C0')
            .borderRadius(11)
          Text(this.aiReply)
            .fontSize(14)
            .fontColor('#40506A')
            .lineHeight(22)
            .layoutWeight(1)
            .padding({ left: 14, right: 14, top: 11, bottom: 11 })
            .backgroundColor('#F0EDFF')
            .borderRadius(14)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
  }

  build() {
    Column() {
      Row({ space: 14 }) {
        Text('返回')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .width(58)
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor('#2C5289')
          .borderRadius(20)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Column({ space: 4 }) {
          Text('链智AI助手')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('采购对账与供应链风险分析')
            .fontSize(12)
            .fontColor('#C8D8F4')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#0B2D5C')

      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 10 }) {
            Text('您好，我是链智AI助手，可以帮助您分析对账差异、供应商风险和采购处理建议。')
              .fontSize(15)
              .fontColor('#25324B')
              .lineHeight(24)
              .width('100%')
          }
          .width('100%')
          .padding(18)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor('#EAF2FF')
          .borderRadius(16)

          Column({ space: 12 }) {
            Text('快捷问题')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#14213D')
              .width('100%')
            this.QuickQuestionButton('分析高风险供应商', () => {
              this.askQuickQuestion('分析高风险供应商', '当前共有2家高风险供应商。建议优先关注华东办公设备有限公司，其发票金额与采购订单存在差异，并核查近期交付和付款记录。');
            })
            this.QuickQuestionButton('解释对账差异', () => {
              this.askQuickQuestion('解释对账差异', '对账差异主要来自发票金额、采购数量、收货记录和付款状态不一致。建议依次核对采购订单、发票、入库单和付款凭证。');
            })
            this.QuickQuestionButton('给出处理建议', () => {
              this.askQuickQuestion('给出处理建议', '建议先确认高金额异常任务，再创建核查任务联系供应商补充材料，处理完成后更新风险状态并保留核查记录。');
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          this.ConversationArea()
        }
        .width('100%')
        .constraintSize({ maxWidth: 920 })
        .padding({ left: 16, right: 16, top: 18, bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      Column({ space: 8 }) {
        if (this.inputFeedback !== '') {
          Text(this.inputFeedback)
            .fontSize(12)
            .fontColor('#B54747')
            .width('100%')
        }
        Row({ space: 10 }) {
          TextInput({ placeholder: '请输入采购问题', text: this.inputText })
            .fontSize(14)
            .fontColor('#25324B')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#F4F7FB')
            .borderRadius(22)
            .onChange((value: string) => {
              this.inputText = value;
              if (this.inputFeedback !== '') {
                this.inputFeedback = '';
              }
            })
          Button('发送')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width(76)
            .height(44)
            .backgroundColor('#1769E0')
            .borderRadius(22)
            .onClick(() => {
              this.sendQuestion();
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 10, color: '#120F2D4A', offsetX: 0, offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F7FB')
  }
}
