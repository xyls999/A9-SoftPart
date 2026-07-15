/**
 * 数据管理：日志 / 设备 / 环境三选一分页。
 * 全部数据来自现有后端接口，缺失字段明确显示“未上报”。
 */
import { AlertMessage, Device, DeviceStatus, Sensor, SensorType } from '../api/types';
import { DeviceApi } from '../api/deviceApi';
import { EdgeAuthStatus, LogApi, SecurityLogStats } from '../api/logApi';
import { SensorApi } from '../api/sensorApi';
import { BackendAreaStat, BackendFeatureStats, BackendStatItem, SystemStatsApi } from '../api/systemStatsApi';
import { TacticalMotion, TacticalSpace, TacticalTheme } from '../theme/TacticalTheme';

@Component
export struct HistoryPage {
  @Prop isDark: boolean = true;
  @State activeSection: number = 0;
  @State devices: Device[] = [];
  @State alerts: AlertMessage[] = [];
  @State sensors: Sensor[] = [];
  @State tempHistory: number[] = [];
  @State humidHistory: number[] = [];
  @State historyLabels: string[] = [];
  @State stats: BackendFeatureStats = {
    available: false,
    timestamp: '',
    deviceTotal: 0,
    deviceOnline: 0,
    deviceOffline: 0,
    deviceOnlineRate: 0,
    temperatureValue: null,
    temperatureUnit: '°C',
    temperatureOnline: false,
    humidityValue: null,
    humidityUnit: '%RH',
    humidityOnline: false,
    items: [],
    areas: []
  };
  @State securityStats: SecurityLogStats = {
    available: false, today: 0, total: 0, critical: 0, high: 0, medium: 0, low: 0
  };
  @State authStatus: EdgeAuthStatus = {
    available: false, enableAuth: false, doorPasswordRequired: false, sharedKeySet: false,
    authAlgorithm: '', doorPasswordAlgorithm: ''
  };
  @State logsAvailable: boolean = false;
  @State logsComplete: boolean = false;
  @State devicesAvailable: boolean = false;
  @State sensorsAvailable: boolean = false;
  @State historyAvailable: boolean = false;
  @State isLoading: boolean = true;
  @State pressedSection: number = -1;

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    const deviceRequest = DeviceApi.getDeviceSnapshot();
    const logRequest = LogApi.getSnapshot();
    const sensorRequest = SensorApi.getSensorSnapshot();
    const historyRequest = SensorApi.getTempHumidHistory();
    const statsRequest = SystemStatsApi.getFeatureStats();

    const deviceSnapshot = await deviceRequest;
    this.devices = deviceSnapshot.devices;
    this.devicesAvailable = deviceSnapshot.available;

    const logSnapshot = await logRequest;
    this.alerts = logSnapshot.alerts;
    this.securityStats = logSnapshot.securityStats;
    this.authStatus = logSnapshot.authStatus;
    this.logsAvailable = logSnapshot.available;
    this.logsComplete = logSnapshot.complete;

    const sensorSnapshot = await sensorRequest;
    this.sensors = sensorSnapshot.sensors;
    this.sensorsAvailable = sensorSnapshot.available;

    const history = await historyRequest;
    this.tempHistory = history.temp;
    this.humidHistory = history.humid;
    this.historyLabels = history.labels;
    this.historyAvailable = history.available;

