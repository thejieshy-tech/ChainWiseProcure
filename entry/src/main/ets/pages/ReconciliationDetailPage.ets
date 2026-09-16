import { ProcurementDataSet, PurchaseOrderRecord } from '../data/DemoProcurementData';
import { resolveProcurementDataSet } from '../service/ProcurementBatchRepository';
import {
  ReconciliationIssue,
  ReconciliationRunResult,
  TaskReconciliationResult,
  runReconciliation
} from '../service/ReconciliationEngine';
interface ReconciliationRouteParams {
  taskId?: string;
  batchId?: string;
}

interface ReconciliationDetailTask {
  taskId: string;
  name: string;
  orderNo: string;
  supplier: string;
  itemName: string;
  quantity: number;
  unitPrice: number;
  totalAmount: number;
  amount: string;
  createDate: string;
  status: string;
  differenceCount: number;
}

@Entry
@Component
struct ReconciliationDetailPage {
  @State activeBatchId: string = 'demo-base';
  @State taskFound: boolean = false;
  @State currentTask: ReconciliationDetailTask = {
    taskId: '',
    name: '',
    orderNo: '',
    supplier: '',
    itemName: '',
    quantity: 0,
    unitPrice: 0,
    totalAmount: 0,
    amount: '¥0',
    createDate: '',
    status: '未找到',
    differenceCount: 0
  };
  @State displayedStatus: string = '未找到';
  @State differenceConfirmed: boolean = false;
  @State suggestionGenerated: boolean = false;
  @State generatedSuggestion: string = '';
  @State reconciliationProcessed: boolean = false;
  @State sequenceFeedback: string = '';
  @State reconciliationIssues: ReconciliationIssue[] = [];
  @State batchUnavailableMessage: string = '';

  private currentDataSet: ProcurementDataSet | null =
    resolveProcurementDataSet('demo-base');
  aboutToAppear(): void {
    let taskId: string | undefined = undefined;
    let routedBatchId: string = 'demo-base';

    try {
      const params: ReconciliationRouteParams =
        this.getUIContext().getRouter().getParams() as ReconciliationRouteParams;
      taskId = params.taskId;
      if (params.batchId !== undefined) {
        routedBatchId = params.batchId;
      }
    } catch {
      taskId = undefined;
      routedBatchId = 'demo-base';
    }

    this.activeBatchId = routedBatchId;
    const resolvedDataSet: ProcurementDataSet | null =
      resolveProcurementDataSet(this.activeBatchId);
    if (resolvedDataSet === null) {
      this.currentDataSet = null;
      this.setBatchUnavailable();
      return;
    }

    this.currentDataSet = resolvedDataSet;
    if (taskId === undefined) {
      this.setTaskNotFound();
      return;
    }

    const reconciliationResult: ReconciliationRunResult =
      runReconciliation(resolvedDataSet);
    const order: PurchaseOrderRecord | undefined = resolvedDataSet.purchaseOrders.find(
      (item: PurchaseOrderRecord) => item.taskId === taskId
    );
    const taskResult: TaskReconciliationResult | undefined = reconciliationResult.taskResults.find(
      (item: TaskReconciliationResult) => item.taskId === taskId
    );

    if (order === undefined || taskResult === undefined) {
      this.setTaskNotFound();
      return;
    }

    this.currentTask = {
      taskId: order.taskId,
      name: order.taskName,
      orderNo: order.poNumber,
      supplier: order.supplier,
      itemName: order.itemName,
      quantity: order.quantity,
      unitPrice: order.unitPrice,
      totalAmount: order.totalAmount,
      amount: this.formatCurrency(order.totalAmount),
      createDate: order.createdDate,
      status: taskResult.status,
      differenceCount: taskResult.issues.length
    };
    this.reconciliationIssues = taskResult.issues;
    this.taskFound = true;
    this.displayedStatus = taskResult.status;
  }

