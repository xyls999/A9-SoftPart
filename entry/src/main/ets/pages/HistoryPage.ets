/**
 * 历史记录页 · 数据看板 + 可视化图表 + 日志信息
 * 支持可展开高级图表、二维数据对比
 */
import { AppCard } from '../components/AppCard';
import { SectionHeader } from '../components/SectionHeader';
import { MockData } from '../mock/mockData';
import { AlertMessage, Device } from '../api/types';
import { DeviceApi } from '../api/deviceApi';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';

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
  @State todayEnergy: number = 14.3;
  @State chartExpanded: boolean = false;
  @State activeCompareKey: string = 'temp_humid';
  /** 近 7 天能耗模拟数据 */
  private weekEnergy: number[] = [12.1, 13.8, 11.5, 15.2, 14.3, 16.0, 11.9];
  /** 24 小时时间标签 */
  private hourLabels: string[] = ['0', '2', '4', '6', '8', '10', '12', '14', '16', '18', '20', '22'];

  /** 二维对比数据集 */
  private compareSets: CompareSet[] = [
    {
      key: 'temp_humid',
      label: '温度 · 湿度',
      labelA: '温度 (°C)', labelB: '湿度 (%RH)',
      colorA: AppColors.SENSOR_TEMP, colorB: AppColors.SENSOR_HUMID,
      unitA: '°C', unitB: '%',
      dataA: [22.5,22.0,21.8,22.1,23.0,24.1,25.2,26.0,26.5,25.8,24.3,23.1],
      dataB: [58,60,62,61,56,52,48,45,43,46,50,55]
    },
    {
      key: 'air_quality',
      label: 'PM2.5 · CO₂',
      labelA: 'PM2.5 (μg/m³)', labelB: 'CO₂ (ppm)',
      colorA: AppColors.SENSOR_AIR, colorB: AppColors.PURPLE,
      unitA: 'μg', unitB: 'ppm',
      dataA: [12,15,18,22,20,17,14,13,16,19,21,18],
      dataB: [580,600,620,650,640,610,590,570,560,575,595,612]
    },
    {
      key: 'power_day',
      label: '功率 · 电量',
      labelA: '功率 (kW)', labelB: '累计 (kWh)',
      colorA: AppColors.SENSOR_POWER, colorB: AppColors.ORANGE,
      unitA: 'kW', unitB: 'kWh',
      dataA: [0.8,0.6,0.5,0.7,1.2,2.1,1.8,1.5,1.3,1.8,2.5,1.9],
      dataB: [0.8,1.4,1.9,2.6,3.8,5.9,7.7,9.2,10.5,12.3,14.8,16.7]
    }
  ];

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.alerts = MockData.alerts;
    this.devices = await DeviceApi.getDevices();
    this.deviceCount = this.devices.length;
    this.onlineCount = this.devices.filter((d: Device) => d.status !== 'offline').length;
    this.alertCount = this.alerts.filter((a: AlertMessage) => !a.isRead).length;
  }

  private get activeCompare(): CompareSet {
    return this.compareSets.find((c: CompareSet) => c.key === this.activeCompareKey) ?? this.compareSets[0];
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
  private maxIn(...arrays: number[][]): number {
    let m = 0;
    for (const arr of arrays) {
      for (const v of arr) { if (v > m) m = v; }
    }
    return m;
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
  funcEntry(icon: Resource, label: string, color: string) {
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
        Text(label)
          .fontSize(AppFont.SIZE_BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
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
              this.statItem(`${this.todayEnergy.toFixed(1)}`, '今日能耗', AppColors.SENSOR_POWER, $r('sys.symbol.bolt_fill'))
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
              Row({ space: AppSpace.SM }) {
                ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string, idx: number) => {
                  Column({ space: AppSpace.XS }) {
                    Text(`${this.weekEnergy[idx]}`)
                      .fontSize(AppFont.SIZE_CAPTION)
                      .fontColor(idx === this.maxEnergyDay ? AppColors.DANGER : AppColors.TEXT_TERTIARY)
                      .fontWeight(idx === this.maxEnergyDay ? FontWeight.Medium : FontWeight.Regular)
                    Column()
                      .width('100%')
                      .height(this.weekEnergy[idx] * 5.5)
                      .borderRadius(4)
                      .backgroundColor(idx === this.maxEnergyDay ? AppColors.DANGER : AppColors.PRIMARY_BG)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Center)
                  .justifyContent(FlexAlign.End)
                }, (day: string) => day)
              }
              .width('100%')
              .height(120)
              .alignItems(VerticalAlign.Bottom)

              Row() {
                Text('周均')
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_TERTIARY)
                Text(`${(this.weekEnergy.reduce((a: number, b: number) => a + b, 0) / 7).toFixed(1)} kWh`)
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Medium)
                  .margin({ left: AppSpace.XS })
                Blank()
                Text('峰值')
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_TERTIARY)
                Text(`${Math.max(...this.weekEnergy).toFixed(1)} kWh`)
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
                  ForEach(this.compareSets, (cs: CompareSet) => {
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
                      ForEach(this.hourLabels, (label: string) => {
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
                      Text(`${(this.activeCompare.dataA.reduce((a: number, b: number) => a + b, 0) / this.activeCompare.dataA.length).toFixed(1)} ${this.activeCompare.unitA}`)
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
                      Text(`${Math.max(...this.activeCompare.dataA).toFixed(1)} ${this.activeCompare.unitA}`)
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
                      Text(`${(this.activeCompare.dataB.reduce((a: number, b: number) => a + b, 0) / this.activeCompare.dataB.length).toFixed(1)} ${this.activeCompare.unitB}`)
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
                      Text(`${Math.max(...this.activeCompare.dataB).toFixed(1)} ${this.activeCompare.unitB}`)
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

        // ===== 5. 快捷功能 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '快捷功能', subtitle: '数据管理与分析' })

          Grid() {
            GridItem() { this.funcEntry($r('sys.symbol.house_fill'), '设备日志', AppColors.PRIMARY) }
            GridItem() { this.funcEntry($r('sys.symbol.bolt_fill'), '能耗统计', AppColors.SENSOR_POWER) }
            GridItem() { this.funcEntry($r('sys.symbol.flame_fill'), '告警中心', AppColors.WARNING) }
            GridItem() { this.funcEntry($r('sys.symbol.paperplane_fill'), '数据导出', AppColors.SUCCESS) }
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(AppSpace.CARD_GAP)
          .rowsGap(AppSpace.CARD_GAP)
          .width('100%')
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
