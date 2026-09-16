import { ProcurementDataSet, PurchaseOrderRecord } from '../data/DemoProcurementData';
import { resolveProcurementDataSet } from '../service/ProcurementBatchRepository';
import {
  ReconciliationRunResult,
  TaskReconciliationResult,
  runReconciliation
} from '../service/ReconciliationEngine';

interface ReconciliationListRouteParams {
  batchId?: string;
}

interface ReconciliationTask {
  taskId: string;
  name: string;
  orderNo: string;
  supplier: string;
  amount: string;
  createDate: string;
  status: string;
  differenceCount: number;
}

@Entry
@Component
struct ReconciliationListPage {
  @State selectedStatus: string = '全部';
  @State searchKeyword: string = '';
  @State showSearchHint: boolean = false;
  @State navigationError: string = '';
  @State analysisPanelVisible: boolean = false;
  @State analysisProgress: number = 25;
  @State analysisStep: number = 0;
  @State analysisCompleted: boolean = false;
  @State analysisFeedback: string = '';
  @State analysisTotalCount: number = 0;
  @State analysisDifferenceCount: number = 0;
  @State analysisCompletedCount: number = 0;
  @State analysisMissingMaterialCount: number = 0;
  @State analysisAiConclusion: string = '';
  @State reconciliationEngineExecuted: boolean = false;
  @State activeBatchId: string = 'demo-base';
  @State tasks: ReconciliationTask[] = [];
  @State batchUnavailableMessage: string = '';

  private currentDataSet: ProcurementDataSet | null =
    resolveProcurementDataSet('demo-base');
  private dataInitialized: boolean = false;

  aboutToAppear(): void {
    if (this.dataInitialized) {
      return;
    }

    let routedBatchId: string = 'demo-base';
    try {
      const params: ReconciliationListRouteParams =
        this.getUIContext().getRouter().getParams() as ReconciliationListRouteParams;
      if (params.batchId !== undefined) {
        routedBatchId = params.batchId;
      }
    } catch {
      routedBatchId = 'demo-base';
    }

    this.activeBatchId = routedBatchId;
    const resolvedDataSet: ProcurementDataSet | null =
      resolveProcurementDataSet(this.activeBatchId);
    if (resolvedDataSet === null) {
      this.currentDataSet = null;
      this.tasks = [];
      this.batchUnavailableMessage = 'CSV批次已失效，请返回首页重新校验';
      this.analysisPanelVisible = false;
      this.dataInitialized = true;
      return;
    }

    this.currentDataSet = resolvedDataSet;
    this.tasks = this.createTasks(resolvedDataSet);
    this.batchUnavailableMessage = '';
    this.dataInitialized = true;
  }

  private createTasks(dataSet: ProcurementDataSet): ReconciliationTask[] {
    const generatedTasks: ReconciliationTask[] = [];
    const purchaseOrders: PurchaseOrderRecord[] = dataSet.purchaseOrders;

    for (let index: number = 0; index < purchaseOrders.length; index++) {
      const order: PurchaseOrderRecord = purchaseOrders[index];
      const task: ReconciliationTask = {
        taskId: order.taskId,
        name: order.taskName,
        orderNo: order.poNumber,
        supplier: order.supplier,
        amount: this.formatCurrency(order.totalAmount),
        createDate: order.createdDate,
        status: '待处理',
        differenceCount: 0
      };
      generatedTasks.push(task);
    }

    return generatedTasks;
  }

  private applyReconciliationResults(result: ReconciliationRunResult): void {
    const updatedTasks: ReconciliationTask[] = [];

    for (let index: number = 0; index < this.tasks.length; index++) {
      const task: ReconciliationTask = this.tasks[index];
      const taskResult: TaskReconciliationResult | undefined = result.taskResults.find(
        (item: TaskReconciliationResult) => item.taskId === task.taskId
      );
      if (taskResult === undefined) {
        updatedTasks.push(task);
        continue;
      }
      const updatedTask: ReconciliationTask = {
        taskId: task.taskId,
        name: task.name,
        orderNo: task.orderNo,
        supplier: task.supplier,
        amount: task.amount,
        createDate: task.createDate,
        status: taskResult.status,
        differenceCount: taskResult.issues.length
      };
      updatedTasks.push(updatedTask);
    }

    this.tasks = updatedTasks;
    this.selectedStatus = '全部';
  }

