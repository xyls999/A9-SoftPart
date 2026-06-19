/**
 * 添加设备页 · 经典鸿蒙浅色
 * 选择类型 → 填名称 → 选房间 → 确认添加
 */
import { AppCard } from '../components/AppCard';
import { AppIcon } from '../components/AppIcon';
import { DeviceApi } from '../api/deviceApi';
import { Device, DeviceType, DeviceStatus } from '../api/types';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';
import { router, promptAction } from '@kit.ArkUI';

interface TypeOption {
  type: DeviceType;
  label: string;
  icon: Resource;
  color: string;
  bg: string;
  defaultVal: number;
}

@Entry
@Component
struct AddDevicePage {
  @State selectedType: DeviceType = DeviceType.FAN;
  @State deviceName: string = '';
  @State selectedRoom: string = '客厅';
  @State adding: boolean = false;

  private readonly typeOptions: TypeOption[] = [
    { type: DeviceType.FAN, label: '风扇', icon: $r('sys.symbol.fan_fill_1'), color: AppColors.DEVICE_FAN, bg: AppColors.DEVICE_FAN_BG, defaultVal: 1 },
    { type: DeviceType.AC, label: '空调', icon: $r('sys.symbol.air_fill'), color: AppColors.DEVICE_AC, bg: AppColors.DEVICE_AC_BG, defaultVal: 24 },
    { type: DeviceType.DOOR, label: '门禁', icon: $r('sys.symbol.door_service'), color: AppColors.DEVICE_DOOR, bg: AppColors.DEVICE_DOOR_BG, defaultVal: 0 },
    { type: DeviceType.LIGHT, label: '灯光', icon: $r('sys.symbol.lightbulb'), color: AppColors.DEVICE_LIGHT, bg: AppColors.DEVICE_LIGHT_BG, defaultVal: 60 }
  ];

  private readonly rooms: string[] = ['客厅', '主卧', '次卧', '厨房', '卫生间', '玄关', '书房', '车库'];

  private get canSubmit(): boolean {
    return this.deviceName.trim().length > 0 && !this.adding;
  }

  private get currentOption(): TypeOption {
    const found = this.typeOptions.find(o => o.type === this.selectedType);
    return found ?? this.typeOptions[0];
  }

  async submit(): Promise<void> {
    if (!this.canSubmit) return;
    this.adding = true;
    const id = DeviceApi.genId(this.selectedType);
    const opt = this.currentOption;
    const device: Device = {
      id: id,
      name: this.deviceName.trim(),
      type: this.selectedType,
      status: DeviceStatus.ONLINE,
      room: this.selectedRoom,
      icon: opt.icon,
      primaryValue: opt.defaultVal,
      isOn: false
    };
    await DeviceApi.addDevice(device);
    this.adding = false;
    promptAction.showToast({ message: `已添加「${device.name}」`, duration: 2000 });
    router.back();
  }

