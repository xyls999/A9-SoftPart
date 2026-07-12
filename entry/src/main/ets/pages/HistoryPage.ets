/**
 * 历史记录页 · 数据看板 + 可视化图表 + 日志信息
 * 支持可展开高级图表、二维数据对比
 */
import { AppCard } from '../components/AppCard';
import { SectionHeader } from '../components/SectionHeader';
import { AlertMessage, Device, Sensor, SensorType } from '../api/types';
import { DeviceApi } from '../api/deviceApi';
import { SensorApi } from '../api/sensorApi';
import { MonitorApi } from '../api/monitorApi';
import { BackendStatItem, SystemStatsApi } from '../api/systemStatsApi';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';
import { StatRing } from '../components/StatRing';

/** 二维对比数据集 */
interface CompareSet {
  key: string;
  label: string;
  labelA: string;
  labelB: string;
  colorA: string;
  colorB: string;
  dataA: number[];
  dataB: number[];
  unitA: string;
  unitB: string;
}

@Component
export struct HistoryPage {
  @State alerts: AlertMessage[] = [];
  @State devices: Device[] = [];
  @State deviceCount: number = 0;
  @State onlineCount: number = 0;
  @State alertCount: number = 0;
  @State sensorCount: number = 0;
  @State todayEnergyText: string = '暂无';
  @State chartExpanded: boolean = false;
  @State activeCompareKey: string = 'temp_humid';
  @State realTempData: number[] = [];
  @State realHumidData: number[] = [];
  @State realLabels: string[] = [];
  @State backendStatsAvailable: boolean = false;
  @State backendDeviceRate: number = 0;
  @State backendStatsItems: BackendStatItem[] = [];
  /** 近 7 天真实能耗数据 */
  private weekEnergy: number[] = [];
  /** 24 小时时间标签 */
  private hourLabels: string[] = [];

