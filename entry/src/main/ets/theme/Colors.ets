/**
 * 设备主控配色系统
 * 参考系统级智慧语音首页，白灰底、克制蓝色强调。
 */

export class AppColors {
  /** ===== 背景层 ===== */
  static readonly BG_PAGE: string = '#F6F7F9';
  static readonly BG_CARD: string = '#FFFFFF';
  static readonly BG_CARD_TAP: string = '#EEF3FA';
  static readonly BG_GROUP: string = '#F0F2F5';
  static readonly BG_INPUT: string = '#FFFFFF';

  /** ===== 分隔线 / 细线 ===== */
  static readonly DIVIDER: string = '#E2E6EC';
  static readonly HAIRLINE: string = '#11182710';

  /** ===== 主交互色 ===== */
  static readonly PRIMARY: string = '#3B82F6';
  static readonly PRIMARY_TAP: string = '#2563EB';
  static readonly PRIMARY_LIGHT: string = '#D7ECFF';
  static readonly PRIMARY_BG: string = '#EFF6FF';

  /** ===== 文字层级 ===== */
  static readonly TEXT_PRIMARY: string = '#111827';
  static readonly TEXT_SECONDARY: string = '#4B5563';
  static readonly TEXT_TERTIARY: string = '#8A94A6';
  static readonly TEXT_DISABLED: string = '#C8CED8';
  static readonly TEXT_INVERSE: string = '#FFFFFF';

  /** ===== 功能语义色（低饱和，克制） ===== */
  static readonly SUCCESS: string = '#16A34A';
  static readonly WARNING: string = '#D97706';
  static readonly DANGER: string = '#DC2626';
  static readonly ONLINE: string = '#16A34A';
  static readonly OFFLINE: string = '#A8B0BE';

  /** ===== 设备类型图标色（仅用于图标，弱化） ===== */
  static readonly DEVICE_FAN: string = '#3B82F6';
  static readonly DEVICE_AC: string = '#0EA5E9';
  static readonly DEVICE_DOOR: string = '#64748B';
  static readonly DEVICE_LIGHT: string = '#F59E0B';
  static readonly DEVICE_CAMERA: string = '#16A34A';

  /** ===== 设备类型浅色背景（图标圆形底） ===== */
  static readonly DEVICE_FAN_BG: string = '#EFF6FF';
  static readonly DEVICE_AC_BG: string = '#ECFEFF';
  static readonly DEVICE_DOOR_BG: string = '#F1F5F9';
  static readonly DEVICE_LIGHT_BG: string = '#FFFBEB';
  static readonly DEVICE_CAMERA_BG: string = '#F0FDF4';

  /** ===== 传感器类型图标色 ===== */
  static readonly SENSOR_TEMP: string = '#F59E0B';
  static readonly SENSOR_HUMID: string = '#0EA5E9';
  static readonly SENSOR_AIR: string = '#16A34A';
  static readonly SENSOR_LIGHT: string = '#EAB308';
  static readonly SENSOR_PIR: string = '#64748B';
  static readonly SENSOR_DOOR: string = '#64748B';
  static readonly SENSOR_SMOKE: string = '#DC2626';
  static readonly SENSOR_POWER: string = '#3B82F6';

  // —— 兼容旧引用（统一指向新值，避免大范围改名出错）——
  static readonly BLUE: string = '#3B82F6';
  static readonly PURPLE: string = '#64748B';
  static readonly GREEN: string = '#16A34A';
  static readonly ORANGE: string = '#F59E0B';
  static readonly RED: string = '#DC2626';
  static readonly CYAN: string = '#0EA5E9';
  static readonly PINK: string = '#64748B';
  static readonly YELLOW: string = '#EAB308';
  static readonly INDIGO: string = '#2563EB';
  static readonly TEAL: string = '#0EA5E9';
}
