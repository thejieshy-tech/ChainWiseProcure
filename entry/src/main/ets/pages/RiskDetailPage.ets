interface RiskRouteParams {
  riskId?: string;
}

interface RiskDetailRecord {
  riskId: string;
  supplier: string;
  title: string;
  level: string;
  status: string;
  amount: string;
  foundDate: string;
  description: string;
  purchaseEvidence: string;
  invoiceEvidence: string;
  paymentEvidence: string;
  aiAnalysis: string;
  suggestions: string[];
}

@Entry
@Component
struct RiskDetailPage {
  @State currentRisk: RiskDetailRecord = {
    riskId: 'risk-001', supplier: '华东办公设备有限公司', title: '办公椅数量与发票不一致', level: '高风险', status: '待处理', amount: '¥126,800', foundDate: '2026-07-16',
    description: '采购订单记录办公椅20件，供应商发票仅记录18件，存在2件数量差异。系统同时检测到发票单价高于采购订单约定单价。',
    purchaseEvidence: '办公椅20件，单价¥1,280', invoiceEvidence: '办公椅18件，单价¥1,350', paymentEvidence: '已付款¥120,000',
    aiAnalysis: '系统判断该风险同时涉及数量差异、单价变化和付款金额异常，建议暂缓支付剩余款项，优先联系供应商核对发票和实际收货记录。',
    suggestions: ['核对仓库入库记录', '联系供应商确认缺少数量', '要求供应商提供调价说明', '财务暂缓支付剩余金额']
  };
  @State displayedStatus: string = '待处理';
  @State riskConfirmed: boolean = false;
  @State checkTaskCreated: boolean = false;
  @State checkTaskId: string = '';
  @State aiSuggestionAdopted: boolean = false;

  private readonly risks: RiskDetailRecord[] = [
    {
      riskId: 'risk-001', supplier: '华东办公设备有限公司', title: '办公椅数量与发票不一致', level: '高风险', status: '待处理', amount: '¥126,800', foundDate: '2026-07-16',
      description: '采购订单记录办公椅20件，供应商发票仅记录18件，存在2件数量差异。系统同时检测到发票单价高于采购订单约定单价。',
      purchaseEvidence: '办公椅20件，单价¥1,280', invoiceEvidence: '办公椅18件，单价¥1,350', paymentEvidence: '已付款¥120,000',
      aiAnalysis: '系统判断该风险同时涉及数量差异、单价变化和付款金额异常，建议暂缓支付剩余款项，优先联系供应商核对发票和实际收货记录。',
      suggestions: ['核对仓库入库记录', '联系供应商确认缺少数量', '要求供应商提供调价说明', '财务暂缓支付剩余金额']
    },
    {
      riskId: 'risk-002', supplier: '远航服务器科技有限公司', title: '服务器配件单价异常上涨', level: '高风险', status: '待处理', amount: '¥286,000', foundDate: '2026-07-15',
      description: '本次服务器配件报价较最近三次采购均价明显上涨，且供应商未随发票提供价格调整说明。',
      purchaseEvidence: '服务器内存40条，合同单价¥6,850', invoiceEvidence: '服务器内存40条，发票单价¥7,150', paymentEvidence: '尚未付款',
      aiAnalysis: '系统识别到短期单价异常上涨，建议在付款前复核合同调价条款，并补充同规格配件的市场询价记录。',
      suggestions: ['复核合同调价条款', '获取供应商调价说明', '补充同类产品询价', '审批完成前暂缓付款']
    },
    {
      riskId: 'risk-003', supplier: '新城物流有限公司', title: '运输费用超过合同约定', level: '中风险', status: '核验中', amount: '¥38,600', foundDate: '2026-07-14',
      description: '本次运输费用高于合同约定金额，账单中新增了未提前确认的等待费和装卸附加费。',
      purchaseEvidence: '合同运输费用¥35,000', invoiceEvidence: '运输服务发票¥38,600', paymentEvidence: '已预付¥20,000',
      aiAnalysis: '系统判断超额部分主要来自附加费用，建议核验运输签收单和附加费用审批记录后再结算尾款。',
      suggestions: ['核对运输签收单', '确认附加费用审批记录', '联系物流方说明差额', '核验完成后结算尾款']
    },
    {
      riskId: 'risk-004', supplier: '优品工服有限公司', title: '交付时间延迟', level: '中风险', status: '核验中', amount: '¥56,900', foundDate: '2026-07-13',
      description: '员工工服未在合同约定日期前完成交付，当前已延迟5天，可能影响后续统一发放安排。',
      purchaseEvidence: '合同约定2026-07-08交付', invoiceEvidence: '发票已于2026-07-07开具', paymentEvidence: '已支付预付款¥28,450',
      aiAnalysis: '系统发现开票日期早于实际交付且交期已逾期，建议确认最新到货计划并依据合同评估延期责任。',
      suggestions: ['确认最新交付日期', '要求供应商说明延期原因', '保留延期沟通记录', '评估合同违约条款']
    },
    {
      riskId: 'risk-005', supplier: '明辉仓储用品有限公司', title: '部分发票信息缺失', level: '低风险', status: '待补充', amount: '¥18,500', foundDate: '2026-07-12',
      description: '供应商提交的部分发票缺少完整规格型号和采购订单关联信息，暂时无法完成单据匹配。',
      purchaseEvidence: '仓储用品订单金额¥18,500', invoiceEvidence: '发票缺少规格型号及订单号', paymentEvidence: '尚未付款',
      aiAnalysis: '系统判断当前风险主要为单据信息完整性问题，建议补齐发票明细后重新执行对账。',
      suggestions: ['联系供应商补充发票信息', '核对采购订单编号', '确认商品规格型号', '资料补齐后重新对账']
    },
    {
      riskId: 'risk-006', supplier: '恒达电子有限公司', title: '付款记录与订单日期异常', level: '已处理', status: '已关闭', amount: '¥42,300', foundDate: '2026-07-10',
      description: '付款记录日期早于采购订单审批日期，复核后确认该笔款项为已批准的紧急采购预付款。',
      purchaseEvidence: '采购订单于2026-07-09审批', invoiceEvidence: '发票于2026-07-10开具', paymentEvidence: '预付款于2026-07-08支付',
      aiAnalysis: '系统已结合紧急采购审批记录完成复核，相关日期差异具有有效业务依据，当前风险已关闭。',
      suggestions: ['归档紧急采购审批单', '关联付款凭证与订单', '保留复核说明', '后续采购提前完成订单审批']
    }
  ];

