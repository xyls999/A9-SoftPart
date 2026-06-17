/**
 * 智能家居 App 配色系统 · 经典鸿蒙浅色风格
 * 纯白卡片 + 浅灰背景 + 鸿蒙系统蓝主色
 * 参考: 华为智慧生活 / 米家 11.0 / HarmonyOS 设计规范
 */

export class AppColors {
  /** ===== 背景层（纯白 + 浅灰，无深色玻璃） ===== */
  static readonly BG_PAGE: string = '#F5F6F8';        // 页面底色（浅灰）
  static readonly BG_CARD: string = '#FFFFFF';         // 卡片白底
  static readonly BG_CARD_TAP: string = '#F2F3F5';     // 卡片按下态
  static readonly BG_GROUP: string = '#FAFAFA';        // 分组浅底
  static readonly BG_INPUT: string = '#F2F3F5';        // 输入框底

  /** ===== 分隔线 / 细线 ===== */
  static readonly DIVIDER: string = '#E5E6EB';         // 主分隔线
  static readonly HAIRLINE: string = '#0000000F';      // 极细发丝线

  /** ===== 鸿蒙主色（系统蓝，交互态统一色） ===== */
  static readonly PRIMARY: string = '#007DFF';         // 主色
  static readonly PRIMARY_TAP: string = '#3385FF';     // 按下态
  static readonly PRIMARY_LIGHT: string = '#0A007DFF'; // 浅蓝背景(8%透明)——用于选中态底
  static readonly PRIMARY_BG: string = '#E6F0FF';      // 浅蓝胶囊背景

  /** ===== 文字层级（深色文字于浅底） ===== */
  static readonly TEXT_PRIMARY: string = '#181818';    // 主文字
  static readonly TEXT_SECONDARY: string = '#666666';  // 次文字
  static readonly TEXT_TERTIARY: string = '#999999';   // 辅助文字
  static readonly TEXT_DISABLED: string = '#CCCCCC';   // 禁用文字
  static readonly TEXT_INVERSE: string = '#FFFFFF';    // 反白（用于主色按钮上）

  /** ===== 功能语义色（低饱和，克制） ===== */
  static readonly SUCCESS: string = '#379B5E';
  static readonly WARNING: string = '#FA8C16';
  static readonly DANGER: string = '#E8402E';
  static readonly ONLINE: string = '#379B5E';
  static readonly OFFLINE: string = '#BFBFBF';

  /** ===== 设备类型图标色（仅用于图标，弱化） ===== */
  static readonly DEVICE_FAN: string = '#4DA6FF';
  static readonly DEVICE_AC: string = '#007DFF';
  static readonly DEVICE_DOOR: string = '#9B6DFF';
  static readonly DEVICE_LIGHT: string = '#F5A623';
  static readonly DEVICE_CAMERA: string = '#379B5E';

  /** ===== 设备类型浅色背景（图标圆形底） ===== */
  static readonly DEVICE_FAN_BG: string = '#E8F4FF';
  static readonly DEVICE_AC_BG: string = '#E6F0FF';
  static readonly DEVICE_DOOR_BG: string = '#F0E8FF';
  static readonly DEVICE_LIGHT_BG: string = '#FFF4E0';
  static readonly DEVICE_CAMERA_BG: string = '#E6F5EC';

  /** ===== 传感器类型图标色 ===== */
  static readonly SENSOR_TEMP: string = '#FA8C16';
  static readonly SENSOR_HUMID: string = '#4DA6FF';
  static readonly SENSOR_AIR: string = '#379B5E';
  static readonly SENSOR_LIGHT: string = '#F5A623';
  static readonly SENSOR_PIR: string = '#9B6DFF';
  static readonly SENSOR_DOOR: string = '#E8402E';
  static readonly SENSOR_SMOKE: string = '#E8402E';
  static readonly SENSOR_POWER: string = '#007DFF';

  // —— 兼容旧引用（统一指向新值，避免大范围改名出错）——
  static readonly BLUE: string = '#007DFF';
  static readonly PURPLE: string = '#9B6DFF';
  static readonly GREEN: string = '#379B5E';
  static readonly ORANGE: string = '#FA8C16';
  static readonly RED: string = '#E8402E';
  static readonly CYAN: string = '#4DA6FF';
  static readonly PINK: string = '#E8402E';
  static readonly YELLOW: string = '#F5A623';
  static readonly INDIGO: string = '#5E6CE6';
  static readonly TEAL: string = '#379B5E';
}