  /** 二维对比数据集 (temp_humid 由 getter 动态返回,不在此处) */
  private compareSets: CompareSet[] = [
    {
      key: 'air_quality',
      label: 'PM2.5 · CO₂',
      labelA: 'PM2.5 (μg/m³)', labelB: 'CO₂ (ppm)',
      colorA: AppColors.SENSOR_AIR, colorB: AppColors.PURPLE,
      unitA: 'μg', unitB: 'ppm',
      dataA: [],
      dataB: []
    },
    {
      key: 'power_day',
      label: '功率 · 电量',
      labelA: '功率 (kW)', labelB: '累计 (kWh)',
      colorA: AppColors.SENSOR_POWER, colorB: AppColors.PRIMARY,
      unitA: 'kW', unitB: 'kWh',
      dataA: [],
      dataB: []
    }
  ];

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    // 真实告警
    const remoteAlerts = await MonitorApi.getAlerts();
    this.alerts = remoteAlerts;
    // 真实设备
    this.devices = await DeviceApi.getDevices();
    this.deviceCount = this.devices.length;
    this.onlineCount = this.devices.filter((d: Device) => d.status !== 'offline').length;
    this.alertCount = this.alerts.filter((a: AlertMessage) => !a.isRead).length;
    const sensors = await SensorApi.getSensors();
    this.sensorCount = sensors.length;
    const energy = sensors.find((s: Sensor) => s.id === 'power_02' || s.type === SensorType.POWER && s.name.includes('今日'));
    if (energy && energy.current.unit !== '离线') {
      this.todayEnergyText = energy.current.value.toFixed(1);
    } else {
      this.todayEnergyText = '暂无';
    }
    // 真实温湿度历史
    const history = await SensorApi.getTempHumidHistory();
    if (history.temp.length > 0) {
      this.realTempData = history.temp;
      this.realHumidData = history.humid;
      this.realLabels = history.labels;
    }
    const featureStats = await SystemStatsApi.getFeatureStats();
    this.backendStatsAvailable = featureStats.available;
    this.backendDeviceRate = featureStats.deviceOnlineRate;
    this.backendStatsItems = featureStats.items;
  }

  private get activeCompare(): CompareSet {
    if (this.activeCompareKey === 'temp_humid') {
      return {
        key: 'temp_humid', label: '温度 · 湿度',
        labelA: '温度 (°C)', labelB: '湿度 (%RH)',
        colorA: AppColors.SENSOR_TEMP, colorB: AppColors.SENSOR_HUMID,
        unitA: '°C', unitB: '%',
        dataA: this.realTempData,
        dataB: this.realHumidData
      };
    }
    const found = this.compareSets.find((c: CompareSet) => c.key === this.activeCompareKey);
    return found ?? this.compareSets[0];
  }

  /** 选择器用到的所有 key+label (含 temp_humid) */
  private get allCompareKeys(): CompareSet[] {
    const tempSet: CompareSet = {
      key: 'temp_humid', label: '温度 · 湿度',
      labelA: '温度 (°C)', labelB: '湿度 (%RH)',
      colorA: AppColors.SENSOR_TEMP, colorB: AppColors.SENSOR_HUMID,
      unitA: '°C', unitB: '%',
      dataA: this.realTempData, dataB: this.realHumidData
    };
    const merged: CompareSet[] = [tempSet];
    for (const item of this.compareSets) {
      merged.push(item);
    }
    return merged;
  }

  private levelColor(level: string): string {
    if (level === 'danger') return AppColors.DANGER;
    if (level === 'warning') return AppColors.WARNING;
    return AppColors.PRIMARY;
  }

  private timeAgo(ts: number): string {
    const diff = Date.now() - ts;
    const m = Math.floor(diff / 60000);
    if (m < 1) return '刚刚';
    if (m < 60) return `${m} 分钟前`;
    const h = Math.floor(m / 60);
    if (h < 24) return `${h} 小时前`;
    return `${Math.floor(h / 24)} 天前`;
  }

  /** 找最大值（用于柱状/线的高度归一化） */
  private maxIn(arrays: number[][]): number {
    let m = 0;
    for (const arr of arrays) {
      for (const v of arr) {
        if (v > m) {
          m = v;
        }
      }
    }
    return m;
  }

  private maxOf(values: number[]): number {
    let max = 0;
    for (const value of values) {
      if (value > max) {
        max = value;
      }
    }
    return max;
  }

  private avgText(values: number[], unit: string): string {
    if (!values || values.length === 0) return `离线 ${unit}`;
    const avg = values.reduce((a: number, b: number) => a + b, 0) / values.length;
    return `${avg.toFixed(1)} ${unit}`;
  }

  private maxText(values: number[], unit: string): string {
    if (!values || values.length === 0) return `离线 ${unit}`;
    return `${this.maxOf(values).toFixed(1)} ${unit}`;
  }

  private backendChartItems(): BackendStatItem[] {
    return this.backendStatsItems.length > 1 ? this.backendStatsItems.slice(1) : [];
  }

  @Builder
  statItem(value: string, label: string, color: string, icon: Resource) {
    Column({ space: AppSpace.XS }) {
      Column() {
        SymbolGlyph(icon)
          .fontSize(14)
          .fontColor([color])
      }
      .width(32).height(32)
      .borderRadius(16)
      .backgroundColor(color + '18')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      Text(value)
        .fontSize(AppFont.SIZE_TITLE_LG)
        .fontColor(AppColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(AppFont.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_TERTIARY)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  statDivider() {
    Column()
      .width(0.5)
      .height(48)
      .backgroundColor(AppColors.DIVIDER)
  }

  @Builder
  funcEntry(icon: Resource, label: string, value: string, color: string) {
    AppCard({ innerPadding: AppSpace.BASE, cornerRadius: AppSpace.RADIUS_CARD }) {
      Column({ space: AppSpace.MD }) {
        Column() {
          SymbolGlyph(icon)
            .fontSize(22)
            .fontColor([color])
        }
        .width(44).height(44)
        .borderRadius(22)
        .backgroundColor(color + '16')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        Text(value)
          .fontSize(AppFont.SIZE_TITLE_LG)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(label)
          .fontSize(AppFont.SIZE_CAPTION)
          .fontColor(AppColors.TEXT_TERTIARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  backendMetricRow(stat: BackendStatItem) {
    Column({ space: AppSpace.XS }) {
      Row({ space: AppSpace.SM }) {
        Column({ space: 2 }) {
          Text(stat.label)
            .fontSize(AppFont.SIZE_CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
          Text(stat.detail)
            .fontSize(9)
            .fontColor(AppColors.TEXT_TERTIARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(stat.value)
          .fontSize(AppFont.SIZE_CAPTION)
          .fontColor(stat.online ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (stat.progress >= 0) {
        Progress({ value: stat.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color(stat.online ? AppColors.PRIMARY : '#A9C7E8')
          .backgroundColor('#EAF4FF')
          .style({ strokeWidth: 5 })
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
    .padding({ left: AppSpace.SM, right: AppSpace.SM, top: AppSpace.XS, bottom: AppSpace.XS })
    .borderRadius(AppSpace.RADIUS_BASE)
    .backgroundColor('#F5FAFF')
  }

  @Builder
  backendStatsChart() {
    AppCard({ innerPadding: AppSpace.BASE, cornerRadius: AppSpace.RADIUS_CARD }) {
      Column({ space: AppSpace.SM }) {
        if (this.backendStatsAvailable) {
          Row({ space: AppSpace.BASE }) {
            StatRing({ value: this.backendDeviceRate, max: 100, unit: '%', ringColor: AppColors.PRIMARY, ringSize: 86 })
            Column({ space: AppSpace.XS }) {
              Text('设备在线率')
                .fontSize(AppFont.SIZE_BODY)
                .fontColor(AppColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
              Text(this.backendStatsItems.length > 0 ? this.backendStatsItems[0].detail : '暂无')
                .fontSize(AppFont.SIZE_FOOTNOTE)
                .fontColor(AppColors.TEXT_TERTIARY)
              Text('12 类实时状态')
                .fontSize(AppFont.SIZE_CAPTION)
                .fontColor(AppColors.PRIMARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: AppSpace.SM, right: AppSpace.SM })
          .alignItems(VerticalAlign.Center)

          ForEach(this.backendChartItems(), (stat: BackendStatItem) => {
            this.backendMetricRow(stat)
          }, (stat: BackendStatItem) => stat.key)
        } else {
          Text('后端未返回统计信息')
            .fontSize(AppFont.SIZE_FOOTNOTE)
            .fontColor(AppColors.TEXT_TERTIARY)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: AppSpace.BASE, bottom: AppSpace.BASE })
        }
      }
      .width('100%')
    }
  }

  private get hourLabelsComputed(): string[] {
    if (this.activeCompareKey === 'temp_humid' && this.realLabels.length > 0) {
      return this.realLabels;
    }
    return this.hourLabels;
  }

  private get maxEnergyDay(): number {
    let max = 0;
    for (let i = 1; i < this.weekEnergy.length; i++) {
      if (this.weekEnergy[i] > this.weekEnergy[max]) max = i;
    }
    return max;
  }

  build() {
    Scroll() {
      Column({ space: AppSpace.BASE }) {

        // ===== 页面标题 =====
        Row({ space: AppSpace.SM }) {
          Column() {
            SymbolGlyph($r('sys.symbol.clock_fill'))
              .fontSize(22)
              .fontColor([AppColors.PRIMARY])
          }
          .width(40).height(40)
          .borderRadius(20)
          .backgroundColor(AppColors.PRIMARY_BG)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          Column({ space: 2 }) {
            Text('历史记录')
              .fontSize(AppFont.SIZE_TITLE_LG)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
            Text('数据看板 · 可视化分析')
              .fontSize(AppFont.SIZE_FOOTNOTE)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // ===== 1. 今日概览 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '今日概览', subtitle: '设备 · 告警 · 能耗' })
          AppCard({ innerPadding: AppSpace.LG }) {
            Row() {
              this.statItem(`${this.deviceCount}`, '设备总数', AppColors.PRIMARY, $r('sys.symbol.house_fill'))
              this.statDivider()
              this.statItem(`${this.onlineCount}`, '在线设备', AppColors.SUCCESS, $r('sys.symbol.wifi'))
              this.statDivider()
              this.statItem(`${this.alertCount}`, '未读告警', AppColors.DANGER, $r('sys.symbol.flame_fill'))
              this.statDivider()
              this.statItem(this.todayEnergyText, '今日能耗', AppColors.SENSOR_POWER, $r('sys.symbol.bolt_fill'))
            }
            .width('100%')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ===== 2. 能耗趋势柱状图 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '能耗趋势', subtitle: '近 7 天用电量 (kWh)' })
          AppCard({ innerPadding: AppSpace.BASE }) {
            Column({ space: AppSpace.MD }) {
              if (this.weekEnergy.length > 0) {
                Row({ space: AppSpace.SM }) {
                  ForEach(this.weekEnergy, (value: number, idx: number) => {
                    Column({ space: AppSpace.XS }) {
                      Text(`${value}`)
                        .fontSize(AppFont.SIZE_CAPTION)
                        .fontColor(idx === this.maxEnergyDay ? AppColors.DANGER : AppColors.TEXT_TERTIARY)
                        .fontWeight(idx === this.maxEnergyDay ? FontWeight.Medium : FontWeight.Regular)
                      Column()
                        .width('100%')
                        .height(value * 5.5)
                        .borderRadius(4)
                        .backgroundColor(idx === this.maxEnergyDay ? AppColors.DANGER : AppColors.PRIMARY_BG)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                    .justifyContent(FlexAlign.End)
                  }, (_: number, idx: number) => `${idx}`)
                }
                .width('100%')
                .height(120)
                .alignItems(VerticalAlign.Bottom)
              } else {
                Text('暂无真实能耗数据')
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_TERTIARY)
                  .width('100%')
                  .height(120)
                  .textAlign(TextAlign.Center)
              }

              Row() {
                Text('周均')
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_TERTIARY)
                Text(this.avgText(this.weekEnergy, 'kWh'))
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Medium)
                  .margin({ left: AppSpace.XS })
                Blank()
                Text('峰值')
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_TERTIARY)
                Text(this.maxText(this.weekEnergy, 'kWh'))
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.DANGER)
                  .fontWeight(FontWeight.Medium)
                  .margin({ left: AppSpace.XS })
              }
              .width('100%')
            }
            .width('100%')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ===== 3. 高级图表（可展开/折叠） =====
        Column({ space: AppSpace.SM }) {
          // 可点击展开的标题
          Row() {
            Column({ space: 2 }) {
              Text('高级图表')
                .fontSize(AppFont.SIZE_BODY_LG)
                .fontColor(AppColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              Text('二维数据对比 · 24 小时趋势')
                .fontSize(AppFont.SIZE_FOOTNOTE)
                .fontColor(AppColors.TEXT_TERTIARY)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(18)
                .fontColor([AppColors.TEXT_TERTIARY])
            }
            .width(32).height(32)
            .borderRadius(16)
            .backgroundColor(AppColors.BG_INPUT)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .rotate({ angle: this.chartExpanded ? 90 : 0 })
            .animation({ duration: 250, curve: Curve.EaseInOut })
          }
          .width('100%')
          .onClick(() => { this.chartExpanded = !this.chartExpanded; })

          // 展开内容
          if (this.chartExpanded) {
            Column({ space: AppSpace.SM }) {
              // 对比类型选择器
              Scroll() {
                Row({ space: AppSpace.SM }) {
                  ForEach(this.allCompareKeys, (cs: CompareSet) => {
                    Text(cs.label)
                      .fontSize(AppFont.SIZE_FOOTNOTE)
                      .fontColor(this.activeCompareKey === cs.key ? AppColors.TEXT_INVERSE : AppColors.TEXT_SECONDARY)
                      .fontWeight(this.activeCompareKey === cs.key ? FontWeight.Medium : FontWeight.Regular)
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .borderRadius(AppSpace.RADIUS_PILL)
                      .backgroundColor(this.activeCompareKey === cs.key ? AppColors.PRIMARY : AppColors.BG_INPUT)
                      .onClick(() => { this.activeCompareKey = cs.key; })
                  }, (cs: CompareSet) => cs.key)
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')

              // 二维对比柱状图
              AppCard({ innerPadding: AppSpace.BASE }) {
                Column({ space: AppSpace.MD }) {
                  // 图例
                  Row({ space: AppSpace.LG }) {
                    Row({ space: AppSpace.XS }) {
                      Column().width(10).height(10).borderRadius(2).backgroundColor(this.activeCompare.colorA)
                      Text(this.activeCompare.labelA)
                        .fontSize(AppFont.SIZE_CAPTION)
                        .fontColor(AppColors.TEXT_TERTIARY)
                    }
                    Row({ space: AppSpace.XS }) {
                      Column().width(10).height(10).borderRadius(2).backgroundColor(this.activeCompare.colorB)
                      Text(this.activeCompare.labelB)
                        .fontSize(AppFont.SIZE_CAPTION)
                        .fontColor(AppColors.TEXT_TERTIARY)
                    }
                  }

                  // 双柱图
                  Column({ space: 0 }) {
                    // 数值标签行
                    Row({ space: 0 }) {
                      ForEach(this.activeCompare.dataA, (_: number, idx: number) => {
                        Column({ space: 1 }) {
                          Text(`${this.activeCompare.dataA[idx]}`)
                            .fontSize(8)
                            .fontColor(this.activeCompare.colorA)
                          Text(`${this.activeCompare.dataB[idx]}`)
                            .fontSize(8)
                            .fontColor(this.activeCompare.colorB)
                        }
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.Center)
                      })
                    }
                    .width('100%')
                    .margin({ bottom: AppSpace.XS })

                    // 柱体行（双柱并排）
                    Row({ space: 1 }) {
                      ForEach(this.activeCompare.dataA, (_: number, idx: number) => {
                        Column({ space: 1 }) {
                          // 柱 A
                          Row({ space: 1 }) {
                            Column()
                              .width('45%')
                              .height(this.activeCompare.dataA[idx] * 3.5)
                              .borderRadius({ topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0 })
                              .backgroundColor(this.activeCompare.colorA)
                            Column()
                              .width('45%')
                              .height(this.activeCompare.dataB[idx] * 0.18)
                              .borderRadius({ topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0 })
                              .backgroundColor(this.activeCompare.colorB)
                          }
                          .width('100%')
                          .justifyContent(FlexAlign.End)
                          .alignItems(VerticalAlign.Bottom)
                        }
                        .layoutWeight(1)
                        .justifyContent(FlexAlign.End)
                      })
                    }
                    .width('100%')
                    .height(100)
                    .alignItems(VerticalAlign.Bottom)

                    // 分隔线 + 时间标签
                    Column()
                      .width('100%')
                      .height(0.5)
                      .backgroundColor(AppColors.DIVIDER)
                      .margin({ top: AppSpace.XS, bottom: AppSpace.XS })

                    Row({ space: 0 }) {
                      ForEach(this.hourLabelsComputed, (label: string) => {
                        Text(label)
                          .fontSize(9)
                          .fontColor(AppColors.TEXT_TERTIARY)
                          .layoutWeight(1)
                          .textAlign(TextAlign.Center)
                      })
                    }
                    .width('100%')
                  }
                  .width('100%')

                  // 统计摘要
                  Row() {
                    Column({ space: 2 }) {
                      Text('均值')
                        .fontSize(AppFont.SIZE_CAPTION)
                        .fontColor(AppColors.TEXT_TERTIARY)
                      Text(this.avgText(this.activeCompare.dataA, this.activeCompare.unitA))
                        .fontSize(AppFont.SIZE_FOOTNOTE)
                        .fontColor(this.activeCompare.colorA)
                        .fontWeight(FontWeight.Medium)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                    Column({ space: 2 }) {
                      Text('峰值')
                        .fontSize(AppFont.SIZE_CAPTION)
                        .fontColor(AppColors.TEXT_TERTIARY)
                      Text(this.maxText(this.activeCompare.dataA, this.activeCompare.unitA))
                        .fontSize(AppFont.SIZE_FOOTNOTE)
                        .fontColor(this.activeCompare.colorA)
                        .fontWeight(FontWeight.Medium)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                    Column().width(0.5).height(32).backgroundColor(AppColors.DIVIDER)
                    Column({ space: 2 }) {
                      Text('均值')
                        .fontSize(AppFont.SIZE_CAPTION)
                        .fontColor(AppColors.TEXT_TERTIARY)
                      Text(this.avgText(this.activeCompare.dataB, this.activeCompare.unitB))
                        .fontSize(AppFont.SIZE_FOOTNOTE)
                        .fontColor(this.activeCompare.colorB)
                        .fontWeight(FontWeight.Medium)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                    Column({ space: 2 }) {
                      Text('峰值')
                        .fontSize(AppFont.SIZE_CAPTION)
                        .fontColor(AppColors.TEXT_TERTIARY)
                      Text(this.maxText(this.activeCompare.dataB, this.activeCompare.unitB))
                        .fontSize(AppFont.SIZE_FOOTNOTE)
                        .fontColor(this.activeCompare.colorB)
                        .fontWeight(FontWeight.Medium)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                  }
                  .width('100%')
                }
                .width('100%')
              }
            }
            .width('100%')
            .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ===== 4. 近期日志 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({
            title: '近期日志',
            subtitle: `${this.alerts.filter((a: AlertMessage) => !a.isRead).length} 条未读 · 共 ${this.alerts.length} 条记录`
          })

          ForEach(this.alerts, (a: AlertMessage) => {
            AppCard({ innerPadding: AppSpace.BASE }) {
              Row() {
                Circle({ width: 8, height: 8 })
                  .fill(this.levelColor(a.level))
                  .margin({ right: AppSpace.SM, top: 4 })

                Column({ space: 4 }) {
                  Row({ space: AppSpace.XS }) {
                    Text(a.source)
                      .fontSize(AppFont.SIZE_BODY)
                      .fontColor(AppColors.TEXT_PRIMARY)
                      .fontWeight(FontWeight.Medium)
                    if (!a.isRead) {
                      Text('新')
                        .fontSize(9)
                        .fontColor(AppColors.TEXT_INVERSE)
                        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                        .borderRadius(4)
                        .backgroundColor(AppColors.DANGER)
                    }
                  }
                  Text(a.content)
                    .fontSize(AppFont.SIZE_FOOTNOTE)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(this.timeAgo(a.timestamp))
                  .fontSize(AppFont.SIZE_CAPTION)
                  .fontColor(AppColors.TEXT_TERTIARY)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }
          }, (a: AlertMessage) => a.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ===== 5. 其他统计 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '其他统计', subtitle: this.backendStatsAvailable ? 'A9 v5 · 12 类真实状态' : '暂无真实数据' })
          this.backendStatsChart()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING, top: 48, bottom: 100 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
