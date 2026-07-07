/**
 * 大模型对话 API · 对接设备端网关（DeepSeek）
 * 策略: HTTP POST /api/chat/send 获取真实回复，失败降级到本地关键词回复
 * 流式: 网关返回完整文本，前端模拟逐字打字效果
 */
import { ChatMessage, ChatRole } from './types';
import { MockData } from '../mock/mockData';
import { Http } from './http';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
const TAG = 'SmartHomeChat';

let msgIdCounter = 100;

interface ChatSendRequest {
  messages: ChatMessage[];
}

interface ChatReplyResponse {
  reply: string;
  role: string;
}

export class ChatApi {
  /**
   * 发送消息（流式打字效果）
   * 先从网关获取完整回复，再逐字吐出模拟流式
   * 关键修复: 无论 HTTP 成功或失败，onDone 必定被调用
   */
  static async sendStream(
    messages: ChatMessage[],
    onToken: (token: string) => void,
    onDone: (full: ChatMessage) => void
  ): Promise<void> {
    let reply: string = '';

    try {
      // 1. 调网关获取真实回复（带超时保护）
      const body: ChatSendRequest = { messages };
      hilog.info(DOMAIN, TAG, `sendStream start, msgs=${messages.length}`);

      const respText = await ChatApi.raceTimeout(Http.post('/api/chat/send', body), 25000);

      if (respText) {
        try {
          const resp = JSON.parse(respText) as ChatReplyResponse;
          if (resp.reply) {
            reply = resp.reply;
            hilog.info(DOMAIN, TAG, `got reply: ${reply.substring(0, 40)}`);
          }
        } catch (e) {
          hilog.warn(DOMAIN, TAG, `JSON parse failed, raw: ${respText.substring(0, 80)}`);
        }
      } else {
        hilog.warn(DOMAIN, TAG, `Http.post returned null, falling back to mock`);
      }

      // 2. 降级到本地回复
      if (!reply) {
        reply = ChatApi.mockReply(messages[messages.length - 1]?.content || '');
        hilog.info(DOMAIN, TAG, `using mock reply: ${reply.substring(0, 40)}`);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `sendStream error: ${(e as Error).message}`);
      reply = ChatApi.mockReply(messages[messages.length - 1]?.content || '');
    }

    // 3. 逐字吐出（模拟流式打字）— 这段必定执行
    hilog.info(DOMAIN, TAG, `starting typewriter, reply len=${reply.length}`);
    let i = 0;
    return new Promise<void>(resolve => {
      const timer = setInterval(() => {
        if (i >= reply.length) {
          clearInterval(timer);
          onDone({
            id: 'msg_' + (msgIdCounter++),
            role: ChatRole.ASSISTANT,
            content: reply,
            timestamp: Date.now()
          });
          hilog.info(DOMAIN, TAG, `typewriter done`);
          resolve();
          return;
        }
        const step = reply[i] === ' ' ? 2 : 1;
        onToken(reply.slice(0, i + step));
        i += step;
      }, 35);
    });
  }

  /**
   * 超时竞速: 如果 promise 在 ms 内未完成，返回 null
   * 防止 Http.post 永久挂起导致聊天卡死
   */
  private static raceTimeout(promise: Promise<string | null>, ms: number): Promise<string | null> {
    return new Promise<string | null>(resolve => {
      let done = false;
      const timer = setTimeout(() => {
        if (!done) {
          done = true;
          hilog.warn(DOMAIN, TAG, `raceTimeout fired after ${ms}ms`);
          resolve(null);
        }
      }, ms);
      promise.then(result => {
        if (!done) {
          done = true;
          clearTimeout(timer);
          resolve(result);
        }
      }).catch(() => {
        if (!done) {
          done = true;
          clearTimeout(timer);
          resolve(null);
        }
      });
    });
  }

  /** 语音输入（占位） */
  static async voiceToText(audioPath: string): Promise<string> {
    return new Promise(resolve => setTimeout(() => resolve('把客厅空调调到 24 度'), 600));
  }

  /** 文字转语音（占位） */
  static async textToVoice(text: string): Promise<string> {
    return new Promise(resolve => setTimeout(() => resolve(''), 400));
  }

  /** 欢迎语 */
  static getWelcome(): string {
    return MockData.chatWelcome;
  }

  /** 本地降级回复（网关不可用时） */
  private static mockReply(input: string): string {
    const q = input.toLowerCase();
    if (q.includes('空调') || q.includes('温度')) return '好的，我已为你将客厅空调设定为 24°C 制冷模式。';
    if (q.includes('风扇')) return '客厅吊扇已开启 2 档风，如需调整请告诉我。';
    if (q.includes('门') || q.includes('开锁')) return '已向入户门禁发送开锁指令。';
    if (q.includes('你好') || q.includes('hi') || q.includes('hello')) return '你好！有什么可以帮你的吗？';
    if (q.includes('灯')) return '客厅主灯已打开，亮度 80%。';
    return '收到。我可以帮你控制风扇、空调、门禁、灯光，查询传感器数据。请告诉我你想做什么。';
  }
}