  private setBatchUnavailable(): void {
    this.taskFound = false;
    this.displayedStatus = '已失效';
    this.reconciliationIssues = [];
    this.batchUnavailableMessage = 'CSV批次已失效，请返回首页重新校验';
  }

  private setTaskNotFound(): void {
    this.taskFound = false;
    this.displayedStatus = '未找到';
    this.reconciliationIssues = [];
    this.batchUnavailableMessage = '';
  }

  private confirmDifference(): void {
    if (this.differenceConfirmed) {
      return;
    }
    this.differenceConfirmed = true;
    this.displayedStatus = '处理中';
    this.sequenceFeedback = '';
  }

  private generateHandlingSuggestion(): void {
    if (this.suggestionGenerated) {
      return;
    }
    this.suggestionGenerated = true;
    this.generatedSuggestion = '建议核对采购订单、发票和收货记录，并联系供应商确认差异原因。';
  }

  private markAsProcessed(): void {
    if (this.reconciliationProcessed) {
      return;
    }
    if (!this.differenceConfirmed) {
      this.sequenceFeedback = '请先确认差异';
      return;
    }
    this.reconciliationProcessed = true;
    this.displayedStatus = '已处理';
    this.sequenceFeedback = '';
  }

  private formatCurrency(amount: number): string {
    return '¥' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  private hasIssue(issueType: string): boolean {
    return this.reconciliationIssues.find(
      (item: ReconciliationIssue) => item.type === issueType
    ) !== undefined;
  }

  private hasInvoiceIssue(): boolean {
    return this.hasIssue('missing_invoice') ||
      this.hasIssue('invoice_quantity_difference') ||
      this.hasIssue('invoice_unit_price_difference') ||
      this.hasIssue('invoice_amount_difference');
  }

  private getAiAnalysisText(): string {
    if (this.reconciliationIssues.length === 0) {
      return '系统未发现明显差异，建议完成最终审核后归档。';
    }
    return '系统基于采购订单、发票、收货和付款记录发现' +
      this.reconciliationIssues.length.toString() +
      '项待处理问题。建议优先核对规则明细，并联系供应商补充或确认相关凭证。';
  }

  private getStatusBackground(status: string): string {
    if (status === '待处理' || status === '待补充材料') {
      return '#FFF3E6';
    }
    if (status === '对账中' || status === '处理中') {
      return '#EAF2FF';
    }
    if (status === '存在差异' || status === '未找到' || status === '已失效') {
      return '#FCEAEA';
    }
    return '#E8F7F1';
  }

  private getStatusColor(status: string): string {
    if (status === '待处理' || status === '待补充材料') {
      return '#B65E10';
    }
    if (status === '对账中' || status === '处理中') {
      return '#1769E0';
    }
    if (status === '存在差异' || status === '未找到' || status === '已失效') {
      return '#B54747';
    }
    return '#17795B';
  }

  private getProgressStatus(step: string): string {
    if (this.reconciliationIssues.length === 0 || step === '采购订单') {
      return '已匹配';
    }
    if (step === '发票') {
      if (this.hasIssue('missing_invoice')) {
        return '待补充';
      }
      return this.hasInvoiceIssue() ? '存在差异' : '已匹配';
    }
    if (this.hasIssue('missing_payment')) {
      return '待补充';
    }
    return this.hasIssue('payment_amount_difference') ? '存在差异' : '已匹配';
  }

  private getProgressColor(status: string): string {
    if (status === '已匹配') {
      return '#17795B';
    }
    if (status === '待补充') {
      return '#B65E10';
    }
    if (status === '存在差异') {
      return '#B54747';
    }
    return '#1769E0';
  }

  private getProgressBackground(status: string): string {
    if (status === '已匹配') {
      return '#E8F7F1';
    }
    if (status === '待补充') {
      return '#FFF3E6';
    }
    if (status === '存在差异') {
      return '#FCEAEA';
    }
    return '#EAF2FF';
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#14213D')
      .width('100%')
  }

  @Builder
  InfoRow(label: string, value: string, valueColor: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(13)
        .fontColor('#7B879C')
        .width(88)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(valueColor)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CurrentStatusInfoRow() {
    Row({ space: 12 }) {
      Text('当前状态')
        .fontSize(13)
        .fontColor('#7B879C')
        .width(88)
      Text(this.displayedStatus)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getStatusColor(this.displayedStatus))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ProgressItem(step: string) {
    Column({ space: 8 }) {
      Text(step)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#25324B')
        .maxLines(1)
      Text(this.getProgressStatus(step))
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getProgressColor(this.getProgressStatus(step)))
        .padding({ left: 8, right: 8, top: 5, bottom: 5 })
        .backgroundColor(this.getProgressBackground(this.getProgressStatus(step)))
        .borderRadius(12)
    }
    .layoutWeight(1)
    .height(78)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F8FAFD')
    .borderRadius(12)
  }

  @Builder
  RuleIssueCard(item: ReconciliationIssue) {
    Column({ space: 10 }) {
      Text(item.title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#25324B')
        .width('100%')
      Row({ space: 8 }) {
        Text('规则说明：')
          .fontSize(12)
          .fontColor('#7B879C')
        Text(item.detail)
          .fontSize(13)
          .fontColor('#40506A')
          .layoutWeight(1)
      }
      .width('100%')
      Row({ space: 8 }) {
        Text('风险等级：')
          .fontSize(12)
          .fontColor('#7B879C')
        Text(item.severity)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.severity === '高' ? '#B54747' : '#B65E10')
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 7, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
  }

  @Builder
  NoDifferenceCard() {
    Column({ space: 9 }) {
      Text('暂无差异')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17795B')
        .width('100%')
      Text('订单、发票、收货及付款记录已匹配，未发现差异。')
        .fontSize(13)
        .fontColor('#53627A')
        .lineHeight(21)
        .width('100%')
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 7, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
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
        Text('对账详情')
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(this.displayedStatus)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStatusColor(this.displayedStatus))
          .width(58)
          .height(30)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getStatusBackground(this.displayedStatus))
          .borderRadius(15)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#0B2D5C')

      Scroll() {
        Column({ space: 22 }) {
          if (this.batchUnavailableMessage !== '') {
            Column({ space: 10 }) {
              Text(this.batchUnavailableMessage)
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor('#B54747')
                .width('100%')
                .textAlign(TextAlign.Center)
              Text('内存中的CSV采购数据已不可用，本页面不会回退显示基础批次。')
                .fontSize(13)
                .fontColor('#667085')
                .lineHeight(21)
                .width('100%')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FCEAEA')
            .borderRadius(16)
          } else if (!this.taskFound) {
            Column({ space: 10 }) {
              Text('未找到对账任务')
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor('#B54747')
                .width('100%')
                .textAlign(TextAlign.Center)
              Text('未找到与当前任务编号和数据批次匹配的采购记录，请返回任务列表后重试。')
                .fontSize(13)
                .fontColor('#667085')
                .lineHeight(21)
                .width('100%')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FCEAEA')
            .borderRadius(16)
          }
          if (this.taskFound) {
          Column({ space: 14 }) {
            this.SectionTitle('任务基本信息')
            Column({ space: 13 }) {
              this.InfoRow('任务名称', this.currentTask.name, '#40506A')
              Divider().strokeWidth(1).color('#EDF1F6')
              this.InfoRow('采购订单号', this.currentTask.orderNo, '#40506A')
              this.InfoRow('供应商名称', this.currentTask.supplier, '#40506A')
              this.InfoRow('商品名称', this.currentTask.itemName, '#40506A')
              this.InfoRow('采购数量', this.currentTask.quantity.toString(), '#40506A')
              this.InfoRow('采购单价', this.formatCurrency(this.currentTask.unitPrice), '#40506A')
              this.InfoRow('总金额', this.currentTask.amount, '#14213D')
              this.InfoRow('创建日期', this.currentTask.createDate, '#40506A')
              this.CurrentStatusInfoRow()
              this.InfoRow('差异数量', this.currentTask.differenceCount.toString() + '项',
                this.currentTask.differenceCount > 0 ? '#B54747' : '#17795B')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
          }
          .width('100%')

          Column({ space: 14 }) {
            this.SectionTitle('对账进度')
            Row({ space: 8 }) {
              this.ProgressItem('采购订单')
              this.ProgressItem('发票')
              this.ProgressItem('付款记录')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
          }
          .width('100%')

          Column({ space: 14 }) {
            this.SectionTitle('差异明细')
            if (this.reconciliationIssues.length === 0) {
              this.NoDifferenceCard()
            } else {
              ForEach(this.reconciliationIssues, (item: ReconciliationIssue) => {
                this.RuleIssueCard(item)
              }, (item: ReconciliationIssue) => item.type)
            }
          }
          .width('100%')

          Column({ space: 12 }) {
            this.SectionTitle('AI分析建议')
            Text(this.getAiAnalysisText())
              .fontSize(14)
              .fontColor('#40506A')
              .lineHeight(23)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#EAF2FF')
          .borderRadius(16)
          .border({ width: 1, color: '#C8DAF5' })

          if (this.suggestionGenerated) {
            Column({ space: 8 }) {
              Text('生成的处理建议')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#25324B')
                .width('100%')
              Text(this.generatedSuggestion)
                .fontSize(14)
                .fontColor('#40506A')
                .lineHeight(23)
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 9, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
          }

          if (this.differenceConfirmed || this.suggestionGenerated || this.reconciliationProcessed) {
            Column({ space: 6 }) {
              if (this.differenceConfirmed) {
                Text('差异已确认，进入处理流程')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#17795B')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              if (this.suggestionGenerated) {
                Text('处理建议已生成')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#17795B')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              if (this.reconciliationProcessed) {
                Text('该对账差异已处理完成')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#17795B')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .padding({ top: 11, bottom: 11, left: 12, right: 12 })
            .backgroundColor('#E8F7F1')
            .borderRadius(12)
          }

          if (this.sequenceFeedback !== '') {
            Text(this.sequenceFeedback)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#B54747')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 11, bottom: 11, left: 12, right: 12 })
              .backgroundColor('#FCEAEA')
              .borderRadius(12)
          }
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

      if (this.taskFound) {
        GridRow({
        columns: { xs: 1, sm: 1, md: 3, lg: 3 },
        gutter: { x: 8, y: 10 }
      }) {
        GridCol({ span: 1 }) {
          Button(this.differenceConfirmed ? '差异已确认' : '确认差异')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1769E0')
            .width('100%')
            .height(44)
            .backgroundColor('#EAF2FF')
            .borderRadius(22)
            .enabled(!this.differenceConfirmed)
            .onClick(() => {
              this.confirmDifference();
            })
        }
        GridCol({ span: 1 }) {
          Button(this.suggestionGenerated ? '建议已生成' : '生成处理建议')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width('100%')
            .height(44)
            .backgroundColor('#1769E0')
            .borderRadius(22)
            .enabled(!this.suggestionGenerated)
            .onClick(() => {
              this.generateHandlingSuggestion();
            })
        }
        GridCol({ span: 1 }) {
          Button(this.reconciliationProcessed ? '已处理' : '标记已处理')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width('100%')
            .height(44)
            .backgroundColor('#17795B')
            .borderRadius(22)
            .enabled(!this.reconciliationProcessed)
            .onClick(() => {
              this.markAsProcessed();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
        .shadow({ radius: 8, color: '#160F2D4A', offsetX: 0, offsetY: -2 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F7FB')
  }
}