  private formatCurrency(amount: number): string {
    return '¥' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  private getFilteredTasks(): ReconciliationTask[] {
    let filteredTasks: ReconciliationTask[] = this.tasks;
    if (this.selectedStatus !== '全部') {
      filteredTasks = this.tasks.filter((task: ReconciliationTask) => task.status === this.selectedStatus);
    }

    const normalizedKeyword: string = this.searchKeyword.trim().toLowerCase();
    if (normalizedKeyword === '') {
      return filteredTasks;
    }

    return filteredTasks.filter((task: ReconciliationTask) =>
      task.name.toLowerCase().includes(normalizedKeyword) ||
      task.supplier.toLowerCase().includes(normalizedKeyword) ||
      task.orderNo.toLowerCase().includes(normalizedKeyword)
    );
  }

  private getTaskCountByStatus(status: string): string {
    return this.tasks.filter((task: ReconciliationTask) => task.status === status).length.toString();
  }
  private openAnalysisPanel(): void {
    if (this.currentDataSet === null) {
      this.analysisPanelVisible = false;
      return;
    }
    this.analysisPanelVisible = true;
  }

  private closeAnalysisPanel(): void {
    this.analysisPanelVisible = false;
  }

  private continueAnalysis(): void {
    const dataSet: ProcurementDataSet | null = this.currentDataSet;
    if (this.analysisCompleted || this.analysisStep >= 3 || dataSet === null) {
      return;
    }
    this.analysisStep = this.analysisStep + 1;
    this.analysisProgress = (this.analysisStep + 1) * 25;
    if (this.analysisProgress === 100) {
      this.analysisCompleted = true;
      if (!this.reconciliationEngineExecuted) {
        const reconciliationResult: ReconciliationRunResult =
          runReconciliation(dataSet);
        this.analysisTotalCount = reconciliationResult.summary.totalCount;
        this.analysisDifferenceCount = reconciliationResult.summary.differenceCount;
        this.analysisCompletedCount = reconciliationResult.summary.completedCount;
        this.analysisMissingMaterialCount = reconciliationResult.summary.missingMaterialCount;
        this.analysisAiConclusion = reconciliationResult.summary.aiConclusion;
        this.analysisFeedback = '已完成' + this.analysisTotalCount.toString() + '条采购任务的智能核对';
        this.applyReconciliationResults(reconciliationResult);
        this.reconciliationEngineExecuted = true;
      }
    }
  }

  private getAnalysisStepTitle(): string {
    if (this.analysisStep === 0) {
      return '正在读取采购订单';
    }
    if (this.analysisStep === 1) {
      return '正在匹配发票记录';
    }
    if (this.analysisStep === 2) {
      return '正在核对收货与付款信息';
    }
    return '生成AI对账结论';
  }

  private getAnalysisStepDescription(): string {
    if (this.analysisStep === 0) {
      return '正在校验订单编号、供应商及金额字段';
    }
    if (this.analysisStep === 1) {
      return '正在关联发票号码、开票金额及供应商信息';
    }
    if (this.analysisStep === 2) {
      return '正在比对收货数量、付款状态及时间记录';
    }
    return '正在汇总差异项并生成处理建议';
  }

  private getStatusBackground(status: string): string {
    if (status === '待处理' || status === '待补充材料') {
      return '#FFF3E6';
    }
    if (status === '对账中') {
      return '#EAF2FF';
    }
    if (status === '存在差异') {
      return '#FCEAEA';
    }
    return '#E8F7F1';
  }

  private getStatusColor(status: string): string {
    if (status === '待处理' || status === '待补充材料') {
      return '#B65E10';
    }
    if (status === '对账中') {
      return '#1769E0';
    }
    if (status === '存在差异') {
      return '#B54747';
    }
    return '#17795B';
  }

  private openTaskDetail(taskId: string): void {
    this.navigationError = '';
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ReconciliationDetailPage',
      params: {
        taskId: taskId,
        batchId: this.activeBatchId
      }
    }).catch(() => {
      this.navigationError = '页面跳转失败，请稍后重试';
    });
  }
  @Builder
  AnalysisResultItem(title: string, value: string, accentColor: string) {
    Column({ space: 6 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(accentColor)
      Text(title)
        .fontSize(12)
        .fontColor('#667085')
    }
    .width('100%')
    .height(74)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F8FAFD')
    .borderRadius(12)
  }

  @Builder
  AnalysisPanel() {
    Column({ space: 16 }) {
      Row() {
        Text(this.analysisCompleted ? '对账分析完成' : 'AI智能对账')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#14213D')
          .layoutWeight(1)
        Text(this.analysisProgress.toString() + '%')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.analysisCompleted ? '#17795B' : '#1769E0')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Progress({ value: this.analysisProgress, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(10)
        .color(this.analysisCompleted ? '#17795B' : '#1769E0')
        .backgroundColor('#DCE7F5')
        .borderRadius(5)

      Column({ space: 6 }) {
        Text('当前步骤：' + this.getAnalysisStepTitle())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#25324B')
        Text(this.getAnalysisStepDescription())
          .fontSize(13)
          .fontColor('#667085')
          .lineHeight(20)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.analysisCompleted) {
        Text(this.analysisFeedback)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#17795B')
          .width('100%')
          .padding({ left: 14, right: 14, top: 11, bottom: 11 })
          .backgroundColor('#E8F7F1')
          .borderRadius(12)

        Column({ space: 10 }) {
          Text('结果概览')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#25324B')
            .width('100%')
          GridRow({
            columns: { xs: 2, sm: 2, md: 4, lg: 4 },
            gutter: { x: 10, y: 10 }
          }) {
            GridCol({ span: 1 }) {
              this.AnalysisResultItem('核对任务', this.analysisTotalCount.toString() + '条', '#14213D')
            }
            GridCol({ span: 1 }) {
              this.AnalysisResultItem('发现差异', this.analysisDifferenceCount.toString() + '条', '#B54747')
            }
            GridCol({ span: 1 }) {
              this.AnalysisResultItem('核对完成', this.analysisCompletedCount.toString() + '条', '#17795B')
            }
            GridCol({ span: 1 }) {
              this.AnalysisResultItem('待补充材料', this.analysisMissingMaterialCount.toString() + '条', '#B65E10')
            }
          }
          .width('100%')
        }
        .width('100%')

        Column({ space: 7 }) {
          Text('AI结论')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#25324B')
          Text(this.analysisAiConclusion)
            .fontSize(13)
            .fontColor('#53627A')
            .lineHeight(21)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(14)
        .backgroundColor('#FFF7E8')
        .borderRadius(12)
      }

      Row({ space: 10 }) {
        Button(this.analysisCompleted ? '关闭结果' : '取消')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1769E0')
          .layoutWeight(1)
          .height(42)
          .backgroundColor('#EAF2FF')
          .borderRadius(21)
          .onClick(() => {
            this.closeAnalysisPanel();
          })
        Button(this.analysisCompleted ? '分析已完成' : '继续分析')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.analysisCompleted ? '#17795B' : '#FFFFFF')
          .layoutWeight(1)
          .height(42)
          .backgroundColor(this.analysisCompleted ? '#E8F7F1' : '#1769E0')
          .borderRadius(21)
          .enabled(!this.analysisCompleted)
          .onClick(() => {
            this.continueAnalysis();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .shadow({ radius: 12, color: '#160F2D4A', offsetX: 0, offsetY: 4 })
  }

  @Builder
  OverviewCard(title: string, value: string, accentColor: string) {
    Column({ space: 8 }) {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(accentColor)
      Text(title)
        .fontSize(12)
        .fontColor('#667085')
    }
    .width('100%')
    .height(86)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
  }

  @Builder
  FilterChip(title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(this.selectedStatus === title ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.selectedStatus === title ? '#FFFFFF' : '#53627A')
      .height(36)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.selectedStatus === title ? '#1769E0' : '#EDF2F8')
      .borderRadius(18)
      .onClick(() => {
        this.selectedStatus = title;
      })
  }

  @Builder
  TaskCard(task: ReconciliationTask) {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Column({ space: 5 }) {
          Text(task.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#25324B')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(task.orderNo)
            .fontSize(12)
            .fontColor('#7B879C')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(task.status)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStatusColor(task.status))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.getStatusBackground(task.status))
          .borderRadius(12)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Divider()
        .strokeWidth(1)
        .color('#EDF1F6')

      Column({ space: 9 }) {
        Row() {
          Text('供应商名称')
            .fontSize(12)
            .fontColor('#98A2B3')
            .width(76)
          Text(task.supplier)
            .fontSize(13)
            .fontColor('#40506A')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')

        Row() {
          Text('创建日期')
            .fontSize(12)
            .fontColor('#98A2B3')
            .width(76)
          Text(task.createDate)
            .fontSize(13)
            .fontColor('#40506A')
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')

      Row() {
        Column({ space: 4 }) {
          Text('含税金额')
            .fontSize(11)
            .fontColor('#98A2B3')
          Text(task.amount)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#14213D')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(task.differenceCount.toString() + '项差异')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(task.differenceCount > 0 ? '#B54747' : '#17795B')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(task.differenceCount > 0 ? '#FCEAEA' : '#E8F7F1')
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
      this.openTaskDetail(task.taskId);
    })  }

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

        Text('对账任务')
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
            this.showSearchHint = !this.showSearchHint;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#0B2D5C')

      Scroll() {
        Column({ space: 22 }) {
          if (this.showSearchHint) {
            TextInput({
              text: this.searchKeyword,
              placeholder: '搜索任务、供应商或采购订单号'
            })
              .fontSize(14)
              .fontColor('#40506A')
              .placeholderColor('#98A2B3')
              .width('100%')
              .height(44)
              .padding({ left: 14, right: 14 })
              .backgroundColor('#EAF2FF')
              .borderRadius(12)
              .onChange((value: string) => {
                this.searchKeyword = value;
              })
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
          if (this.batchUnavailableMessage !== '') {
            Text(this.batchUnavailableMessage)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#B54747')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ left: 14, right: 14, top: 13, bottom: 13 })
              .backgroundColor('#FCEAEA')
              .borderRadius(12)
          }

          Button('开始智能对账')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width('100%')
            .height(50)
            .backgroundColor(this.batchUnavailableMessage === '' ? '#1769E0' : '#B8C4D5')
            .enabled(this.batchUnavailableMessage === '')
            .borderRadius(25)
            .shadow({ radius: 9, color: '#251769E0', offsetX: 0, offsetY: 3 })
            .onClick(() => {
              this.openAnalysisPanel();
            })

          if (this.analysisPanelVisible) {
            this.AnalysisPanel()
          }
          Column({ space: 12 }) {
            Text('数据概览')
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor('#14213D')
              .width('100%')

            GridRow({
              columns: { xs: 2, sm: 2, md: 4, lg: 4 },
              gutter: { x: 12, y: 12 }
            }) {
              GridCol({ span: 1 }) {
                this.OverviewCard('全部任务', this.tasks.length.toString(), '#14213D')
              }
              GridCol({ span: 1 }) {
                this.OverviewCard(
                  this.analysisCompleted ? '存在差异' : '待处理',
                  this.getTaskCountByStatus(this.analysisCompleted ? '存在差异' : '待处理'),
                  this.analysisCompleted ? '#B54747' : '#B65E10'
                )
              }
              GridCol({ span: 1 }) {
                this.OverviewCard(
                  this.analysisCompleted ? '待补充材料' : '对账中',
                  this.getTaskCountByStatus(this.analysisCompleted ? '待补充材料' : '对账中'),
                  this.analysisCompleted ? '#B65E10' : '#1769E0'
                )
              }
              GridCol({ span: 1 }) {
                this.OverviewCard('已完成', this.getTaskCountByStatus('已完成'), '#17795B')
              }
            }
            .width('100%')
          }
          .width('100%')

          Column({ space: 14 }) {
            Row({ space: 8 }) {
              this.FilterChip('全部')
              this.FilterChip(this.analysisCompleted ? '存在差异' : '待处理')
              this.FilterChip(this.analysisCompleted ? '待补充材料' : '对账中')
              this.FilterChip('已完成')
            }
            .width('100%')

            Column({ space: 12 }) {
              ForEach(this.getFilteredTasks(), (task: ReconciliationTask) => {
                this.TaskCard(task)
              }, (task: ReconciliationTask) => task.orderNo)
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