  aboutToAppear(): void {
    try {
      const params: RiskRouteParams = this.getUIContext().getRouter().getParams() as RiskRouteParams;
      if (params.riskId !== undefined) {
        this.currentRisk = this.findRisk(params.riskId);
      }
    } catch {
      this.currentRisk = this.risks[0];
    }
    this.displayedStatus = this.currentRisk.status;
  }

  private confirmRisk(): void {
    if (this.riskConfirmed) {
      return;
    }
    this.riskConfirmed = true;
    this.displayedStatus = '处理中';
  }

  private createCheckTask(): void {
    if (this.checkTaskCreated) {
      return;
    }
    this.checkTaskCreated = true;
    this.checkTaskId = 'CHECK-20260717-001';
  }

  private adoptAiSuggestion(): void {
    if (this.aiSuggestionAdopted) {
      return;
    }
    this.aiSuggestionAdopted = true;
  }

  private findRisk(riskId: string): RiskDetailRecord {
    const risk: RiskDetailRecord | undefined = this.risks.find(
      (item: RiskDetailRecord) => item.riskId === riskId
    );
    return risk === undefined ? this.risks[0] : risk;
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
    if (status === '核验中' || status === '处理中') {
      return '#B65E10';
    }
    if (status === '待补充') {
      return '#1769E0';
    }
    return '#17795B';
  }

  private getStatusBackground(status: string): string {
    if (status === '待处理') {
      return '#FCEAEA';
    }
    if (status === '核验中' || status === '处理中') {
      return '#FFF3DF';
    }
    if (status === '待补充') {
      return '#EAF2FF';
    }
    return '#E8F7F1';
  }

