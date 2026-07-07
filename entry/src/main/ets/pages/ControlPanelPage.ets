/**
 * 竖屏语音主页面
 */
import { DeviceApi } from '../api/deviceApi';
import { SensorApi } from '../api/sensorApi';
import { MonitorApi } from '../api/monitorApi';
import { ChatApi } from '../api/chatApi';
import {
  AlertMessage,
  ChatMessage,
  ChatRole,
  Device,
  DeviceType,
  Sensor,
  SensorGroup
} from '../api/types';
import { MockData } from '../mock/mockData';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';

@Component
export struct ControlPanelPage {
  @State activePage: number = 0;
  @State devices: Device[] = [];
  @State envSensors: Sensor[] = [];
  @State alerts: AlertMessage[] = [];
  @State inputText: string = '';
  @State messages: ChatMessage[] = [];
  @State isResponding: boolean = false;
  @State isListening: boolean = false;
  @State pressedKey: string = '';
  @State bgAngle: number = 132;
  @State breathScale: number = 1;
  @State badgeAngle: number = 0;
  @State realTempData: number[] = [22.5, 22.0, 21.8, 22.1, 23.0, 24.1, 25.2, 26.0, 26.5, 25.8, 24.3, 23.1];
  @State realHumidData: number[] = [58, 60, 62, 61, 56, 52, 48, 45, 43, 46, 50, 55];
  private msgId: number = 1;
  private weekEnergy: number[] = [12.1, 13.8, 11.5, 15.2, 14.3, 16.0, 11.9];
  private motionTimer: number = -1;

  aboutToAppear(): void {
    this.messages = [{
      id: 'msg_0',
      role: ChatRole.ASSISTANT,
      content: '已就绪',
      timestamp: Date.now()
    }];
    this.motionTimer = setInterval(() => {
      this.bgAngle = (this.bgAngle + 1) % 360;
      this.breathScale = this.breathScale === 1 ? 1.035 : 1;
      this.badgeAngle += 24;
    }, 1800);
    this.loadData();
  }

  aboutToDisappear(): void {
    if (this.motionTimer !== -1) clearInterval(this.motionTimer);
  }

  async loadData(): Promise<void> {
    const devices = await DeviceApi.getDevices();
    const envSensors = await SensorApi.getByGroup(SensorGroup.ENVIRONMENT);
    const remoteAlerts = await MonitorApi.getAlerts();
    const history = await SensorApi.getTempHumidHistory();
    const fallbackAlerts = MockData.alerts ? MockData.alerts : [];
    this.devices = devices ? devices : [];
    this.envSensors = envSensors ? envSensors.slice(0, 3) : [];
    this.alerts = remoteAlerts && remoteAlerts.length > 0 ? remoteAlerts : fallbackAlerts;
    if (history && history.temp && history.temp.length > 0) {
      this.realTempData = history.temp;
      this.realHumidData = history.humid ? history.humid : [];
    }
  }

  private safeDevices(): Device[] {
    return this.devices ? this.devices : [];
  }

  private safeSensors(): Sensor[] {
    return this.envSensors ? this.envSensors : [];
  }

  private safeAlerts(): AlertMessage[] {
    return this.alerts ? this.alerts : [];
  }

  private safeMessages(): ChatMessage[] {
    return this.messages ? this.messages : [];
  }

  private safeNumbers(values: number[]): number[] {
    return values ? values : [];
  }

  private displayText(value: string | undefined | null, fallback: string): string {
    if (value === undefined || value === null) return fallback;
    const text = value.trim();
    const lower = text.toLowerCase();
    if (text.length === 0 || lower === 'undefined' || lower === 'undifeid' || lower === 'null' || lower === 'nan') return fallback;
    return text;
  }

  private chineseText(value: string | undefined | null, fallback: string): string {
    const text = this.displayText(value, fallback);
    if (/[A-Za-z]/.test(text)) return fallback;
    return text;
  }

