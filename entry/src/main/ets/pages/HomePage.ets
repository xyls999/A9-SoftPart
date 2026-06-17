/**
 * 首页 · 经典鸿蒙浅色
 */
import { DeviceCard } from '../components/DeviceCard';
import { SectionHeader } from '../components/SectionHeader';
import { StatRing } from '../components/StatRing';
import { AppCard } from '../components/AppCard';
import { AppIcon } from '../components/AppIcon';
import { DeviceApi } from '../api/deviceApi';
import { SensorApi } from '../api/sensorApi';
import { Device, Sensor, Scene, SensorGroup, DeviceType } from '../api/types';
import { MockData } from '../mock/mockData';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';

@Component
export struct HomePage {
  @State devices: Device[] = [];
  @State envSensors: Sensor[] = [];
  @State scenes: Scene[] = [];
  @State activeSceneId: string = 's1';

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.devices = await DeviceApi.getDevices();
    this.envSensors = (await SensorApi.getByGroup(SensorGroup.ENVIRONMENT)).slice(0, 4);
    this.scenes = MockData.scenes;
  }

  private getGreeting(): string {
    const h = new Date().getHours();
    if (h < 6) return '夜深了';
    if (h < 11) return '早上好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  build() {
    Scroll() {
      Column({ space: AppSpace.BASE }) {
        // ===== 1. 问候头图 =====
        Row() {
          Column({ space: 4 }) {
            Text(`${this.getGreeting()}，${MockData.user.nickname}`)
              .fontSize(AppFont.SIZE_TITLE_LG)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
            Row({ space: 6 }) {
              AppIcon({ iconRes: MockData.weather.icon, iconSize: 14, iconColor: AppColors.TEXT_TERTIARY })
              Text(`${MockData.weather.city} · ${MockData.weather.condition} ${MockData.weather.temp}°C`)
                .fontSize(AppFont.SIZE_FOOTNOTE)
                .fontColor(AppColors.TEXT_TERTIARY)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Column() {
            Text(MockData.user.nickname.charAt(0))
              .fontSize(AppFont.SIZE_BODY_LG)
              .fontColor(AppColors.PRIMARY)
              .fontWeight(FontWeight.Medium)
          }
          .width(44).height(44)
          .borderRadius(22)
          .backgroundColor(AppColors.PRIMARY_BG)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // ===== 2. 场景快捷 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '场景模式', subtitle: '一键切换家居状态' })
          Scroll() {
            Row({ space: AppSpace.SM }) {
              ForEach(this.scenes, (s: Scene) => {
                Column({ space: 4 }) {
                  Column() {
                    AppIcon({
                      iconRes: s.icon,
                      iconSize: 22,
                      iconColor: this.activeSceneId === s.id ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY
                    })
                  }
                  .width(52).height(52)
                  .borderRadius(26)
                  .backgroundColor(this.activeSceneId === s.id ? AppColors.PRIMARY_BG : AppColors.BG_CARD)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  Text(s.name)
                    .fontSize(AppFont.SIZE_CAPTION)
                    .fontColor(this.activeSceneId === s.id ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
                    .fontWeight(this.activeSceneId === s.id ? FontWeight.Medium : FontWeight.Regular)
                }
                .width(64)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => { this.activeSceneId = s.id; })
              }, (s: Scene) => s.id)
            }
            .padding({ top: AppSpace.XS })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ===== 3. 设备卡片网格 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '我的设备', subtitle: `${this.devices.length} 台设备在线`, actionText: '全部 >', onAction: () => {} })
          Grid() {
            ForEach(this.devices.filter((d: Device) => d.type !== DeviceType.CAMERA), (d: Device) => {
              GridItem() {
                DeviceCard({
                  device: d,
                  onTap: () => {}
                })
              }
            }, (d: Device) => d.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(AppSpace.CARD_GAP)
          .rowsGap(AppSpace.CARD_GAP)
          .width('100%')
          .height(this.devices.filter((d: Device) => d.type !== DeviceType.CAMERA).length * 120)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ===== 4. 环境概览 =====
        Column({ space: AppSpace.SM }) {
          SectionHeader({ title: '环境概览', subtitle: '实时环境数据' })
          AppCard({ innerPadding: AppSpace.BASE }) {
            Row() {
              ForEach(this.envSensors, (s: Sensor) => {
                Column({ space: AppSpace.XS }) {
                  StatRing({
                    value: s.current.value,
                    max: s.thresholdMax || 100,
                    unit: s.current.unit,
                    ringColor: this.sensorColor(s),
                    ringSize: 64,
                    decimals: s.current.value < 10 ? 1 : 0
                  })
                  Text(s.name.replace('客厅', ''))
                    .fontSize(AppFont.SIZE_CAPTION)
                    .fontColor(AppColors.TEXT_TERTIARY)
                    .maxLines(1)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              }, (s: Sensor) => s.id)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ===== 5. AI 快捷入口 =====
        AppCard({
          innerPadding: AppSpace.BASE,
          onClickAction: () => {}
        }) {
          Row() {
            Column() {
              AppIcon({ iconRes: $r('sys.symbol.mic_fill'), iconSize: 20, iconColor: AppColors.PRIMARY })
            }
            .width(40).height(40)
            .borderRadius(20)
            .backgroundColor(AppColors.PRIMARY_BG)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            Column({ space: 2 }) {
              Text('和智能助手对话')
                .fontSize(AppFont.SIZE_BODY)
                .fontColor(AppColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              Text('"帮我打开空调" · "家里安全吗"')
                .fontSize(AppFont.SIZE_FOOTNOTE)
                .fontColor(AppColors.TEXT_TERTIARY)
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: AppSpace.SM })
            .layoutWeight(1)
            Text('›')
              .fontSize(22)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
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

  private sensorColor(s: Sensor): string {
    const map: Record<string, string> = {
      'temperature': AppColors.SENSOR_TEMP,
      'humidity': AppColors.SENSOR_HUMID,
      'air_quality': AppColors.SENSOR_AIR,
      'illuminance': AppColors.SENSOR_LIGHT
    };
    return map[s.type] || AppColors.PRIMARY;
  }
}
