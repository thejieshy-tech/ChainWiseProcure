@Entry
@Component
struct MyPage {
  @State resetPanelVisible: boolean = false;
  @State pageFeedback: string = '';

  private openResetPanel(): void {
    this.pageFeedback = '';
    this.resetPanelVisible = true;
  }

  private closeResetPanel(): void {
    this.resetPanelVisible = false;
  }

  private returnToHome(): void {
    this.pageFeedback = '';
    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/Index'
    }).catch(() => {
      this.pageFeedback = '演示重置失败，请稍后重试';
    });
  }

  private confirmReset(): void {
    this.resetPanelVisible = false;
    this.returnToHome();
  }

  @Builder
  SectionHeader(title: string, description: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#14213D')
      Text(description)
        .fontSize(12)
        .fontColor('#7B879C')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  OverviewRow(title: string, value: string, valueColor: string) {
    Row() {
      Text(title)
        .fontSize(13)
        .fontColor('#7B879C')
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(valueColor)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CapabilityCard(symbol: string, title: string, description: string, accentColor: string) {
    Column({ space: 9 }) {
      Text(symbol)
        .fontSize(symbol === 'AI' ? 13 : 17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(38)
        .height(38)
        .textAlign(TextAlign.Center)
        .backgroundColor(accentColor)
        .borderRadius(12)
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#25324B')
        .width('100%')
      Text(description)
        .fontSize(12)
        .fontColor('#7B879C')
        .lineHeight(19)
        .width('100%')
    }
    .width('100%')
    .constraintSize({ minHeight: 150 })
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
  }

  @Builder
  DataMetric(title: string, value: string, accentColor: string) {
    Column({ space: 5 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(accentColor)
      Text(title)
        .fontSize(12)
        .fontColor('#667085')
    }
    .width('100%')
    .height(76)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F8FAFD')
    .borderRadius(12)
  }

  @Builder
  DemoStep(step: string, title: string) {
    Row({ space: 12 }) {
      Text(step)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(30)
        .height(30)
        .textAlign(TextAlign.Center)
        .backgroundColor('#1769E0')
        .borderRadius(15)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#40506A')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 7, bottom: 7 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ResetConfirmationPanel() {
    Column({ space: 14 }) {
      Text('重新开始演示')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#14213D')
        .width('100%')
      Text('当前页面内存中的演示状态将恢复，是否返回全新首页？')
        .fontSize(14)
        .fontColor('#53627A')
        .lineHeight(22)
        .width('100%')
      Row({ space: 10 }) {
        Button('取消')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1769E0')
          .layoutWeight(1)
          .height(42)
          .backgroundColor('#EAF2FF')
          .borderRadius(21)
          .onClick(() => {
            this.closeResetPanel();
          })
        Button('确认重置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .height(42)
          .backgroundColor('#1769E0')
          .borderRadius(21)
          .onClick(() => {
            this.confirmReset();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#C8DAF5' })
    .borderRadius(16)
    .shadow({ radius: 10, color: '#160F2D4A', offsetX: 0, offsetY: 3 })
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
          Text('我的')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('链智采项目与演示设置')
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
        Column({ space: 22 }) {
          Column({ space: 18 }) {
            Row({ space: 15 }) {
              Text('祖')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .width(58)
                .height(58)
                .textAlign(TextAlign.Center)
                .backgroundColor('#1769E0')
                .borderRadius(29)
              Column({ space: 5 }) {
                Text('祖杰')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#25324B')
                Text('链智采项目体验用户')
                  .fontSize(13)
                  .fontColor('#667085')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(1)
              .color('#EDF1F6')

            Column({ space: 5 }) {
              Text('链智采')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#14213D')
              Text('AI采购对账与供应链风险助手')
                .fontSize(13)
                .fontColor('#7B879C')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(18)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })

          Column({ space: 12 }) {
            this.SectionHeader('项目概览', '当前演示版本与运行信息')
            Column() {
              this.OverviewRow('当前版本', 'V0.9.0 演示版', '#1769E0')
              Divider().strokeWidth(1).color('#EDF1F6')
              this.OverviewRow('项目状态', '核心流程已完成', '#17795B')
              Divider().strokeWidth(1).color('#EDF1F6')
              this.OverviewRow('运行环境', 'HarmonyOS', '#4E3DA4')
              Divider().strokeWidth(1).color('#EDF1F6')
              this.OverviewRow('数据模式', '本地模拟数据', '#B65E10')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
          }
          .width('100%')

          Column({ space: 12 }) {
            this.SectionHeader('核心能力', '链智采本地演示功能')
            GridRow({
              columns: { xs: 1, sm: 1, md: 2, lg: 4 },
              gutter: { x: 12, y: 12 }
            }) {
              GridCol({ span: 1 }) {
                this.CapabilityCard('⇧', '智能订单导入', '本地预览采购订单并生成待对账任务', '#2F74E8')
              }
              GridCol({ span: 1 }) {
                this.CapabilityCard('✓', 'AI智能对账', '分阶段演示订单、发票、收货与付款核对', '#0E8A7A')
              }
              GridCol({ span: 1 }) {
                this.CapabilityCard('!', '供应商风险分析', '识别高风险供应商并展示处理建议', '#C65D3B')
              }
              GridCol({ span: 1 }) {
                this.CapabilityCard('AI', '采购AI助手', '通过快捷问题获取本地模拟采购建议', '#6554C0')
              }
            }
            .width('100%')
          }
          .width('100%')

          Column({ space: 12 }) {
            this.SectionHeader('演示数据说明', '项目内置数据概览')
            Column({ space: 12 }) {
              GridRow({
                columns: { xs: 2, sm: 2, md: 4, lg: 4 },
                gutter: { x: 10, y: 10 }
              }) {
                GridCol({ span: 1 }) {
                  this.DataMetric('对账任务', '5条', '#14213D')
                }
                GridCol({ span: 1 }) {
                  this.DataMetric('风险记录', '6条', '#C2415A')
                }
                GridCol({ span: 1 }) {
                  this.DataMetric('高风险供应商', '2家', '#B54747')
                }
                GridCol({ span: 1 }) {
                  this.DataMetric('AI快捷问题', '3类', '#6554C0')
                }
              }
              .width('100%')
              Text('所有数据均为本地演示数据，不连接真实企业系统')
                .fontSize(13)
                .fontColor('#667085')
                .lineHeight(21)
                .width('100%')
                .padding(12)
                .backgroundColor('#FFF7E8')
                .borderRadius(12)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
          }
          .width('100%')

          Column({ space: 12 }) {
            this.SectionHeader('推荐演示流程', '按顺序体验核心功能')
            Column() {
              this.DemoStep('1', '导入采购订单')
              this.DemoStep('2', '开始AI智能对账')
              this.DemoStep('3', '查看对账差异')
              this.DemoStep('4', '进入风险中心')
              this.DemoStep('5', '使用AI助手获取建议')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
          }
          .width('100%')

          if (this.pageFeedback !== '') {
            Text(this.pageFeedback)
              .fontSize(13)
              .fontColor('#B54747')
              .width('100%')
              .padding({ left: 14, right: 14, top: 11, bottom: 11 })
              .backgroundColor('#FCEAEA')
              .borderRadius(12)
          }

          if (this.resetPanelVisible) {
            this.ResetConfirmationPanel()
          }

          Row({ space: 10 }) {
            Button('重新开始演示')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1769E0')
              .layoutWeight(1)
              .height(46)
              .backgroundColor('#EAF2FF')
              .borderRadius(23)
              .onClick(() => {
                this.openResetPanel();
              })
            Button('返回首页')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .layoutWeight(1)
              .height(46)
              .backgroundColor('#1769E0')
              .borderRadius(23)
              .onClick(() => {
                this.returnToHome();
              })
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ maxWidth: 920 })
        .padding({ left: 16, right: 16, top: 18, bottom: 28 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F7FB')
  }
}