  private numberText(value: number | undefined | null, fallback: string): string {
    if (value === undefined || value === null || value !== value) return fallback;
    return `${value}`;
  }

  private onlineCount(): number {
    return this.safeDevices().filter((d: Device) => d.status !== 'offline').length;
  }

  private primaryDevices(): Device[] {
    return this.safeDevices().filter((d: Device) => d.type !== DeviceType.CAMERA).slice(0, 4);
  }

  private unreadAlertCount(): number {
    return this.safeAlerts().filter((a: AlertMessage) => !a.isRead).length;
  }

  private avgOf(values: number[]): number {
    values = this.safeNumbers(values);
    if (values.length === 0) return 0;
    return values.reduce((a: number, b: number) => a + b, 0) / values.length;
  }

  private maxOf(values: number[]): number {
    values = this.safeNumbers(values);
    let max = 0;
    for (const value of values) {
      if (value > max) max = value;
    }
    return max;
  }

  private normalized(value: number, max: number): number {
    if (max <= 0) return 0.1;
    return Math.max(0.1, Math.min(1, value / max));
  }

  private tempMood(): number {
    const temp = this.avgOf(this.realTempData);
    if (temp < 18) return 0.36;
    if (temp > 29) return 0.9;
    return 0.58;
  }

  private humidMood(): number {
    const humid = this.avgOf(this.realHumidData);
    if (humid < 35) return 0.34;
    if (humid > 70) return 0.86;
    return 0.56;
  }

  private statusText(level: number): string {
    if (level > 0.78) return '偏高';
    if (level < 0.42) return '偏低';
    return '舒适';
  }

  private sensorValueText(sensor: Sensor): string {
    if (!sensor || !sensor.current) return '暂无数据';
    const unit = this.chineseText(sensor.current.unit, '');
    if (unit === '°C') return `${this.numberText(sensor.current.value, '-')} 摄氏度`;
    if (unit === '%RH') return `${this.numberText(sensor.current.value, '-')}%`;
    if (unit === 'ppm') return `${this.numberText(sensor.current.value, '-')} 百万分之一`;
    if (/[A-Za-z]/.test(unit)) return this.numberText(sensor.current.value, '-');
    return `${this.numberText(sensor.current.value, '-')}${unit}`;
  }

  private pressed(key: string): boolean {
    return this.pressedKey === key;
  }