  @Builder
  SectionTitle(title: string) {
    Text(title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#14213D').width('100%')
  }

  @Builder
  InfoRow(label: string, value: string, color: string) {
    Row({ space: 12 }) {
      Text(label).fontSize(13).fontColor('#7B879C').width(80)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  CurrentStatusInfoRow() {
    Row({ space: 12 }) {
      Text('当前状态').fontSize(13).fontColor('#7B879C').width(80)
      Text(this.displayedStatus)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getStatusColor(this.displayedStatus))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  EvidenceRow(label: string, value: string, color: string) {
    Column({ space: 7 }) {
      Text(label).fontSize(12).fontWeight(FontWeight.Medium).fontColor(color).width('100%')
      Text(value).fontSize(14).fontColor('#40506A').lineHeight(22).width('100%')
    }
    .width('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#F8FAFD')
    .borderRadius(12)
  }

  @Builder
  SuggestionItem(suggestion: string) {
    Row({ space: 10 }) {
      Text('✓')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1769E0')
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .backgroundColor('#EAF2FF')
        .borderRadius(12)
      Text(suggestion).fontSize(14).fontColor('#40506A').lineHeight(22).layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Column({ space: 10 }) {
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
          Text('风险详情')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('').width(58)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Row({ space: 10 }) {
          Text(this.currentRisk.level)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getLevelColor(this.currentRisk.level))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.getLevelBackground(this.currentRisk.level))
            .borderRadius(14)
          Text(this.displayedStatus)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getStatusColor(this.displayedStatus))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.getStatusBackground(this.displayedStatus))
            .borderRadius(14)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor('#0B2D5C')
      Scroll() {
        Column({ space: 22 }) {
          Column({ space: 14 }) {
            this.SectionTitle('风险基本信息')
            Column({ space: 13 }) {
              this.InfoRow('风险标题', this.currentRisk.title, '#25324B')
              Divider().strokeWidth(1).color('#EDF1F6')
              this.InfoRow('供应商', this.currentRisk.supplier, '#40506A')
              this.InfoRow('风险编号', this.currentRisk.riskId, '#40506A')
              this.InfoRow('采购金额', this.currentRisk.amount, '#14213D')
              this.InfoRow('发现日期', this.currentRisk.foundDate, '#40506A')
              this.CurrentStatusInfoRow()
              this.InfoRow('风险等级', this.currentRisk.level, this.getLevelColor(this.currentRisk.level))
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
          }
          .width('100%')
          Column({ space: 12 }) {
            this.SectionTitle('风险说明')
            Text(this.currentRisk.description).fontSize(14).fontColor('#40506A').lineHeight(23).width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
          Column({ space: 12 }) {
            this.SectionTitle('证据对比')
            this.EvidenceRow('采购订单', this.currentRisk.purchaseEvidence, '#1769E0')
            this.EvidenceRow('发票记录', this.currentRisk.invoiceEvidence, '#C2413A')
            this.EvidenceRow('付款记录', this.currentRisk.paymentEvidence, '#B65E10')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
          Column({ space: 12 }) {
            this.SectionTitle('AI风险分析')
            Text(this.currentRisk.aiAnalysis).fontSize(14).fontColor('#40506A').lineHeight(23).width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#EAF2FF')
          .borderRadius(16)
          .border({ width: 1, color: '#C8DAF5' })
          Column({ space: 14 }) {
            this.SectionTitle('处理建议')
            ForEach(this.currentRisk.suggestions, (suggestion: string) => {
              this.SuggestionItem(suggestion)
            }, (suggestion: string) => suggestion)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
          if (this.riskConfirmed || this.checkTaskCreated || this.aiSuggestionAdopted) {
            Column({ space: 6 }) {
              if (this.riskConfirmed) {
                Text('已确认风险，进入处理流程')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#17795B')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              if (this.checkTaskCreated) {
                Text('核查任务已创建')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#17795B')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                Text('任务编号：' + this.checkTaskId)
                  .fontSize(12)
                  .fontColor('#40506A')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              if (this.aiSuggestionAdopted) {
                Text('已采纳AI建议')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#17795B')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 11, bottom: 11 })
            .backgroundColor('#E8F7F1')
            .borderRadius(12)
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: 920 })
        .padding({ left: 16, right: 16, top: 18, bottom: 28 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      GridRow({
        columns: { xs: 1, sm: 1, md: 3, lg: 3 },
        gutter: { x: 8, y: 10 }
      }) {
        GridCol({ span: 1 }) {
          Button(this.riskConfirmed ? '风险已确认' : '确认风险')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1769E0')
            .width('100%')
            .height(44)
            .backgroundColor('#EAF2FF')
            .borderRadius(22)
            .enabled(!this.riskConfirmed)
            .onClick(() => {
              this.confirmRisk();
            })
        }
        GridCol({ span: 1 }) {
          Button(this.checkTaskCreated ? '任务已创建' : '创建核查任务')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width('100%')
            .height(44)
            .backgroundColor('#B65E10')
            .borderRadius(22)
            .enabled(!this.checkTaskCreated)
            .onClick(() => {
              this.createCheckTask();
            })
        }
        GridCol({ span: 1 }) {
          Button(this.aiSuggestionAdopted ? '建议已采纳' : '采纳AI建议')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.aiSuggestionAdopted ? '#17795B' : '#FFFFFF')
            .width('100%')
            .height(44)
            .backgroundColor(this.aiSuggestionAdopted ? '#E8F7F1' : '#17795B')
            .borderRadius(22)
            .border({ width: this.aiSuggestionAdopted ? 1 : 0, color: '#A8DCCB' })
            .enabled(!this.aiSuggestionAdopted)
            .onClick(() => {
              this.adoptAiSuggestion();
            })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 8, color: '#160F2D4A', offsetX: 0, offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F7FB')
  }
}
