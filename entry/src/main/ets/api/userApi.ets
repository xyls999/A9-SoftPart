/**
 * 用户与服务端管理 API
 *
 * 接口契约:
 *   GET  /api/user/profile         → UserProfile
 *   PUT  /api/user/profile         { ... } → { success }
 *   GET  /api/server/status        → ServerStatus
 *   POST /api/server/restart       → { success }
 *   POST /api/server/connect       { host, port, protocol } → { success }
 */
import { UserProfile, UserProfileUpdate, ServerStatus } from './types';
import { MockData } from '../mock/mockData';

const DELAY = 240;
function delay<T>(data: T): Promise<T> {
  return new Promise(resolve => setTimeout(() => resolve(data), DELAY));
}

export class UserApi {
  /** 获取用户资料 */
  static async getProfile(): Promise<UserProfile> {
    // TODO[后端对接]: GET /api/user/profile
    return delay(MockData.user);
  }

  /** 更新用户资料 */
  static async updateProfile(profile: UserProfileUpdate): Promise<boolean> {
    // TODO[后端对接]: PUT /api/user/profile
    if (profile.nickname !== undefined) MockData.user.nickname = profile.nickname;
    if (profile.homeName !== undefined) MockData.user.homeName = profile.homeName;
    if (profile.memberCount !== undefined) MockData.user.memberCount = profile.memberCount;
    if (profile.deviceCount !== undefined) MockData.user.deviceCount = profile.deviceCount;
    return delay(true);
  }

  /** 获取服务端状态 */
  static async getServerStatus(): Promise<ServerStatus> {
    // TODO[后端对接]: GET /api/server/status
    return delay(MockData.server);
  }

  /** 重启服务端 */
  static async restartServer(): Promise<boolean> {
    // TODO[后端对接]: POST /api/server/restart
    return delay(true);
  }

  /** 连接服务端（WiFi / 星闪） */
  static async connectServer(host: string, port: number, protocol: 'wifi' | 'starflash'): Promise<boolean> {
    // TODO[后端对接]: POST /api/server/connect  body: { host, port, protocol }
    MockData.server.host = host;
    MockData.server.port = port;
    MockData.server.protocol = protocol;
    MockData.server.isOnline = true;
    return delay(true);
  }
}
