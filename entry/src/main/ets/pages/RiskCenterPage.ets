interface RiskRecord {
  riskId: string;
  supplier: string;
  title: string;
  level: string;
  status: string;
  amount: string;
}

@Entry
@Component
struct RiskCenterPage {
  @State selectedFilter: string = '全部';
  @State searchExpanded: boolean = false;
  @State searchKeyword: string = '';
  @State navigationError: string = '';

  private readonly risks: RiskRecord[] = [
    { riskId: 'risk-001', supplier: '华东办公设备有限公司', title: '办公椅数量与发票不一致', level: '高风险', status: '待处理', amount: '¥126,800' },
    { riskId: 'risk-002', supplier: '远航服务器科技有限公司', title: '服务器配件单价异常上涨', level: '高风险', status: '待处理', amount: '¥286,000' },
    { riskId: 'risk-003', supplier: '新城物流有限公司', title: '运输费用超过合同约定', level: '中风险', status: '核验中', amount: '¥38,600' },
    { riskId: 'risk-004', supplier: '优品工服有限公司', title: '交付时间延迟', level: '中风险', status: '核验中', amount: '¥56,900' },
    { riskId: 'risk-005', supplier: '明辉仓储用品有限公司', title: '部分发票信息缺失', level: '低风险', status: '待补充', amount: '¥18,500' },
    { riskId: 'risk-006', supplier: '恒达电子有限公司', title: '付款记录与订单日期异常', level: '已处理', status: '已关闭', amount: '¥42,300' }
  ];

  private isProcessedRisk(risk: RiskRecord): boolean {
    return risk.level === '已处理' || risk.status === '已处理' || risk.status === '已关闭';
  }

  private matchesSelectedFilter(risk: RiskRecord): boolean {
    if (this.selectedFilter === '全部') {
      return true;
    }
    if (this.selectedFilter === '高风险' || this.selectedFilter === '中风险') {
      return risk.level === this.selectedFilter;
    }
    if (this.selectedFilter === '待处理') {
      return risk.status === '待处理';
    }
    return this.isProcessedRisk(risk);
  }

  private matchesSearchKeyword(risk: RiskRecord): boolean {
    const keyword: string = this.searchKeyword.trim().toLowerCase();
    if (keyword === '') {
      return true;
    }
    return risk.title.toLowerCase().includes(keyword) ||
      risk.supplier.toLowerCase().includes(keyword) ||
      risk.riskId.toLowerCase().includes(keyword);
  }

  private getFilteredRisks(): RiskRecord[] {
    return this.risks.filter((risk: RiskRecord) => {
      return this.matchesSelectedFilter(risk) && this.matchesSearchKeyword(risk);
    });
  }

  private getOverviewCount(category: string): string {
    return this.getFilteredRisks().filter((risk: RiskRecord) => {
      if (category === '已处理') {
        return this.isProcessedRisk(risk);
      }
      return risk.level === category;
    }).length.toString();
  }

  private getLevelColor(level: string): string {
    if (level === '高风险') {
      return '#C2413A';
    }
    if (level === '中风险') {
      return '#B65E10';
    }
    if (level === '低风险') {
      return '#1769E0';
    }
    return '#17795B';
  }

  private getLevelBackground(level: string): string {
    if (level === '高风险') {
      return '#FCEAEA';
    }
    if (level === '中风险') {
      return '#FFF3DF';
    }
    if (level === '低风险') {
      return '#EAF2FF';
    }
    return '#E8F7F1';
  }

  private getStatusColor(status: string): string {
    if (status === '待处理') {
      return '#C2413A';
    }
    if (status === '核验中') {
      return '#B65E10';
    }
    if (status === '待补充') {
      return '#1769E0';
    }
    return '#17795B';
  }

