/**
 * 历史记录页 · 数据看板 + 日志信息 + 快捷功能
 * 经典鸿蒙浅色风格 — 参考 MinePage 统计卡片 & MonitorPage 告警列表样式
 */
import { AppCard } from '../components/AppCard';
import { SectionHeader } from '../components/SectionHeader';
import { MockData } from '../mock/mockData';
import { AlertMessage, Device } from '../api/types';
import { DeviceApi } from '../api/deviceApi';
import { SensorApi } from '../api/sensorApi';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';

@Component
export struct HistoryPage {
  @State alerts: AlertMessage[] = [];
  @State devices: Device[] = [];
  @State deviceCount: number = 0;
  @State onlineCount: number = 0;
  @State alertCount: number = 0;
  @State todayEnergy: number = 14.3;
  /** 近 7 天能耗模拟数据 */
  private weekEnergy: number[] = [12.1, 13.8, 11.5, 15.2, 14.3, 16.0, 11.9];

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.alerts = MockData.alerts;
    this.devices = await DeviceApi.getDevices();
    // 静默加载传感器，仅用于后台
    void SensorApi.getSensors();
    this.deviceCount = this.devices.length;
    this.onlineCount = this.devices.filter((d: Device) => d.status !== 'offline').length;
    this.alertCount = this.alerts.filter((a: AlertMessage) => !a.isRead).length;
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

  /** 单个统计数字 */
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

  /** 统计分隔线 */
  @Builder
  statDivider() {
    Column()
      .width(0.5)
      .height(48)
      .backgroundColor(AppColors.DIVIDER)
  }

  /** 快捷功能入口卡片（2×2 网格内用） */
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

  /** 一周中能耗最高的日索引 */
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
            Text('数据看板 · 日志中心')
              .fontSize(AppFont.SIZE_FOOTNOTE)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // ===== 1. 今日概览卡片（仿 MinePage 用户卡统计行） =====
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

        // ===== 2. 近 7 天能耗趋势 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '能耗趋势', subtitle: '近 7 天用电量 (kWh)' })

          AppCard({ innerPadding: AppSpace.BASE }) {
            Column({ space: AppSpace.MD }) {
              // 柱状图行
              Row({ space: AppSpace.SM }) {
                ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string, idx: number) => {
                  Column({ space: AppSpace.XS }) {
                    Text(`${this.weekEnergy[idx]}`)
                      .fontSize(AppFont.SIZE_CAPTION)
                      .fontColor(idx === this.maxEnergyDay ? AppColors.DANGER : AppColors.TEXT_TERTIARY)
                      .fontWeight(idx === this.maxEnergyDay ? FontWeight.Medium : FontWeight.Regular)
                    // 柱状条
                    Column()
                      .width('100%')
                      .height(this.weekEnergy[idx] * 5.5)
                      .borderRadius(4)
                      .backgroundColor(idx === this.maxEnergyDay ? AppColors.DANGER : AppColors.PRIMARY_BG)
                      .animation({ duration: 400, curve: Curve.EaseOut })
                    Text(day)
                      .fontSize(AppFont.SIZE_CAPTION)
                      .fontColor(AppColors.TEXT_TERTIARY)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Center)
                  .justifyContent(FlexAlign.End)
                }, (day: string) => day)
              }
              .width('100%')
              .height(120)
              .alignItems(VerticalAlign.Bottom)

              // 底部汇总
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
                Text('周总量')
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_TERTIARY)
                Text(`${this.weekEnergy.reduce((a: number, b: number) => a + b, 0).toFixed(1)} kWh`)
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_PRIMARY)
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

        // ===== 3. 近期日志（仿 MonitorPage 告警列表） =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({
            title: '近期日志',
            subtitle: `${this.alerts.filter((a: AlertMessage) => !a.isRead).length} 条未读 · 共 ${this.alerts.length} 条记录`
          })

          ForEach(this.alerts, (a: AlertMessage) => {
            AppCard({ innerPadding: AppSpace.BASE }) {
              Row() {
                // 左侧：彩色圆点（MonitorPage 风格）
                Circle({ width: 8, height: 8 })
                  .fill(this.levelColor(a.level))
                  .margin({ right: AppSpace.SM, top: 4 })

                // 中间：内容
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

                // 右侧：时间
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

        // ===== 4. 快捷功能（仿 MinePage 设置项图标风格） =====
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
