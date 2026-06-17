/**
 * 设备控制 API · 风扇 / 门禁 / 空调 / 灯光
 *
 * ====================================================================
 * 对接说明（agent3 审核）:
 * 所有函数当前返回 MockData，用于本地预览。
 * 后端对接时，仅替换函数体（return 部分），保持函数签名不变。
 * 页面层只通过本文件访问设备数据，不直接读 mockData。
 * ====================================================================
 *
 * 接口契约:
 *   GET    /api/devices                    → Device[]
 *   GET    /api/devices/{id}               → Device
 *   POST   /api/devices/{id}/control       { action, params } → { success }
 *   POST   /api/devices/{id}/toggle        { isOn } → { success }
 *   DELETE /api/devices/{id}               → { success }
 *
 * 通信协议: WiFi / 星闪（由 Device.protocol 指定，控制指令下发到对应通道）
 */
import { Device, ControlParams } from './types';
import { MockData } from '../mock/mockData';

const DELAY = 280; // 模拟网络延迟 ms

function delay<T>(data: T): Promise<T> {
  return new Promise(resolve => setTimeout(() => resolve(data), DELAY));
}

export class DeviceApi {
  /** 获取全部设备列表 */
  static async getDevices(): Promise<Device[]> {
    // TODO[后端对接]: GET /api/devices
    return delay(MockData.devices);
  }

  /** 获取单个设备详情 */
  static async getDevice(id: string): Promise<Device | undefined> {
    // TODO[后端对接]: GET /api/devices/{id}
    return delay(MockData.devices.find(d => d.id === id));
  }

  /**
   * 控制设备（档位/温度/亮度等）
   * @param action  动作类型: 'set_speed' | 'set_temp' | 'set_brightness' | 'set_mode'
   * @param params  参数键值对，如 { level: 3 } 或 { temperature: 22 }
   */
  static async control(id: string, action: string, params: ControlParams): Promise<boolean> {
    // TODO[后端对接]: POST /api/devices/{id}/control  body: { action, params }
    // 本地预览: 同步更新内存中的 mock 状态
    const dev = MockData.devices.find(d => d.id === id);
    if (dev) {
      if (action === 'set_speed' || action === 'set_temp' || action === 'set_brightness') {
        dev.primaryValue = params.value as number;
      }
      if (action === 'set_mode' && dev.mode !== undefined) {
        dev.mode = params.mode as string;
      }
    }
    return delay(true);
  }

  /** 开关设备 */
  static async toggle(id: string, isOn: boolean): Promise<boolean> {
    // TODO[后端对接]: POST /api/devices/{id}/toggle  body: { isOn }
    const dev = MockData.devices.find(d => d.id === id);
    if (dev) dev.isOn = isOn;
    return delay(true);
  }

  /** 触发门禁开锁（门禁专用，需二次验证） */
  static async unlockDoor(id: string, pin: string): Promise<boolean> {
    // TODO[后端对接]: POST /api/devices/{id}/unlock  body: { pin }
    // 安全校验: pin 不为空
    if (!pin) return delay(false);
    const dev = MockData.devices.find(d => d.id === id);
    if (dev) { dev.isOn = true; dev.primaryValue = 1; setTimeout(() => { dev.isOn = false; dev.primaryValue = 0; }, 8000); }
    return delay(true);
  }
}