  private openRiskDetail(riskId: string): void {
    this.navigationError = '';
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RiskDetailPage',
      params: { riskId: riskId }
    }).catch(() => {
      this.navigationError = '页面跳转失败，请稍后重试';
    });
  }

  @Builder
  OverviewCard(title: string, category: string, color: string) {
    Column({ space: 7 }) {
      Text(this.getOverviewCount(category)).fontSize(25).fontWeight(FontWeight.Bold).fontColor(color)
      Text(title).fontSize(13).fontColor('#667085')
    }
    .width('100%')
    .height(88)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
  }

  @Builder
  FilterChip(title: string) {
    Text(title)
      .fontSize(12)
      .fontWeight(this.selectedFilter === title ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.selectedFilter === title ? '#FFFFFF' : '#53627A')
      .height(36)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.selectedFilter === title ? '#1769E0' : '#EDF2F8')
      .borderRadius(18)
      .onClick(() => {
        this.selectedFilter = title;
      })
  }

  @Builder
  RiskCard(risk: RiskRecord) {
    Column({ space: 13 }) {
      Row({ space: 10 }) {
        Text('!')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getLevelColor(risk.level))
          .width(38)
          .height(38)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getLevelBackground(risk.level))
          .borderRadius(12)
        Column({ space: 5 }) {
          Text(risk.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#25324B')
            .width('100%')
          Text(risk.riskId).fontSize(12).fontColor('#7B879C').width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(risk.level)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getLevelColor(risk.level))
          .padding({ left: 9, right: 9, top: 5, bottom: 5 })
          .backgroundColor(this.getLevelBackground(risk.level))
          .borderRadius(12)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      Divider().strokeWidth(1).color('#EDF1F6')
      Row({ space: 8 }) {
        Text('供应商：').fontSize(12).fontColor('#98A2B3')
        Text(risk.supplier).fontSize(13).fontColor('#40506A').layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      Row() {
        Column({ space: 4 }) {
          Text('涉及金额').fontSize(11).fontColor('#98A2B3')
          Text(risk.amount).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#14213D')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(risk.status)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStatusColor(risk.status))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.getLevelBackground(risk.level))
          .borderRadius(12)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
    .onClick(() => {
      this.openRiskDetail(risk.riskId);
    })
  }

  build() {
    Column() {
      Row() {
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
        Text('风险中心')
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('搜索')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .width(58)
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor('#2C5289')
          .borderRadius(20)
          .onClick(() => {
            this.searchExpanded = !this.searchExpanded;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#0B2D5C')
      Scroll() {
        Column({ space: 22 }) {
          if (this.searchExpanded) {
            Row({ space: 8 }) {
              TextInput({ placeholder: '搜索风险标题、供应商或风险编号', text: this.searchKeyword })
                .fontSize(13)
                .fontColor('#40506A')
                .placeholderColor('#7B879C')
                .height(40)
                .layoutWeight(1)
                .backgroundColor('#EAF2FF')
                .onChange((value: string) => {
                  this.searchKeyword = value;
                })
              if (this.searchKeyword !== '') {
                Text('清空')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1769E0')
                  .height(40)
                  .padding({ left: 10, right: 10 })
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.searchKeyword = '';
                  })
              }
            }
            .width('100%')
            .padding({ left: 8, right: 8 })
            .backgroundColor('#EAF2FF')
            .borderRadius(12)
          }
          if (this.navigationError !== '') {
            Text(this.navigationError)
              .fontSize(13)
              .fontColor('#B54747')
              .width('100%')
              .padding({ left: 14, right: 14, top: 11, bottom: 11 })
              .backgroundColor('#FCEAEA')
              .borderRadius(12)
          }
          Column({ space: 12 }) {
            Text('数据概览').fontSize(19).fontWeight(FontWeight.Bold).fontColor('#14213D').width('100%')
            GridRow({ columns: { xs: 2, sm: 2, md: 4, lg: 4 }, gutter: { x: 12, y: 12 } }) {
              GridCol({ span: 1 }) { this.OverviewCard('高风险', '高风险', '#C2413A') }
              GridCol({ span: 1 }) { this.OverviewCard('中风险', '中风险', '#B65E10') }
              GridCol({ span: 1 }) { this.OverviewCard('低风险', '低风险', '#1769E0') }
              GridCol({ span: 1 }) { this.OverviewCard('已处理', '已处理', '#17795B') }
            }
            .width('100%')
          }
          .width('100%')
          Column({ space: 14 }) {
            Row({ space: 6 }) {
              this.FilterChip('全部')
              this.FilterChip('高风险')
              this.FilterChip('中风险')
              this.FilterChip('待处理')
              this.FilterChip('已处理')
            }
            .width('100%')
            Column({ space: 12 }) {
              if (this.getFilteredRisks().length === 0) {
                Text('未找到符合条件的风险')
                  .fontSize(14)
                  .fontColor('#7B879C')
                  .width('100%')
                  .height(96)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#FFFFFF')
                  .borderRadius(16)
              } else {
                ForEach(this.getFilteredRisks(), (risk: RiskRecord) => {
                  this.RiskCard(risk)
                }, (risk: RiskRecord) => risk.riskId)
              }
            }
            .width('100%')
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ maxWidth: 920 })
        .padding({ left: 16, right: 16, top: 18, bottom: 32 })
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