  private touchKey(key: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.pressedKey = key;
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.pressedKey = '';
    }
  }

  async send(): Promise<void> {
    const text = this.chineseText(this.inputText.trim(), '查看家里状态');
    if (!text || this.isResponding) return;
    const userMsg: ChatMessage = {
      id: `msg_${this.msgId++}`,
      role: ChatRole.USER,
      content: text,
      timestamp: Date.now()
    };
    this.messages = this.safeMessages().concat([userMsg]);
    this.inputText = '';

    const assistantId = `msg_${this.msgId++}`;
    this.isResponding = true;
    this.messages = this.safeMessages().concat([{
      id: assistantId,
      role: ChatRole.ASSISTANT,
      content: '',
      timestamp: Date.now(),
      isStreaming: true
    }]);

    try {
      await ChatApi.sendStream(
        this.safeMessages().slice(0, -1),
        (partial: string) => {
          const safePartial = this.chineseText(partial, '正在处理指令');
          this.messages = this.safeMessages().map((m: ChatMessage): ChatMessage =>
            m.id === assistantId ? {
              id: assistantId,
              role: ChatRole.ASSISTANT,
              content: safePartial,
              timestamp: m.timestamp,
              isStreaming: true
            } : m
          );
        },
        (finalMsg: ChatMessage) => {
          const newId = `msg_${this.msgId++}`;
          this.messages = this.safeMessages().map((m: ChatMessage): ChatMessage =>
            m.id === assistantId ? {
              id: newId,
              role: ChatRole.ASSISTANT,
              content: this.chineseText(finalMsg.content, '指令已处理'),
              timestamp: finalMsg.timestamp,
              isStreaming: false
            } : m
          );
        }
      );
    } finally {
      this.isResponding = false;
    }
  }

  async startVoice(): Promise<void> {
    if (this.isListening || this.isResponding) return;
    this.isListening = true;
    try {
      const text = await ChatApi.voiceToText('');
      this.inputText = this.chineseText(text, '查看家里状态');
      await this.send();
    } finally {
      this.isListening = false;
    }
  }

  @Builder
  bottomTab(index: number, label: string, icon: Resource) {
    Column({ space: 3 }) {
      SymbolGlyph(icon)
        .fontSize(21)
        .fontColor([this.activePage === index ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY])
      Text(label)
        .fontSize(AppFont.SIZE_CAPTION)
        .fontColor(this.activePage === index ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
        .fontWeight(FontWeight.Bold)
    }
    .layoutWeight(1)
    .height(58)
    .borderRadius(18)
    .backgroundColor(this.activePage === index ? AppColors.PRIMARY_BG : this.pressed(`tab_${index}`) ? AppColors.BG_CARD_TAP : '#FFFFFF')
    .opacity(this.pressed(`tab_${index}`) ? 0.82 : 1)
    .scale({ x: this.pressed(`tab_${index}`) ? 0.96 : 1, y: this.pressed(`tab_${index}`) ? 0.96 : 1 })
    .shadow(this.activePage === index ? { radius: 10, color: '#D7ECFF', offsetX: 0, offsetY: 4 } : {
      radius: 0,
      color: '#FFFFFF',
      offsetX: 0,
      offsetY: 0
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .animation({ duration: 180, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => { this.touchKey(`tab_${index}`, event); })
    .onClick(() => { this.activePage = index; })
  }

  @Builder
  pageBackdrop() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: this.bgAngle,
          colors: [['#FFFFFF', 0.0], ['#ECF8FF', 0.46], ['#D9F0FF', 1.0]]
        })
        .animation({ duration: 900, curve: Curve.Linear })

      Column()
        .width('138%')
        .height(132)
        .borderRadius(66)
        .linearGradient({
          angle: 8,
          colors: [['#FFFFFF', 0.0], ['#A9DDFF', 0.38], ['#FFFFFF', 0.62], ['#FFFFFF', 1.0]]
        })
        .opacity(0.38)
        .rotate({ angle: -9 })
        .position({ x: '-18%', y: '14%' })

      Column()
        .width('136%')
        .height(112)
        .borderRadius(56)
        .linearGradient({
          angle: 16,
          colors: [['#FFFFFF', 0.0], ['#6DBFFF', 0.44], ['#FFFFFF', 0.65], ['#FFFFFF', 1.0]]
        })
        .opacity(0.32)
        .rotate({ angle: 7 })
        .position({ x: '-16%', y: '60%' })

      Circle({ width: 360, height: 360 })
        .fill('#7EC8FF')
        .opacity(0.13)
        .position({ x: '58%', y: '6%' })
      Circle({ width: 260, height: 260 })
        .fill('#BFE8FF')
        .opacity(0.2)
        .position({ x: '-20%', y: '48%' })
      Circle({ width: 180, height: 180 })
        .fill('#4AAAF0')
        .opacity(0.13)
        .position({ x: '68%', y: '72%' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  voiceOrb() {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: this.isListening ? 248 : 198, height: this.isListening ? 248 : 198 })
        .fill(this.isListening ? '#BFE8FF' : '#D9F0FF')
        .opacity(this.isListening ? 0.5 : 0.34)
        .scale({ x: this.breathScale, y: this.breathScale })
        .animation({ duration: 900, curve: Curve.EaseInOut })
      Circle({ width: this.isListening ? 206 : 176, height: this.isListening ? 206 : 176 })
        .fill('#EDF8FF')
        .opacity(this.isListening ? 0.52 : 0.44)
        .scale({ x: this.breathScale === 1 ? 1.02 : 0.98, y: this.breathScale === 1 ? 1.02 : 0.98 })
        .animation({ duration: 900, curve: Curve.EaseInOut })
      Column() {
        Image($r('app.media.hhu_badge_source'))
          .width(122)
          .height(122)
          .objectFit(ImageFit.Contain)
          .borderRadius(61)
          .rotate({ angle: this.badgeAngle })
          .animation({ duration: 1750, curve: Curve.Linear })
      }
      .width(156)
      .height(156)
      .borderRadius(78)
      .backgroundColor(this.isListening ? AppColors.PRIMARY : AppColors.BG_CARD)
      .border({ width: 1, color: this.isListening ? AppColors.PRIMARY : '#FFFFFF' })
      .shadow({ radius: this.isListening ? 28 : 22, color: this.isListening ? '#BFE8FF' : '#D7ECFF', offsetX: 0, offsetY: 12 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .opacity(this.pressed('voice') ? 0.86 : 1)
      .scale({ x: this.pressed('voice') ? 0.94 : this.breathScale, y: this.pressed('voice') ? 0.94 : this.breathScale })
      .animation({ duration: 220, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => { this.touchKey('voice', event); })
      .onClick(() => this.startVoice())
    }
    .width('100%')
    .height(272)
  }

  @Builder
  voicePage() {
    Column() {
      this.voiceOrb()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  energyPanel() {
    Column({ space: AppSpace.BASE }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.drop_fill'))
          .fontSize(22)
          .fontColor([AppColors.PRIMARY])
        Text('能耗趋势')
          .fontSize(AppFont.SIZE_BODY_LG)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        ForEach(this.weekEnergy, (value: number, index: number) => {
          Column() {
            Column()
              .width('100%')
              .height(34 + this.normalized(value, this.maxOf(this.weekEnergy)) * 76)
              .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 6, bottomRight: 6 })
              .linearGradient({
                angle: 180,
                colors: [[index === this.weekEnergy.length - 1 ? '#2378D8' : '#64B7FF', 0.0], ['#DDF2FF', 1.0]]
              })
              .opacity(index === this.weekEnergy.length - 1 ? 0.96 : 0.62)
          }
          .layoutWeight(1)
          .height(124)
          .justifyContent(FlexAlign.End)
        }, (_: number, index: number) => `${index}`)
      }
      .width('100%')
      .height(132)
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(AppSpace.BASE)
    .borderRadius(AppSpace.RADIUS_CARD)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#FFFFFF' })
    .shadow({ radius: 14, color: '#D7ECFF', offsetX: 0, offsetY: 6 })
  }

  @Builder
  flowStrip(level: number, color: string) {
    Row({ space: 6 }) {
      ForEach([0, 1, 2, 3, 4, 5], (index: number) => {
        Column()
          .layoutWeight(1)
          .height(12)
          .borderRadius(6)
          .backgroundColor(index / 5 <= level ? color : '#DCEEFF')
          .opacity(index / 5 <= level ? 0.88 : 0.5)
          .scale({ x: index / 5 <= level ? this.breathScale : 1, y: 1 })
          .animation({ duration: 900, curve: Curve.EaseInOut })
      }, (index: number) => `${index}`)
    }
    .width('100%')
    .height(18)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  conditionCard(label: string, level: number, color: string, icon: Resource) {
    Column({ space: AppSpace.SM }) {
      Row({ space: 8 }) {
        SymbolGlyph(icon)
          .fontSize(22)
          .fontColor([color])
        Text(label)
          .fontSize(AppFont.SIZE_BODY_LG)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(this.statusText(level))
          .fontSize(AppFont.SIZE_FOOTNOTE)
          .fontColor(AppColors.TEXT_TERTIARY)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .width('100%')
          .height(54)
          .borderRadius(18)
          .backgroundColor('#EAF6FF')
        Column()
          .width(`${Math.round(level * 100)}%`)
          .height(54)
          .borderRadius(18)
          .linearGradient({
            angle: 0,
            colors: [[color, 0.0], ['#BFE8FF', 1.0]]
          })
          .opacity(0.72)
        Row() {
          this.flowStrip(level, '#FFFFFF')
        }
        .width('100%')
        .height(54)
        .padding({ left: AppSpace.SM, right: AppSpace.SM })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(54)
    }
    .width('100%')
    .padding(AppSpace.BASE)
    .borderRadius(AppSpace.RADIUS_CARD)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#FFFFFF' })
    .shadow({ radius: 12, color: '#D7ECFF', offsetX: 0, offsetY: 5 })
  }

  @Builder
  sensorRibbon(sensor: Sensor, index: number) {
    Row({ space: AppSpace.SM }) {
      SymbolGlyph($r('sys.symbol.drop_fill'))
        .fontSize(20)
        .fontColor([index % 2 === 0 ? '#2378D8' : AppColors.PRIMARY])
      Text(this.chineseText(sensor.name, '环境'))
        .fontSize(AppFont.SIZE_BODY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)

      Row({ space: 4 }) {
        ForEach([0, 1, 2, 3, 4], (dot: number) => {
          Column()
            .layoutWeight(1)
            .height(dot === index % 5 ? 18 : 10)
            .borderRadius(5)
            .backgroundColor(dot <= index % 5 ? '#2378D8' : '#DCEEFF')
            .opacity(dot <= index % 5 ? 0.72 : 0.42)
        }, (dot: number) => `${dot}`)
      }
      .layoutWeight(1)
      .height(22)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(54)
    .padding({ left: AppSpace.BASE, right: AppSpace.BASE })
    .borderRadius(AppSpace.RADIUS_BASE)
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  statsPage() {
    Column({ space: AppSpace.BASE }) {
      Column({ space: AppSpace.SM }) {
        Text('统计')
          .fontSize(AppFont.SIZE_TITLE_LG)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      this.energyPanel()

      this.conditionCard('温度', this.tempMood(), '#2378D8', $r('sys.symbol.thermometer'))
      this.conditionCard('湿度', this.humidMood(), '#55B8FF', $r('sys.symbol.drop_fill'))

      Column({ space: AppSpace.SM }) {
        ForEach(this.safeSensors(), (sensor: Sensor, index: number) => {
          this.sensorRibbon(sensor, index)
        }, (sensor: Sensor) => sensor.id)
      }
      .width('100%')
      .padding(AppSpace.BASE)
      .borderRadius(AppSpace.RADIUS_CARD)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#FFFFFF' })
    }
    .width('100%')
  }

  @Builder
  centerContent() {
    Column() {
      if (this.activePage === 0) {
        this.voicePage()
      } else {
        this.statsPage()
      }
    }
    .width('100%')
    .constraintSize({ maxWidth: 430 })
    .padding({ top: AppSpace.BASE, bottom: 110 })
  }

  @Builder
  bottomNav() {
    Row({ space: AppSpace.SM }) {
      this.bottomTab(0, '语音', $r('sys.symbol.mic_fill'))
      this.bottomTab(1, '统计', $r('sys.symbol.drop_fill'))
    }
    .width('100%')
    .height(74)
    .padding({ left: AppSpace.SM, right: AppSpace.SM, top: AppSpace.SM, bottom: AppSpace.SM })
    .borderRadius(26)
    .backgroundColor(AppColors.BG_CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
    .shadow({ radius: 16, color: '#D7ECFF', offsetX: 0, offsetY: 6 })
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        this.pageBackdrop()

        Scroll() {
          this.centerContent()
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .padding({ left: AppSpace.BASE, right: AppSpace.BASE })

        Column() {
          this.bottomNav()
        }
        .width('100%')
        .padding({ left: AppSpace.BASE, right: AppSpace.BASE, bottom: AppSpace.BASE })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
