import { AlertMessage, Camera, Device, DeviceStatus, DeviceType, Sensor, SensorGroup, SensorType } from './types';

type AnyRecord = Record<string, Object>;

function textOf(value: Object | undefined, fallback: string): string {
  if (typeof value === 'string') {
    const text = value.trim();
    const lower = text.toLowerCase();
    if (text.length === 0 || lower === 'undefined' || lower === 'undifeid' || lower === 'null' || lower === 'nan') {
      return fallback;
    }
    return text;
  }
  return fallback;
}

function visibleTextOf(value: Object | undefined, fallback: string): string {
  const text = textOf(value, fallback);
  if (/[A-Za-z]/.test(text)) {
    return fallback;
  }
  return text;
}

function numberOf(value: Object | undefined, fallback: number): number {
  if (typeof value === 'number') {
    if (value !== value) {
      return fallback;
    }
    return value;
  }
  return fallback;
}

function boolOf(value: Object | undefined, fallback: boolean): boolean {
  if (typeof value === 'boolean') {
    return value;
  }
  return fallback;
}

function alertLevelOf(value: Object | undefined): 'info' | 'warning' | 'danger' {
  if (typeof value === 'string' && (value === 'warning' || value === 'danger' || value === 'info')) {
    return value as 'info' | 'warning' | 'danger';
  }
  return 'info';
}

export function iconFromName(name: string, fallback: Resource = $r('sys.symbol.house')): Resource {
  switch (name) {
    case 'fan_fill_1':
    case 'fan':
      return $r('sys.symbol.fan_fill_1');
    case 'air_fill':
    case 'air':
      return $r('sys.symbol.air_fill');
    case 'door_service':
    case 'door':
      return $r('sys.symbol.door_service');
    case 'lightbulb':
    case 'light':
      return $r('sys.symbol.lightbulb');
    case 'camera_fill':
    case 'camera':
      return $r('sys.symbol.camera_fill');
    case 'thermometer':
      return $r('sys.symbol.thermometer');
    case 'drop':
    case 'drop_fill':
      return $r('sys.symbol.drop');
    case 'wind':
      return $r('sys.symbol.wind');
    case 'sun_max':
      return $r('sys.symbol.sun_max');
    case 'figure_arms_open':
      return $r('sys.symbol.figure_arms_open');
    case 'doors_and_windows_closed':
      return $r('sys.symbol.doors_and_windows_closed');
    case 'flame_fill':
      return $r('sys.symbol.flame_fill');
    case 'bolt_fill':
      return $r('sys.symbol.bolt_fill');
    case 'battery_fill':
      return $r('sys.symbol.battery_fill');
    case 'person_fill':
      return $r('sys.symbol.person_fill');
    case 'figure_walk':
      return $r('sys.symbol.figure_walk');
    default:
      return fallback;
  }
}

export function normalizeDevice(raw: AnyRecord): Device {
  const type = textOf(raw.type, DeviceType.LIGHT) as DeviceType;
  const iconName = textOf(raw.icon, type);
  return {
    id: textOf(raw.id, `device_${Date.now()}`),
    name: visibleTextOf(raw.name, '智能设备'),
    type,
    status: textOf(raw.status, DeviceStatus.ONLINE) as DeviceStatus,
    room: visibleTextOf(raw.room, '全屋'),
    icon: iconFromName(iconName),
    primaryValue: numberOf(raw.primaryValue, 0),
    isOn: boolOf(raw.isOn, false),
    mode: typeof raw.mode === 'string' ? visibleTextOf(raw.mode, '自动') : undefined,
    battery: typeof raw.battery === 'number' ? raw.battery : undefined
  };
}

export function normalizeSensor(raw: AnyRecord): Sensor {
  const current = raw.current as AnyRecord | undefined;
  const type = textOf(raw.type, SensorType.TEMPERATURE) as SensorType;
  const historyRaw = raw.history as Array<number> | undefined;
  return {
    id: textOf(raw.id, `sensor_${Date.now()}`),
    name: visibleTextOf(raw.name, '传感器'),
    type,
    group: textOf(raw.group, SensorGroup.OTHER) as SensorGroup,
    room: visibleTextOf(raw.room, '全屋'),
    icon: iconFromName(textOf(raw.icon, type)),
    current: {
      value: current ? numberOf(current.value, 0) : 0,
      unit: current ? textOf(current.unit, '') : '',
      timestamp: current ? numberOf(current.timestamp, Date.now()) : Date.now()
    },
    history: historyRaw ?? [],
    thresholdMin: typeof raw.thresholdMin === 'number' ? raw.thresholdMin : undefined,
    thresholdMax: typeof raw.thresholdMax === 'number' ? raw.thresholdMax : undefined,
    protocol: textOf(raw.protocol, 'wifi') as 'wifi' | 'starflash',
    isAlert: boolOf(raw.isAlert, false)
  };
}

export function normalizeCamera(raw: AnyRecord): Camera {
  return {
    id: textOf(raw.id, `camera_${Date.now()}`),
    name: visibleTextOf(raw.name, '摄像头'),
    room: visibleTextOf(raw.room, '全屋'),
    status: textOf(raw.status, DeviceStatus.ONLINE) as DeviceStatus,
    isRecording: boolOf(raw.isRecording, false),
    resolution: textOf(raw.resolution, '1080P'),
    previewColor: textOf(raw.previewColor, '#1D7F68')
  };
}

export function normalizeAlert(raw: AnyRecord): AlertMessage {
  return {
    id: textOf(raw.id, `alert_${Date.now()}`),
    source: visibleTextOf(raw.source, '系统告警'),
    content: visibleTextOf(raw.content, '暂无详细说明'),
    level: alertLevelOf(raw.level),
    timestamp: numberOf(raw.timestamp, Date.now()),
    isRead: boolOf(raw.isRead, false)
  };
}