    this.stats = await statsRequest;
    this.isLoading = false;
  }

  private selectSection(index: number): void {
    if (this.activeSection === index) return;
    this.activeSection = index;
  }

  private dangerAlerts(): AlertMessage[] {
    return this.alerts.filter((alert: AlertMessage) => alert.level === 'danger' || alert.level === 'warning');
  }

  private normalAlerts(): AlertMessage[] {
    return this.alerts.filter((alert: AlertMessage) => alert.level === 'info');
  }

  private levelCount(level: string): number {
    return this.alerts.filter((alert: AlertMessage) => alert.level === level).length;
  }

  private onlineDevices(): Device[] {
    return this.devices.filter((device: Device) => device.status !== DeviceStatus.OFFLINE);
  }

  private deviceRate(): number {
    if (this.stats.available && this.stats.deviceTotal > 0) return this.stats.deviceOnlineRate;
    if (!this.devicesAvailable || this.devices.length === 0) return -1;
    return this.onlineDevices().length / this.devices.length * 100;
  }

  private deviceSummary(): string {
    if (this.stats.available) return `${this.stats.deviceOnline} 在线 / ${this.stats.deviceOffline} 离线`;
    if (this.devicesAvailable) return `${this.onlineDevices().length} 在线 / ${this.devices.length - this.onlineDevices().length} 离线`;
    return '设备接口不可达';
  }

  private sensorOf(type: SensorType): Sensor | undefined {
    return this.sensors.find((sensor: Sensor) => sensor.type === type && sensor.current.unit !== '离线');
  }

  private maxNumber(values: number[]): number {
    let max = 0;
    for (const value of values) if (value > max) max = value;
    return max;
  }

  private minNumber(values: number[]): number {
    if (values.length === 0) return 0;
    let min = values[0];
    for (const value of values) if (value < min) min = value;
    return min;
  }

  private barHeight(value: number, values: number[]): number {
    const min = this.minNumber(values);
    const max = this.maxNumber(values);
    if (max <= min) return 72;
    return 24 + (value - min) / (max - min) * 72;
  }

  private chartValues(values: number[]): number[] {
    if (values.length <= 18) return values;
    return values.slice(values.length - 18);
  }

  private uptimeMax(): number {
    let max = 0;
    for (const device of this.devices) {
      if (device.uptimeSeconds !== undefined && device.uptimeSeconds > max) max = device.uptimeSeconds;
    }
    return max;
  }

  private uptimeProgress(device: Device): number {
    const max = this.uptimeMax();
    if (device.uptimeSeconds === undefined || max <= 0) return -1;
    return Math.max(0, Math.min(100, device.uptimeSeconds / max * 100));
  }

  private durationText(seconds: number | undefined): string {
    if (seconds === undefined || seconds < 0) return '未上报';
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor(seconds % 86400 / 3600);
    const minutes = Math.floor(seconds % 3600 / 60);
    if (days > 0) return `${days}天 ${hours}小时`;
    if (hours > 0) return `${hours}小时 ${minutes}分钟`;
    return `${minutes}分钟`;
  }

  private timeText(value: string | undefined): string {
    if (!value) return '未上报';
    const ts = Date.parse(value.replace(' ', 'T'));
    if (ts !== ts) return value;
    const date = new Date(ts);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    const hour = `${date.getHours()}`.padStart(2, '0');
    const minute = `${date.getMinutes()}`.padStart(2, '0');
    return `${month}-${day} ${hour}:${minute}`;
  }

  private alertTime(timestamp: number): string {
    if (timestamp <= 0) return '--:--';
    const date = new Date(timestamp);
    const hour = `${date.getHours()}`.padStart(2, '0');
    const minute = `${date.getMinutes()}`.padStart(2, '0');
    return `${hour}:${minute}`;
  }

  private currentText(type: SensorType, fallbackUnit: string): string {
    if (type === SensorType.TEMPERATURE && this.stats.temperatureOnline && this.stats.temperatureValue !== null) {
      return `${this.stats.temperatureValue}${this.stats.temperatureUnit || fallbackUnit}`;
    }
    if (type === SensorType.HUMIDITY && this.stats.humidityOnline && this.stats.humidityValue !== null) {
      return `${this.stats.humidityValue}${this.stats.humidityUnit || fallbackUnit}`;
    }
    const sensor = this.sensorOf(type);
    if (!sensor) return '--';
    return `${sensor.current.value}${sensor.current.unit || fallbackUnit}`;
  }

  private activeInterfaceState(): number {
    if (this.activeSection === 0) {
      if (this.logsComplete) return 2;
      return this.logsAvailable ? 1 : 0;
    }
    if (this.activeSection === 1) {
      if (this.devicesAvailable && this.stats.available) return 2;
      return this.devicesAvailable || this.stats.available ? 1 : 0;
    }
    const available = (this.sensorsAvailable ? 1 : 0) + (this.historyAvailable ? 1 : 0) + (this.stats.available ? 1 : 0);
    if (available === 3) return 2;
    return available > 0 ? 1 : 0;
  }

  private interfaceLabel(): string {
    const state = this.activeInterfaceState();
    if (state === 2) return '● 在线';
    if (state === 1) return '◐ 部分在线';
    return '○ 离线';
  }

  private panel(): string { return TacticalTheme.panel(this.isDark); }
  private raised(): string { return TacticalTheme.panelRaised(this.isDark); }
  private text(): string { return TacticalTheme.text(this.isDark); }
  private secondary(): string { return TacticalTheme.textSecondary(this.isDark); }
  private muted(): string { return TacticalTheme.textMuted(this.isDark); }
  private frameTone(): string { return TacticalTheme.border(this.isDark); }
  private accent(): string { return TacticalTheme.accent(this.isDark); }
  private danger(): string { return TacticalTheme.danger(this.isDark); }

  @Builder
  sectionSelector(index: number, label: string, icon: Resource) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Row({ space: 8 }) {
        SymbolGlyph(icon)
          .fontSize(18)
          .fontColor([this.activeSection === index ? TacticalTheme.inverse(this.isDark) : this.accent()])
        Text(label)
          .fontSize(14)
          .fontFamily('HarmonyOS Sans SC')
          .fontWeight(FontWeight.Bold)
          .fontColor(this.activeSection === index ? TacticalTheme.inverse(this.isDark) : this.text())
      }
      .width('100%')
      .padding({ left: 12, bottom: 13 })
      .alignItems(VerticalAlign.Center)

      Column()
        .width(this.activeSection === index ? '100%' : 22)
        .height(4)
        .backgroundColor(this.activeSection === index ? TacticalTheme.inverse(this.isDark) : this.accent())
        .animation({ duration: TacticalMotion.SWITCH, curve: Curve.EaseOut })
    }
    .layoutWeight(1)
    .height(56)
    .backgroundColor(this.activeSection === index ? this.accent() : this.panel())
    .border({ width: 1, color: this.activeSection === index ? this.accent() : this.frameTone() })
    .opacity(this.pressedSection === index ? 0.7 : 1)
    .animation({ duration: TacticalMotion.SWITCH, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) this.pressedSection = index;
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedSection = -1;
    })
    .onClick(() => this.selectSection(index))
  }

  @Builder
  metricTile(value: string, label: string, danger: boolean = false) {
    Column({ space: 4 }) {
      Column().width(24).height(2).backgroundColor(danger ? this.danger() : this.accent())
      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(danger ? this.danger() : this.text())
        .maxLines(1)
      Text(label)
        .fontSize(11)
        .fontColor(this.muted())
    }
    .layoutWeight(1)
    .height(88)
    .padding(10)
    .backgroundColor(this.raised())
    .border({ width: { bottom: 2 }, color: danger ? this.danger() : this.accent() })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  severityBar(label: string, count: number, color: string) {
    Column({ space: 5 }) {
      Row() {
        Text(label).fontSize(12).fontColor(this.secondary())
        Blank()
        Text(`${count}`).fontSize(12).fontWeight(FontWeight.Bold).fontColor(color)
      }
      .width('100%')
      Progress({ value: this.alerts.length > 0 ? count / this.alerts.length * 100 : 0,
        total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(7)
        .color(color)
        .backgroundColor(TacticalTheme.panelMuted(this.isDark))
        .style({ strokeWidth: 7 })
    }
    .width('100%')
  }

  @Builder
  alertRow(alert: AlertMessage, important: boolean) {
    Row({ space: 10 }) {
      Column()
        .width(4)
        .height(48)
        .backgroundColor(important ? this.danger() : this.accent())
      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text(alert.source)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.text())
            .maxLines(1)
          if (!alert.isRead) {
            Text('新')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(important ? this.danger() : this.accent())
          }
        }
        Text(alert.content)
          .fontSize(12)
          .fontColor(this.secondary())
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(this.alertTime(alert.timestamp))
        .fontSize(11)
        .fontColor(this.muted())
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .padding({ top: 8, bottom: 8, right: 10 })
    .backgroundColor(important ? TacticalTheme.dangerSoft(this.isDark) : this.raised())
    .border({ width: { left: important ? 3 : 1 }, color: important ? this.danger() : this.frameTone() })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  emptyState(text: string) {
    Column({ space: 8 }) {
      Text('暂无数据')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.muted())
      Text(text)
        .fontSize(12)
        .fontColor(this.secondary())
    }
    .width('100%')
    .height(112)
    .backgroundColor(this.panel())
    .border({ width: 1, color: this.frameTone(), style: BorderStyle.Dashed })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  logsPage() {
    Column({ space: 14 }) {
      Row({ space: 8 }) {
        this.metricTile(`${this.alerts.length}`, '日志总数')
        this.metricTile(`${this.dangerAlerts().length}`, '重点信息', true)
        this.metricTile(`${this.normalAlerts().length}`, '普通信息')
      }
      .width('100%')

      Column({ space: 10 }) {
        this.severityBar('危险', this.levelCount('danger'), this.danger())
        this.severityBar('警告', this.levelCount('warning'), this.accent())
        this.severityBar('普通', this.levelCount('info'), this.muted())
      }
      .width('100%')
      .padding(14)
      .backgroundColor(this.panel())
      .border({ width: { bottom: 1 }, color: this.frameTone() })

      Row({ space: 10 }) {
        Column({ space: 3 }) {
          Text('边缘鉴权 / V5.2').fontSize(9).fontWeight(FontWeight.Bold).fontColor(this.accent())
          Text(this.authStatus.available ? (this.authStatus.enableAuth ? '边缘验签已启用' : '边缘验签兼容模式') : '鉴权状态接口离线')
            .fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.text())
          Text(this.authStatus.available ?
            `门禁密码 ${this.authStatus.doorPasswordRequired ? '必需' : '未启用'} · 密钥 ${this.authStatus.sharedKeySet ? '已配置' : '未配置'}` :
            '未读取任何鉴权默认值')
            .fontSize(10).fontColor(this.muted())
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 2 }) {
          Text(this.securityStats.available ? `${this.securityStats.today}` : '--')
            .fontSize(25).fontWeight(FontWeight.Bold).fontColor(this.securityStats.today > 0 ? this.danger() : this.accent())
          Text('今日拦截').fontSize(9).fontColor(this.muted())
        }.alignItems(HorizontalAlign.End)
      }
      .width('100%').padding(12).backgroundColor(this.raised()).border({ width: { bottom: 1 }, color: this.frameTone() })

      Column({ space: 8 }) {
        Text('重点危险信息').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.text())
        if (this.dangerAlerts().length > 0) {
          ForEach(this.dangerAlerts(), (alert: AlertMessage) => { this.alertRow(alert, true) }, (alert: AlertMessage) => alert.id)
        } else {
          this.emptyState(this.logsAvailable ? '暂无危险或警告日志' : '日志与安全事件接口不可达')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('普通信息').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.text())
        if (this.normalAlerts().length > 0) {
          ForEach(this.normalAlerts(), (alert: AlertMessage) => { this.alertRow(alert, false) }, (alert: AlertMessage) => alert.id)
        } else {
          this.emptyState(this.logsAvailable ? '暂无普通日志' : '日志接口不可达')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  deviceRow(device: Device) {
    Column({ space: 9 }) {
      Row({ space: 10 }) {
        Stack() {
          Column().width(36).height(36).backgroundColor(TacticalTheme.panelMuted(this.isDark))
          SymbolGlyph(device.icon).fontSize(20).fontColor([device.status === DeviceStatus.OFFLINE ? this.muted() : this.accent()])
        }
        .width(36).height(36)
        Column({ space: 3 }) {
          Text(device.name).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.text()).maxLines(1)
          Text(`${device.room} / ${device.id}`).fontSize(10).fontColor(this.muted()).maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Row({ space: 5 }) {
          Circle({ width: 7, height: 7 }).fill(device.status === DeviceStatus.OFFLINE ? TacticalTheme.offline(this.isDark) : this.accent())
          Text(device.status === DeviceStatus.OFFLINE ? '离线' : '在线')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(device.status === DeviceStatus.OFFLINE ? this.muted() : this.accent())
        }
      }
      .width('100%')
      Row() {
        Column({ space: 2 }) {
          Text('累计在线').fontSize(10).fontColor(this.muted())
          Text(this.durationText(device.uptimeSeconds)).fontSize(12).fontColor(this.secondary())
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 2 }) {
          Text('最近在线').fontSize(10).fontColor(this.muted())
          Text(this.timeText(device.lastSeen || device.onlineSince)).fontSize(12).fontColor(this.secondary())
        }.layoutWeight(1).alignItems(HorizontalAlign.End)
      }
      .width('100%')
      if (this.uptimeProgress(device) >= 0) {
        Progress({ value: this.uptimeProgress(device),
          total: 100, type: ProgressType.Linear })
          .width('100%').height(5).color(this.accent()).backgroundColor(TacticalTheme.panelMuted(this.isDark)).style({ strokeWidth: 5 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.raised())
    .border({ width: { left: 3 }, color: device.status === DeviceStatus.OFFLINE ? this.frameTone() : this.accent() })
  }

  @Builder
  areaRow(area: BackendAreaStat) {
    Row({ space: 10 }) {
      Column().width(3).height(38).backgroundColor(area.online ? this.accent() : TacticalTheme.offline(this.isDark))
      Column({ space: 3 }) {
        Text(area.name).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.text())
        Text(area.ip || '地址未上报').fontSize(10).fontColor(this.muted())
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Column({ space: 3 }) {
        Text(area.online ? '在线' : '离线').fontSize(11).fontWeight(FontWeight.Bold).fontColor(area.online ? this.accent() : this.muted())
        Text(this.timeText(area.lastSeen)).fontSize(10).fontColor(this.secondary())
      }.alignItems(HorizontalAlign.End)
    }
    .width('100%').height(58).padding({ left: 10, right: 10 })
    .backgroundColor(this.panel()).border({ width: { bottom: 1 }, color: this.frameTone() }).alignItems(VerticalAlign.Center)
  }

  @Builder
  devicesPage() {
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        Stack() {
          Progress({ value: 100, total: 100, type: ProgressType.Ring })
            .width(92).height(92).color(TacticalTheme.panelMuted(this.isDark)).style({ strokeWidth: 7 })
          Progress({ value: Math.max(0, this.deviceRate()), total: 100, type: ProgressType.Ring })
            .width(92).height(92).color(this.accent()).style({ strokeWidth: 7 })
          Column({ space: 0 }) {
            Text(this.deviceRate() >= 0 ? `${Math.round(this.deviceRate())}` : '--')
              .fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.text())
            Text('%').fontSize(10).fontColor(this.muted())
          }
        }.width(92).height(92)
        Column({ space: 7 }) {
          Text('设备在线状态').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.text())
          Text(this.deviceSummary())
            .fontSize(13).fontColor(this.secondary())
          Text('在线时长与最近在线仅展示后端上报值').fontSize(10).fontColor(this.muted())
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%').padding(14).backgroundColor(this.panel()).border({ width: { bottom: 1 }, color: this.frameTone() }).alignItems(VerticalAlign.Center)

      if (this.stats.areas.length > 0) {
        Column({ space: 7 }) {
          Text('区域链路').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.text())
          ForEach(this.stats.areas, (area: BackendAreaStat) => { this.areaRow(area) }, (area: BackendAreaStat) => area.key)
        }.width('100%').alignItems(HorizontalAlign.Start)
      }

      Column({ space: 8 }) {
        Text('设备明细').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.text())
        if (this.devices.length > 0) {
          ForEach(this.devices, (device: Device) => { this.deviceRow(device) }, (device: Device) => device.id)
        } else {
          this.emptyState(this.devicesAvailable ? '后端设备列表为空' : '设备接口不可达，未生成默认设备')
        }
      }.width('100%').alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  historyChart(title: string, current: string, values: number[], color: string) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 2 }) {
          Text(title).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.secondary())
          Text(values.length > 0 ? `${values.length} 个真实采样点` : '暂无历史采样').fontSize(10).fontColor(this.muted())
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text(current).fontSize(26).fontWeight(FontWeight.Bold).fontColor(color)
      }.width('100%').alignItems(VerticalAlign.Center)

      if (values.length > 0) {
        Row({ space: 3 }) {
          ForEach(this.chartValues(values), (value: number, index: number) => {
            Column() {
              Column().width('100%')
                .height(this.barHeight(value, this.chartValues(values)))
                .backgroundColor(color)
                .opacity(0.38 + index / Math.max(1, this.chartValues(values).length - 1) * 0.62)
            }.layoutWeight(1).height(104).justifyContent(FlexAlign.End)
          }, (_: number, index: number) => `${index}`)
        }.width('100%').height(104).alignItems(VerticalAlign.Bottom)
        Row() {
          Text(this.historyLabels.length > 0 ? this.historyLabels[0] : '早').fontSize(9).fontColor(this.muted())
          Blank()
          Text(this.historyLabels.length > 0 ? this.historyLabels[this.historyLabels.length - 1] : '现在').fontSize(9).fontColor(this.muted())
        }.width('100%')
      } else {
        this.emptyState(`${title}暂无真实历史数据`)
      }
    }
    .width('100%').padding(14).backgroundColor(this.raised()).border({ width: { bottom: 1 }, color: this.frameTone() })
  }

  @Builder
  telemetryRow(stat: BackendStatItem) {
    Column({ space: 7 }) {
      Row() {
        Column({ space: 2 }) {
          Text(stat.label).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.text())
          Text(stat.detail).fontSize(10).fontColor(this.muted()).maxLines(1)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text(stat.value).fontSize(13).fontWeight(FontWeight.Bold).fontColor(stat.online ? this.accent() : this.muted())
      }.width('100%')
      if (stat.progress >= 0) {
        Progress({ value: stat.progress, total: 100, type: ProgressType.Linear })
          .width('100%').height(5).color(stat.online ? this.accent() : this.muted())
          .backgroundColor(TacticalTheme.panelMuted(this.isDark)).style({ strokeWidth: 5 })
      }
    }
    .width('100%').padding(10).backgroundColor(this.panel()).border({ width: { bottom: 1 }, color: this.frameTone() })
  }

  @Builder
  environmentPage() {
    Column({ space: 14 }) {
      Row({ space: 8 }) {
        this.metricTile(this.currentText(SensorType.TEMPERATURE, '°C'), '当前温度')
        this.metricTile(this.currentText(SensorType.HUMIDITY, '%RH'), '当前湿度')
      }.width('100%')

      Column({ space: 14 }) {
        this.historyChart('温度趋势', this.currentText(SensorType.TEMPERATURE, '°C'), this.tempHistory, this.accent())
        this.historyChart('湿度趋势', this.currentText(SensorType.HUMIDITY, '%RH'), this.humidHistory,
          TacticalTheme.humidity(this.isDark))
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('室内状态矩阵').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.text())
        if (this.stats.items.length > 2) {
          ForEach(this.stats.items.slice(2), (stat: BackendStatItem) => { this.telemetryRow(stat) }, (stat: BackendStatItem) => stat.key)
        } else {
          this.emptyState(this.stats.available ? '后端没有返回室内状态统计' : '环境统计接口不可达，未生成默认数据')
        }
      }.width('100%').alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  loadingState() {
    Row({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.clock_fill'))
        .fontSize(20)
        .fontColor([this.accent()])
      Column({ space: 4 }) {
        Text('正在读取数据')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.text())
        Text('日志、设备和环境信息将按后端返回结果展示')
          .fontSize(11)
          .fontColor(this.muted())
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(88)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.panel())
    .border({ width: { left: 3, bottom: 1 }, color: this.frameTone() })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 3 }) {
          Text('数据管理').fontSize(26).fontFamily('HarmonyOS Sans SC')
            .fontWeight(FontWeight.Bolder).fontColor(this.text())
          Text('日志、设备与环境').fontSize(11).fontColor(this.muted())
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Text(this.interfaceLabel()).fontSize(10).fontWeight(FontWeight.Bold)
          .fontColor(this.activeInterfaceState() > 0 ? this.accent() : this.muted())
      }
      .width('100%')
      .height(66)
      .alignItems(VerticalAlign.Center)

      Row({ space: 6 }) {
        this.sectionSelector(0, '日志', $r('sys.symbol.clock_fill'))
        this.sectionSelector(1, '设备', $r('sys.symbol.house_fill'))
        this.sectionSelector(2, '环境', $r('sys.symbol.thermometer'))
      }.width('100%')

      if (this.isLoading) {
        this.loadingState()
      } else {
        Column() {
          if (this.activeSection === 0) {
            this.logsPage()
          } else if (this.activeSection === 1) {
            this.devicesPage()
          } else {
            this.environmentPage()
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: TacticalSpace.PAGE, right: TacticalSpace.PAGE, top: 8, bottom: 104 })
  }
}