  build() {
    Column() {
      // 顶部返回栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([AppColors.TEXT_PRIMARY])
          .onClick(() => router.back())
        Text('添加设备')
          .fontSize(AppFont.SIZE_TITLE)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%')
      .padding({ left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING, top: 48, bottom: AppSpace.MD })

      Scroll() {
        Column({ space: AppSpace.BASE }) {
          // ===== 1. 设备类型选择 =====
          Column({ space: AppSpace.SM }) {
            Text('选择设备类型')
              .fontSize(AppFont.SIZE_BODY_LG)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            Grid() {
              ForEach(this.typeOptions, (opt: TypeOption) => {
                GridItem() {
                  Column({ space: AppSpace.SM }) {
                    Column() {
                      AppIcon({ iconRes: opt.icon, iconSize: 28, iconColor: opt.color })
                    }
                    .width(56).height(56)
                    .borderRadius(28)
                    .backgroundColor(this.selectedType === opt.type ? opt.bg : AppColors.BG_INPUT)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    Text(opt.label)
                      .fontSize(AppFont.SIZE_FOOTNOTE)
                      .fontColor(this.selectedType === opt.type ? opt.color : AppColors.TEXT_TERTIARY)
                      .fontWeight(this.selectedType === opt.type ? FontWeight.Medium : FontWeight.Regular)
                  }
                  .padding(AppSpace.SM)
                  .borderRadius(AppSpace.RADIUS_CARD)
                  .border(this.selectedType === opt.type ? { width: 1.5, color: opt.color } : { width: 0, color: '#00000000' })
                  .backgroundColor(this.selectedType === opt.type ? `${opt.color}0A` : AppColors.BG_CARD)
                  .alignItems(HorizontalAlign.Center)
                  .onClick(() => { this.selectedType = opt.type; })
                }
              }, (opt: TypeOption) => opt.type)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .columnsGap(AppSpace.SM)
            .rowsGap(AppSpace.SM)
            .width('100%')
            .height(130)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // ===== 2. 设备名称 =====
          Column({ space: AppSpace.SM }) {
            Text('设备名称')
              .fontSize(AppFont.SIZE_BODY_LG)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            TextInput({ placeholder: `如：客厅${this.currentOption.label}`, text: this.deviceName })
              .height(48)
              .fontSize(AppFont.SIZE_BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .placeholderColor(AppColors.TEXT_TERTIARY)
              .borderRadius(AppSpace.RADIUS_BASE)
              .backgroundColor(AppColors.BG_INPUT)
              .padding({ left: AppSpace.BASE, right: AppSpace.BASE })
              .onChange((v: string) => { this.deviceName = v; })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // ===== 3. 房间选择 =====
          Column({ space: AppSpace.SM }) {
            Text('安装位置')
              .fontSize(AppFont.SIZE_BODY_LG)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.rooms, (room: string) => {
                Text(room)
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(this.selectedRoom === room ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
                  .padding({ left: AppSpace.BASE, right: AppSpace.BASE, top: AppSpace.SM, bottom: AppSpace.SM })
                  .margin({ right: AppSpace.SM, bottom: AppSpace.SM })
                  .borderRadius(AppSpace.RADIUS_PILL)
                  .backgroundColor(this.selectedRoom === room ? AppColors.PRIMARY_BG : AppColors.BG_INPUT)
                  .fontWeight(this.selectedRoom === room ? FontWeight.Medium : FontWeight.Regular)
                  .onClick(() => { this.selectedRoom = room; })
              }, (room: string) => room)
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // ===== 4. 预览 =====
          AppCard({ innerPadding: AppSpace.BASE }) {
            Row({ space: AppSpace.MD }) {
              Column() {
                AppIcon({ iconRes: this.currentOption.icon, iconSize: 24, iconColor: this.currentOption.color })
              }
              .width(44).height(44)
              .borderRadius(22)
              .backgroundColor(this.currentOption.bg)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              Column({ space: 2 }) {
                Text(this.deviceName.trim() || '设备名称')
                  .fontSize(AppFont.SIZE_BODY)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Medium)
                Text(`${this.currentOption.label} · ${this.selectedRoom}`)
                  .fontSize(AppFont.SIZE_FOOTNOTE)
                  .fontColor(AppColors.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }

          Column().height(AppSpace.XXL)
        }
        .width('100%')
        .padding({ left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING, bottom: 100 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 底部确认按钮
      Row() {
        Button(this.adding ? '添加中...' : '确认添加')
          .width('100%')
          .height(48)
          .fontSize(AppFont.SIZE_BODY_LG)
          .fontColor(this.canSubmit ? AppColors.TEXT_INVERSE : AppColors.TEXT_TERTIARY)
          .backgroundColor(this.canSubmit ? AppColors.PRIMARY : AppColors.BG_INPUT)
          .borderRadius(AppSpace.RADIUS_BASE)
          .enabled(this.canSubmit)
          .onClick(() => this.submit())
      }
      .width('100%')
      .padding({ left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING, top: AppSpace.SM, bottom: AppSpace.LG })
      .backgroundColor(AppColors.BG_CARD)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
